package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import haxe.ds.StringMap;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirPatternChildren;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
 * NilGuardFieldAccessCaseNarrowTransforms
 *
 * WHAT
 * - Rewrites an `if` whose condition is `Kernel.is_nil(var)` or'ed with another
 *   condition, when the else-branch reads `var.field`, into a `case var` with a
 *   `nil` clause and a map clause that binds the fields it reads.
 * - The rewrite keeps the evaluation order of `or`: the left operand runs first,
 *   and the right operand runs only when the left one is false.
 *   - `other or is_nil(var)`:
 *       if other do then else (case var do nil -> then; %{field: var_field} -> else' end) end
 *   - `is_nil(var) or other`:
 *       case var do nil -> then; %{field: var_field} -> if other' do then else else' end end
 *     Here `other'` reads its `var.field` values from the clause binders too.
 *
 * WHY
 * - Elixir 1.18+ emits WAE warnings when a variable is inferred as `nil | map` from
 *   initializer bindings (e.g. `var = nil`) and later accessed via `var.field`,
 *   even when guarded by boolean conditions (flow narrowing is limited).
 * - Haxe patterns like:
 *     if (errors.length > 0 || validatedEmail == null) return Error(errors);
 *     return Ok({ email: validatedEmail.email });
 *   should compile cleanly without requiring the user to change source structure.
 * - The nil test must stay first when the source puts it first. Hoisting `other`
 *   out of the case for `x == null || x.a == x.b` read `x.a` on a nil `x` and raised
 *   KeyError (haxe.elixir.codex-8dnf).
 *
 * HOW
 * - Match EIf whose condition is `EBinary(Or, ...)` with `Kernel.is_nil(var)` as
 *   either operand, and whose else-branch reads at least one `var.field`.
 * - Bind each read field to `var_field` in a map pattern and replace the reads.
 * - Keep the plain `if` when a branch binds `var` again or already names one of
 *   the new binders (see `canBindFields`).
 * - Only `EField(EVar(var), field)` reads are bound. An optional Haxe field reads as
 *   `Map.get(var, :field)`, so the map pattern names only keys the type requires.
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
 *       %{email: validated_email_email} -> {:ok, %{email: validated_email_email}}
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
 *     %{a: head_a, b: head_b} -> if head_a == head_b, do: nil, else: head_a
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
		var condUnwrapped = unwrapParen(condition);
		var nilInfo = extractNilGuardOr(condUnwrapped);
		if (nilInfo == null)
			return null;

		var varName = nilInfo.varName;
		var otherCond = nilInfo.otherCond;

		var elseFields = collectDirectFieldAccesses(elseBranch, varName);
		if (elseFields.length == 0)
			return null;

		// When the nil test is the left operand, the other condition moves into the
		// non-nil clause, so its field reads use the clause binders too.
		var fieldNames = nilInfo.nilFirst ? mergeSorted(collectDirectFieldAccesses(otherCond, varName), elseFields) : elseFields;

		var fieldToBinder = new StringMap<String>();
		for (f in fieldNames)
			fieldToBinder.set(f, varName + "_" + f);

		// Branches whose `var.field` reads change, and branches that end up inside the
		// map clause, where the new binders are visible.
		var rewritten = nilInfo.nilFirst ? [otherCond, elseBranch] : [elseBranch];
		var inClause = nilInfo.nilFirst ? [otherCond, thenBranch, elseBranch] : [elseBranch];
		if (!canBindFields(varName, fieldToBinder, rewritten, inClause))
			return null;

		var narrowedElse = replaceFieldAccesses(elseBranch, varName, fieldToBinder);

		var mapPairs:Array<{key:ElixirAST, value:EPattern}> = [];
		for (fieldName in fieldNames) {
			mapPairs.push({key: makeAST(EAtom(fieldName)), value: PVar(fieldToBinder.get(fieldName))});
		}

		if (nilInfo.nilFirst) {
			// `is_nil(v) or other`: test `v` first, then `other`, as `or` does.
			var narrowedOther = replaceFieldAccesses(otherCond, varName, fieldToBinder);
			return makeASTWithMeta(ECase(makeAST(EVar(varName)), [
				{
					pattern: PLiteral(makeAST(ENil)),
					guard: null,
					body: thenBranch
				},
				{
					pattern: PMap(mapPairs),
					guard: null,
					body: makeAST(EIf(narrowedOther, thenBranch, narrowedElse))
				}
			]), original.metadata, original.pos);
		}

		// `other or is_nil(v)`: `other` runs first in the source too.
		var caseExpr = makeASTWithMeta(ECase(makeAST(EVar(varName)), [
			{
				pattern: PLiteral(makeAST(ENil)),
				guard: null,
				body: thenBranch
			},
			{
				pattern: PMap(mapPairs),
				guard: null,
				body: narrowedElse
			}
		]), original.metadata, original.pos);

		return makeASTWithMeta(EIf(otherCond, thenBranch, caseExpr), original.metadata, original.pos);
	}

	/**
	 * Returns true when every `var.field` read can safely become a binder from the
	 * new map pattern.
	 *
	 * Two shapes make that replacement read the wrong value, so the pass keeps the
	 * plain `if` for them:
	 * - A branch in `rewritten` binds `var` again (`v = other()`, `fn v -> ...`, a
	 *   case pattern). A later `v.a` then means the new value, not the field of the
	 *   map that the nil test checked.
	 * - A branch in `inClause` already names a binder, for example an outer local
	 *   `v_a`. The pattern binder would hide that local inside the clause.
	 */
	static function canBindFields(varName:String, fieldToBinder:StringMap<String>, rewritten:Array<ElixirAST>, inClause:Array<ElixirAST>):Bool {
		for (branch in rewritten)
			if (bindsName(branch, varName))
				return false;
		for (branch in inClause)
			for (binder in fieldToBinder)
				if (bindsName(branch, binder) || VarUseAnalyzer.stmtUsesVarExact(branch, binder))
					return false;
		return true;
	}

	/**
	 * Returns true when `expr` binds `name` anywhere: a match target, or a pattern
	 * in a case, receive, with, try, comprehension, function, or anonymous function.
	 * A pinned `^name` also counts, so the check errs toward keeping the plain `if`.
	 * Raw Elixir is not parsed; it can read `name` but is not treated as a binder.
	 */
	static function bindsName(expr:ElixirAST, name:String):Bool {
		var found = false;
		function checkPattern(pattern:EPattern):Void {
			if (found || pattern == null)
				return;
			ElixirPatternChildren.walk(pattern, _ -> {}, p -> switch (p) {
				case PVar(bound) | PAlias(bound, _) if (bound == name):
					found = true;
				default:
			});
		}
		function checkMatchTarget(target:ElixirAST):Void {
			if (found || target == null || target.def == null)
				return;
			switch (target.def) {
				case EVar(bound) if (bound == name):
					found = true;
				default:
					ElixirASTTransformer.iterateAST(target, checkMatchTarget);
			}
		}
		function visit(node:ElixirAST):Void {
			if (found || node == null || node.def == null)
				return;
			switch (node.def) {
				case EMatch(pattern, _):
					checkPattern(pattern);
				case EBinary(Match, target, _):
					checkMatchTarget(target);
				case ECase(_, clauses) | EReceive(clauses, _):
					for (clause in clauses)
						checkPattern(clause.pattern);
				case EWith(clauses, _, _):
					for (clause in clauses)
						checkPattern(clause.pattern);
				case ETry(_, rescueClauses, catchClauses, _, _):
					if (rescueClauses != null)
						for (clause in rescueClauses)
							checkPattern(clause.pattern);
					if (catchClauses != null)
						for (clause in catchClauses)
							checkPattern(clause.pattern);
				case EFor(generators, _, _, _, _):
					for (generator in generators)
						checkPattern(generator.pattern);
				case EFn(clauses):
					for (clause in clauses)
						for (arg in clause.args)
							checkPattern(arg);
				case EDef(_, args, _, _) | EDefp(_, args, _, _) | EDefmacro(_, args, _, _) | EDefmacrop(_, args, _, _):
					for (arg in args)
						checkPattern(arg);
				default:
			}
			ElixirASTTransformer.iterateAST(node, visit);
		}
		visit(expr);
		return found;
	}

	static function mergeSorted(first:Array<String>, second:Array<String>):Array<String> {
		var out = first.copy();
		for (name in second)
			if (out.indexOf(name) == -1)
				out.push(name);
		out.sort(Reflect.compare);
		return out;
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

	static function collectDirectFieldAccesses(expr:ElixirAST, varName:String):Array<String> {
		var seen = new StringMap<Bool>();
		if (expr == null || expr.def == null)
			return [];

		ElixirASTTransformer.transformNode(expr, function(n:ElixirAST):ElixirAST {
			if (n == null || n.def == null)
				return n;
			switch (n.def) {
				case EField(target, fieldName):
					var t = unwrapParen(target);
					switch (t.def) {
						case EVar(v) if (v == varName):
							if (!seen.exists(fieldName)) seen.set(fieldName, true);
						default:
					}
				default:
			}
			return n;
		});

		var out:Array<String> = [];
		for (k in seen.keys())
			out.push(k);
		out.sort(Reflect.compare);
		return out;
	}

	static function replaceFieldAccesses(expr:ElixirAST, varName:String, fieldToBinder:StringMap<String>):ElixirAST {
		return ElixirASTTransformer.transformNode(expr, function(n:ElixirAST):ElixirAST {
			if (n == null || n.def == null)
				return n;
			return switch (n.def) {
				case EField(target, fieldName):
					var t = unwrapParen(target);
					switch (t.def) {
						case EVar(v) if (v == varName && fieldToBinder.exists(fieldName)):
							makeASTWithMeta(EVar(fieldToBinder.get(fieldName)), n.metadata, n.pos);
						default:
							n;
					}
				default:
					n;
			};
		});
	}
}
#end
