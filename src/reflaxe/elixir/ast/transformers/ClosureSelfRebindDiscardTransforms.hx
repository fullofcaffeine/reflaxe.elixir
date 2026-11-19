package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
 * ClosureSelfRebindDiscardTransforms
 *
 * WHAT
 * - Inside anonymous functions, replace rebinds of the closure's own single
 *   binder variable (e.g., `item = expr`) with a discard assignment `_ = expr`.
 *
 * WHY
 * - Prevents warnings where the rebind of the binder is unused and flagged under
 *   MIX_ENV=test --warnings-as-errors. The expression side effects remain.
 *
 * HOW
 * - For each EFn clause with exactly one argument PVar(name), look at every block in
 *   the clause body. A statement `name = rhs` (or `EMatch(PVar(name), rhs)`) becomes
 *   `_ = rhs` only when no later statement of the same block reads `name`
 *   (`VarUseAnalyzer.usedLater`, which also scans raw code and interpolations).
 *   A clause body that is only the rebind is also rewritten: nothing follows it.
 * - A rebind that a later statement reads is kept. A Haxe loop that writes its element,
 *   `for (k in xs) { k = k * 2; note("k" + k); }`, lowers to
 *   `Enum.each(xs, fn k -> k = k * 2; note("k" <> ...k) end)`; turning the rebind into
 *   `_ = k * 2` made `note` read the old `k` (haxe.elixir.codex-g4xy).
 * - A block value is not changed: `_ = rhs` has the same value as `name = rhs`.
 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ClosureSelfRebindDiscardTransforms {
	/** Returns `_ = rhs` when `stmt` rebinds `binder`; otherwise null. */
	static function discardRebind(stmt:ElixirAST, binder:String):Null<ElixirAST> {
		return switch (stmt.def) {
			case EBinary(Match, left, rhs):
				switch (left.def) {
					case EVar(v) if (v == binder):
						makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("_"), left.metadata, left.pos), rhs), stmt.metadata, stmt.pos);
					default: null;
				}
			case EMatch(PVar(v), rhs) if (v == binder):
				makeASTWithMeta(EMatch(PVar("_"), rhs), stmt.metadata, stmt.pos);
			default:
				null;
		};
	}

	/**
	 * Rewrites each rebind of `binder` in `body` to `_ = rhs` when nothing after it reads `binder`.
	 *
	 * Only direct block statements are rewritten, and only when no later statement of that
	 * block may read the binder. Elixir does not leak a rebind out of a nested block, so the
	 * later statements of the same block are the only possible readers.
	 */
	static function discardUnreadRebinds(body:ElixirAST, binder:String):ElixirAST {
		var direct = discardRebind(body, binder);
		if (direct != null)
			return direct;
		return ElixirASTTransformer.transformNode(body, function(x:ElixirAST):ElixirAST {
			function rewriteStatements(stmts:Array<ElixirAST>):Null<Array<ElixirAST>> {
				var changed = false;
				var out = [];
				for (index in 0...stmts.length) {
					var discarded = discardRebind(stmts[index], binder);
					if (discarded != null && !VarUseAnalyzer.usedLater(stmts, index + 1, binder)) {
						out.push(discarded);
						changed = true;
					} else {
						out.push(stmts[index]);
					}
				}
				return changed ? out : null;
			}
			return switch (x.def) {
				case EBlock(stmts):
					var rewritten = rewriteStatements(stmts);
					rewritten != null ? makeASTWithMeta(EBlock(rewritten), x.metadata, x.pos) : x;
				case EDo(stmts):
					var rewrittenDo = rewriteStatements(stmts);
					rewrittenDo != null ? makeASTWithMeta(EDo(rewrittenDo), x.metadata, x.pos) : x;
				default:
					x;
			}
		});
	}

	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EFn(clauses):
					var out = [];
					for (cl in clauses) {
						var binder:Null<String> = switch (cl.args.length == 1 ? cl.args[0] : null) {
							case PVar(v): v;
							default: null;
						};
						if (binder == null) {
							out.push(cl);
							continue;
						}
						var newBody = discardUnreadRebinds(cl.body, binder);
						out.push({args: cl.args, guard: cl.guard, body: newBody});
					}
					makeASTWithMeta(EFn(out), n.metadata, n.pos);
				default:
					n;
			}
		});
	}
}
#end
