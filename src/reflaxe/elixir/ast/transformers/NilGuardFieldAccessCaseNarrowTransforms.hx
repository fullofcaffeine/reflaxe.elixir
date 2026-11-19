package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirPatternChildren;

/**
 * NilGuardFieldAccessCaseNarrowTransforms
 *
 * WHAT
 * - Rewrites an `if` whose condition is `Kernel.is_nil(var)` or'ed with another
 *   condition, when the else-branch reads `var.field`, so that the else-branch
 *   runs inside a `case var` clause that only a non-nil value reaches.
 * - The rewrite keeps the evaluation order of `or`: the left operand runs first,
 *   and the right operand runs only when the left one is false.
 *   - `other or is_nil(var)`:
 *       if other do then else (case var do nil -> then; _ -> else end) end
 *   - `is_nil(var) or other`:
 *       case var do nil -> then; _ -> if other do then else else end end
 * - The branches keep their plain `var.field` reads. They run only after the nil
 *   test, so they read the current value of `var`, and a missing key fails at the
 *   read, as it did before the rewrite.
 *
 * WHY
 * - Elixir 1.18+ emits WAE warnings when a variable is inferred as `nil | map` from
 *   initializer bindings (e.g. `var = nil`) and later accessed via `var.field`,
 *   even when guarded by boolean conditions (flow narrowing is limited).
 * - Haxe patterns like:
 *     if (errors.length > 0 || validatedEmail == null) return Error(errors);
 *     return Ok({ email: validatedEmail.email });
 *   should compile cleanly without requiring the user to change source structure.
 * - Observed on Elixir 1.18.3 (the CI version): a `nil | map` value gives no warning
 *   for `var.field` in the plain `if`, in this rewrite, or with field binders. A value
 *   that is exactly `nil` gives a warning in each of them ("expected a map" for a
 *   read, "clause will never match" for a map pattern).
 * - The nil test must stay first when the source puts it first. Hoisting `other`
 *   out of the case for `x == null || x.a == x.b` read `x.a` on a nil `x` and raised
 *   KeyError (haxe.elixir.codex-8dnf).
 * - An earlier version bound each field up front (`%{a: var_a} ->`). That read the
 *   wrong value when a branch bound `var` again or already had a local named
 *   `var_a`, and it raised before `other` ran when a value from `Dynamic` lacked a
 *   key. The `_` clause has none of these problems.
 *
 * HOW
 * - Match EIf whose condition is `EBinary(Or, ...)` with `Kernel.is_nil(var)` as
 *   either operand, and whose else-branch reads at least one `var.field`.
 * - `is_nil(var) or other` where `other` binds a variable (`n++`, `n += 1`, a match,
 *   a receiver update such as `v.a++`): a binding in an `if` condition stays visible
 *   after the `if`, but one inside a case clause does not. So the pass keeps
 *   `other` in the `if` condition, as earlier versions did, and uses the
 *   `other or is_nil(var)` shape. This still tests `other` before the nil test; see
 *   `conditionBinds`.
 *
 * EXAMPLES
 * Haxe:
 *   if (errors.length > 0 || validatedEmail == null) return Error(errors);
 *   return Ok({ email: validatedEmail.email });
 *
 * Elixir (before):
 *   if length(errors) > 0 or Kernel.is_nil(validated_email),
 *     do: {:error, errors},
 *     else: {:ok, %{email: validated_email.email}}
 *
 * Elixir (after):
 *   if length(errors) > 0 do
 *     {:error, errors}
 *   else
 *     case validated_email do
 *       nil -> {:error, errors}
 *       _ -> {:ok, %{email: validated_email.email}}
 *     end
 *   end
 *
 * Haxe:
 *   if (head == null || head.a == head.b) return null;
 *   return head.a;
 *
 * Elixir (after):
 *   case head do
 *     nil -> nil
 *     _ -> if head.a == head.b, do: nil, else: head.a
 *   end
 *
 * Covered by test/differential/r20_null_guard_short_circuit.
 */
class NilGuardFieldAccessCaseNarrowTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EIf(condition, thenBranch, elseBranch) if (elseBranch != null):
					var rewritten = rewriteIf(condition, thenBranch, elseBranch, n);
					rewritten != null ? rewritten : n;
				default:
					n;
			}
		});
	}

	static function rewriteIf(condition:ElixirAST, thenBranch:ElixirAST, elseBranch:ElixirAST, original:ElixirAST):Null<ElixirAST> {
		var nilInfo = extractNilGuardOr(unwrapParen(condition));
		if (nilInfo == null)
			return null;

		var varName = nilInfo.varName;
		var otherCond = nilInfo.otherCond;
		if (!readsField(elseBranch, varName))
			return null;

		function nonNilCase(nonNilBody:ElixirAST):ElixirAST {
			return makeASTWithMeta(ECase(makeAST(EVar(varName)), [
				{
					pattern: PLiteral(makeAST(ENil)),
					guard: null,
					body: thenBranch
				},
				{
					pattern: PWildcard,
					guard: null,
					body: nonNilBody
				}
			]), original.metadata, original.pos);
		}

		if (nilInfo.nilFirst && !conditionBinds(otherCond))
			return nonNilCase(makeAST(EIf(otherCond, thenBranch, elseBranch)));

		return makeASTWithMeta(EIf(otherCond, thenBranch, nonNilCase(elseBranch)), original.metadata, original.pos);
	}

	/**
	 * Returns true when `cond` binds a variable outside a nested anonymous function:
	 * a match (`{n, old} = {n + 1, n}`, which is how `n++` lowers), a receiver
	 * update, or a pattern in a case, with, receive, try, or comprehension.
	 *
	 * Such a binding must stay in the `if` condition: there it stays visible after
	 * the `if`, but inside a case clause it is lost. For `x == null || x.a == n++`
	 * the pass therefore still evaluates `n++` before the nil test, as earlier
	 * versions did. That keeps `n` correct when `x` is not null, but raises
	 * KeyError when `x` is null. A binding nested in a condition is lost even
	 * without this pass (`if (flag || x == n++)`), so the general fix belongs to
	 * condition lowering, not here.
	 */
	static function conditionBinds(cond:ElixirAST):Bool {
		var found = false;
		function checkPattern(pattern:EPattern):Void {
			if (found || pattern == null)
				return;
			ElixirPatternChildren.walk(pattern, _ -> {}, p -> switch (p) {
				case PVar(_) | PAlias(_, _):
					found = true;
				default:
			});
		}
		function visit(node:ElixirAST):Void {
			if (found || node == null || node.def == null)
				return;
			switch (node.def) {
				case EFn(_):
					return;
				case EMatch(_, _) | EBinary(Match, _, _) | EReceiverEffect(_):
					found = true;
					return;
				case ECase(_, clauses) | EReceive(clauses, _):
					for (clause in clauses)
						checkPattern(clause.pattern);
				case EWith(clauses, _, _):
					for (clause in clauses)
						checkPattern(clause.pattern);
				case ETry(_, rescueClauses, catchClauses, _, _):
					if (rescueClauses != null)
						for (clause in rescueClauses) {
							if (clause.varName != null)
								found = true;
							checkPattern(clause.pattern);
						}
					if (catchClauses != null)
						for (clause in catchClauses)
							checkPattern(clause.pattern);
				case EFor(generators, _, _, _, _):
					for (generator in generators)
						checkPattern(generator.pattern);
				default:
			}
			ElixirASTTransformer.iterateAST(node, visit);
		}
		visit(cond);
		return found;
	}

	static function unwrapParen(e:ElixirAST):ElixirAST {
		return switch (e.def) {
			case EParen(inner): unwrapParen(inner);
			default: e;
		};
	}

	/**
	 * Finds the `Kernel.is_nil(var)` operand of an `or` condition. `nilFirst` is
	 * true when it is the left operand, which `or` evaluates first.
	 */
	static function extractNilGuardOr(cond:ElixirAST):Null<{varName:String, otherCond:ElixirAST, nilFirst:Bool}> {
		if (cond == null || cond.def == null)
			return null;
		return switch (cond.def) {
			case EBinary(Or, left, right):
				var leftVar = extractIsNilVar(left);
				if (leftVar != null) {
					{varName: leftVar, otherCond: right, nilFirst: true};
				} else {
					var rightVar = extractIsNilVar(right);
					rightVar != null ? {varName: rightVar, otherCond: left, nilFirst: false} : null;
				}
			default:
				null;
		};
	}

	static function extractIsNilVar(expr:ElixirAST):Null<String> {
		var e = unwrapParen(expr);
		if (e == null || e.def == null)
			return null;
		var arg:Null<ElixirAST> = null;

		switch (e.def) {
			case ERemoteCall(mod, "is_nil", args) if (args != null && args.length == 1 && isKernel(mod)):
				arg = args[0];
			case ECall(target, "is_nil", args) if (args != null && args.length == 1 && target != null && isKernel(target)):
				arg = args[0];
			case ECall(null, "is_nil", args) if (args != null && args.length == 1):
				// Imported Kernel.is_nil/1
				arg = args[0];
			default:
		}

		if (arg == null)
			return null;
		return switch (unwrapParen(arg).def) {
			case EVar(v): v;
			default: null;
		};
	}

	static function isKernel(mod:ElixirAST):Bool {
		if (mod == null || mod.def == null)
			return false;
		return switch (unwrapParen(mod).def) {
			case EVar("Kernel"): true;
			case EAtom(a): var s:String = a; s == "Kernel" || s == ":Kernel";
			default:
				false;
		};
	}

	/** Returns true when `expr` reads a field of `varName` directly: `var.field`. */
	static function readsField(expr:ElixirAST, varName:String):Bool {
		var found = false;
		function visit(node:ElixirAST):Void {
			if (found || node == null || node.def == null)
				return;
			switch (node.def) {
				case EField(target, _):
					switch (unwrapParen(target).def) {
						case EVar(v) if (v == varName):
							found = true;
							return;
						default:
					}
				default:
			}
			ElixirASTTransformer.iterateAST(node, visit);
		}
		visit(expr);
		return found;
	}
}
#end
