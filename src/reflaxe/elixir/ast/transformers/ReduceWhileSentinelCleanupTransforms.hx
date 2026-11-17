package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

using StringTools;

/**
 * ReduceWhileSentinelCleanupTransforms
 *
 * WHAT
 * - Removes bare numeric literal statements inside the anonymous function bodies
 *   passed to Enum.reduce_while/3 (common sentinel artifacts from loop lowering).
 *
 * WHY
 * - Prevents warnings like "code block contains unused literal 1" within
 *   reduce_while branches while keeping semantics.
 *
 * HOW
 * - For any ERemoteCall(..., "reduce_while", [_, _, fn]), recursively walk the
 *   fn body and remove EInteger(1|0) and EFloat(0.0) statements in EBlock/EDo.
 * - The last statement of a block is never removed: it is the block's value.
 *   `k = if k > 1, do: 0, else: k` (the Haxe `if (k > 1) k = 0;` in a loop
 *   body) stores a block whose only statement is `0`; removing it made the
 *   branch empty, so `k` became `nil`. A literal before the last statement has
 *   no effect, so removing it is always safe.
 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ReduceWhileSentinelCleanupTransforms {
	/**
	 * Returns `stmts` without the sentinel literals `0`, `1` and `0.0` that have no effect.
	 *
	 * Only statements before the last one are removed. The last statement is the
	 * block's value, and a branch such as `do: 0` must keep it.
	 */
	static function dropSentinelStatements(stmts:Array<ElixirAST>):Array<ElixirAST> {
		var out = [];
		for (index in 0...stmts.length) {
			var stmt = stmts[index];
			var isSentinel = switch (stmt.def) {
				case EInteger(v): v == 0 || v == 1;
				case EFloat(f): f == 0.0;
				default: false;
			};
			if (!isSentinel || index == stmts.length - 1)
				out.push(stmt);
		}
		return out;
	}

	static function cleanupNode(n:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(n, function(x:ElixirAST):ElixirAST {
			return switch (x.def) {
				case EBlock(stmts):
					makeASTWithMeta(EBlock(dropSentinelStatements(stmts)), x.metadata, x.pos);
				case EDo(stmts):
					makeASTWithMeta(EDo(dropSentinelStatements(stmts)), x.metadata, x.pos);
				case ERaw(code):
					// Remove lines that are only numeric sentinels (1/0) in raw code blocks
					var lines = code.split("\n");
					var outLines = [];
					for (ln in lines) {
						var t = ln.trim();
						if (t == "1" || t == "0") {
							// skip sentinel-only line
						} else {
							outLines.push(ln);
						}
					}
					var newCode = outLines.join("\n");
					if (newCode != code) makeASTWithMeta(ERaw(newCode), x.metadata, x.pos) else x;
				default:
					x;
			}
		});
	}

	public static function transformPass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case ERemoteCall(mod, func, args) if (func == "reduce_while" && args != null && args.length >= 3):
					var fnArg = args[2];
					var cleaned = cleanupNode(fnArg);
					if (cleaned != fnArg) {
						var newArgs = args.copy();
						newArgs[2] = cleaned;
						makeASTWithMeta(ERemoteCall(mod, func, newArgs), n.metadata, n.pos);
					} else n;
				default:
					n;
			}
		});
	}
}
#end
