package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EarlyReturnIfElseTransforms
 *
 * WHAT
 * - Rewrites statement-level early returns compiled as `if cond, do: <expr>` into a proper
 *   `if ... else ... end` expression by moving the remainder of the surrounding block into
 *   the else branch.
 *
 * WHY
 * - Haxe allows early returns (`if (cond) return x; ...`), but Elixir has no `return` keyword.
 * - When `return` is lowered to just its expression, the naive translation becomes:
 *     if cond, do: x
 *     rest()
 *   which changes semantics (rest executes even when Haxe returned).
 *
 * HOW
 * - The builder tags nodes originating from `TReturn` using `metadata.fromReturn`.
 * - This pass scans EBlock/EDo sequences for:
 *     EIf(cond, thenBranch, elseBranch) with a return in either branch
 *   and, when there are subsequent statements:
 *   1) Appends the remainder to each branch that can fall through, creating an
 *      else branch when absent.
 *   2) Leaves returning paths alone. This includes nested returns in complete
 *      if/else statements before later mutable-state reads.
 *   3) Recursively rewrites early-return patterns inside the inserted remainder.
 * - Distributes assignment continuations through returning branch expressions,
 *   binding only normal results and preserving nested function return scope.
 * - Stops a sequence after a proven return. Later expressions are unreachable,
 *   even when they look like valid numeric results to later cleanup passes.
 *
 * EXAMPLES
 * Haxe:
 *   if (todo == null) return socket;
 *   return recomputeVisible(socket);
 * Elixir (before):
 *   if Kernel.is_nil(todo), do: socket
 *   recompute_visible(socket)
 * Elixir (after):
 *   if Kernel.is_nil(todo) do
 *     socket
 *   else
 *     recompute_visible(socket)
 *   end
 */
class EarlyReturnIfElseTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(node:ElixirAST):ElixirAST {
			return switch (node.def) {
				case EBlock(stmts):
					rewriteSequenceAsSameKind(stmts, function(exprs) return makeASTWithMeta(EBlock(exprs), node.metadata, node.pos));
				case EDo(stmts):
					rewriteSequenceAsSameKind(stmts, function(exprs) return makeASTWithMeta(EDo(exprs), node.metadata, node.pos));
				default:
					node;
			}
		});
	}

	static inline function isFromReturn(n:ElixirAST):Bool {
		if (n == null)
			return false;
		if (n.metadata != null && n.metadata.fromReturn == true)
			return true;
		return switch (n.def) {
			case EBlock(stmts) | EDo(stmts): stmts != null && stmts.length > 0 && isFromReturn(stmts[stmts.length - 1]);
			case EParen(inner):
				isFromReturn(inner);
			case EIf(_, thenBranch, elseBranch) if (elseBranch != null): isFromReturn(thenBranch) && isFromReturn(elseBranch);
			case EUnless(_, body, elseBranch) if (elseBranch != null): isFromReturn(body) && isFromReturn(elseBranch);
			default:
				false;
		};
	}

	static function containsFromReturn(n:ElixirAST):Bool {
		if (n == null || n.def == null)
			return false;

		var found = false;

		function scan(node:ElixirAST):Void {
			if (found || node == null || node.def == null)
				return;
			// A nested function owns its returns; creating it does not exit this one.
			switch (node.def) {
				case EFn(_) | EDef(_, _, _, _) | EDefp(_, _, _, _):
					return;
				default:
			}
			if (node.metadata != null && node.metadata.fromReturn == true) {
				found = true;
				return;
			}
			ElixirASTTransformer.iterateAST(node, scan);
		}

		scan(n);
		return found;
	}

	static function appendContinuation(branch:ElixirAST, continuation:ElixirAST):ElixirAST {
		if (branch == null || branch.def == null)
			return branch;
		if (continuation == null || continuation.def == null)
			return branch;

		return switch (branch.def) {
			case EBlock(stmts):
				var combined = (stmts != null ? stmts : []).concat([continuation]);
				rewriteSequenceAsSameKind(combined, function(exprs) return makeASTWithMeta(EBlock(exprs), branch.metadata, branch.pos));

			case EDo(stmts):
				var combined = (stmts != null ? stmts : []).concat([continuation]);
				rewriteSequenceAsSameKind(combined, function(exprs) return makeASTWithMeta(EDo(exprs), branch.metadata, branch.pos));

			case EParen(inner):
				makeASTWithMeta(EParen(appendContinuation(inner, continuation)), branch.metadata, branch.pos);

			default:
				var combined = [branch, continuation];
				var rewritten = rewriteSequenceAsSameKind(combined, function(exprs) return makeASTWithMeta(EBlock(exprs), branch.metadata, branch.pos));
				switch (rewritten.def) {
					case EBlock(exprs) if (exprs != null && exprs.length == 1):
						exprs[0];
					default:
						rewritten;
				}
		};
	}

	static function rewriteSequenceAsSameKind(stmts:Array<ElixirAST>, wrap:Array<ElixirAST>->ElixirAST):ElixirAST {
		if (stmts == null || stmts.length == 0)
			return wrap([]);

		var out:Array<ElixirAST> = [];
		var i = 0;
		while (i < stmts.length) {
			var stmt = stmts[i];
			if (isFromReturn(stmt)) {
				out.push(stmt);
				return wrap(out);
			}

			switch (stmt.def) {
				case EMatch(pattern, value) if (containsFromReturn(value) && canBindNormalResult(value)):
					var rest = stmts.slice(i + 1);
					// Bind only normal branch results. An explicit return bypasses both
					// the assignment and the remainder of the enclosing function.
					out.push(bindNormalResult(value, function(normal) {
						var binding = makeASTWithMeta(EMatch(pattern, normal), stmt.metadata, stmt.pos);
						return buildRestExpr([binding].concat(rest), stmt.metadata, stmt.pos);
					}));
					return wrap(out);

				case EIf(condition, thenBranch, elseBranch) if ((containsFromReturn(thenBranch) || containsFromReturn(elseBranch))
					&& i < stmts.length - 1):
					var rest = stmts.slice(i + 1);
					var elseExpr = buildRestExpr(rest, stmt.metadata, stmt.pos);
					var thenWithContinuation = isFromReturn(thenBranch) ? thenBranch : appendContinuation(thenBranch, elseExpr);
					var elseWithContinuation = elseBranch == null ? elseExpr : isFromReturn(elseBranch) ? elseBranch : appendContinuation(elseBranch, elseExpr);
					out.push(makeASTWithMeta(EIf(condition, thenWithContinuation, elseWithContinuation), stmt.metadata, stmt.pos));
					return wrap(out);

				case EUnless(condition, body, elseBranch) if ((containsFromReturn(body) || containsFromReturn(elseBranch))
					&& i < stmts.length - 1):
					var restUnless = stmts.slice(i + 1);
					var elseExprUnless = buildRestExpr(restUnless, stmt.metadata, stmt.pos);
					var bodyWithContinuation = isFromReturn(body) ? body : appendContinuation(body, elseExprUnless);
					var elseWithContinuation = elseBranch == null ? elseExprUnless : isFromReturn(elseBranch) ? elseBranch : appendContinuation(elseBranch,
						elseExprUnless);
					out.push(makeASTWithMeta(EUnless(condition, bodyWithContinuation, elseWithContinuation), stmt.metadata, stmt.pos));
					return wrap(out);

				default:
					out.push(stmt);
					i++;
			}
		}

		return wrap(out);
	}

	/** Only distribute through visible branch results, never through call arguments
	 * or exception handlers whose evaluation/catch boundary would change.
	 */
	static function canBindNormalResult(value:ElixirAST):Bool {
		if (value == null || !containsFromReturn(value) || isFromReturn(value))
			return true;
		return switch (value.def) {
			case EParen(inner): canBindNormalResult(inner);
			case EBlock(stmts) | EDo(stmts) if (stmts != null && stmts.length > 0):
				canBindNormalResult(stmts[stmts.length - 1]);
			case EIf(condition, thenBranch, elseBranch): !containsFromReturn(condition) && canBindNormalResult(thenBranch) && canBindNormalResult(elseBranch);
			case EUnless(condition, body, elseBranch): !containsFromReturn(condition) && canBindNormalResult(body) && canBindNormalResult(elseBranch);
			case ECase(subject, clauses): !containsFromReturn(subject) && Lambda.foreach(clauses,
					clause -> !containsFromReturn(clause.guard) && canBindNormalResult(clause.body));
			default: false;
		};
	}

	/** Distribute an assignment continuation through value-producing control flow.
	 * Return metadata distinguishes a function exit from an ordinary branch value.
	 * Statement prefixes retain their evaluation order and use the same early-return
	 * reconstruction as surrounding blocks. Nested functions are opaque values.
	 */
	static function bindNormalResult(value:ElixirAST, continuation:ElixirAST->ElixirAST):ElixirAST {
		if (isFromReturn(value))
			return value;
		return switch (value.def) {
			case EParen(inner):
				bindNormalResult(inner, continuation);
			case EBlock(stmts) | EDo(stmts) if (stmts != null && stmts.length > 0):
				var prefix = stmts.slice(0, stmts.length - 1);
				prefix.push(bindNormalResult(stmts[stmts.length - 1], continuation));
				rewriteSequenceAsSameKind(prefix, function(exprs) return makeASTWithMeta(EBlock(exprs), value.metadata, value.pos));
			case EIf(condition, thenBranch, elseBranch):
				makeASTWithMeta(EIf(condition, bindNormalResult(thenBranch, continuation),
					bindNormalResult(elseBranch == null ? makeAST(ENil) : elseBranch, continuation)),
					value.metadata, value.pos);
			case EUnless(condition, body, elseBranch):
				makeASTWithMeta(EUnless(condition, bindNormalResult(body, continuation),
					bindNormalResult(elseBranch == null ? makeAST(ENil) : elseBranch, continuation)),
					value.metadata, value.pos);
			case ECase(subject, clauses):
				makeASTWithMeta(ECase(subject, [
					for (clause in clauses)
						{
							pattern: clause.pattern,
							guard: clause.guard,
							body: bindNormalResult(clause.body, continuation)
						}
				]), value.metadata, value.pos);
			default:
				continuation(value);
		};
	}

	static function buildRestExpr(rest:Array<ElixirAST>, meta:ElixirMetadata, pos:haxe.macro.Expr.Position):ElixirAST {
		// Recursively rewrite early-return patterns within the remainder.
		var rewritten = rewriteSequenceAsSameKind(rest, function(exprs) return makeASTWithMeta(EBlock(exprs), meta, pos));
		return switch (rewritten.def) {
			case EBlock(exprs) if (exprs != null && exprs.length == 1):
				// Prefer a single expression over a 1-element block in branches.
				exprs[0];
			default:
				rewritten;
		};
	}
}
#end
