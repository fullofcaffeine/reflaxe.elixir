package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * BareLiteralDropTransforms
 *
 * WHAT
 * - Removes standalone literal expressions from statement lists (`EBlock`/`EDo`) when they are not
 *   the final expression of the block.
 *
 * WHY
 * - Elixir warns on “code block contains unused literal …” when a literal appears in statement
 *   position. Haxe code frequently produces these as the return value of an expression that is
 *   used for its side-effects (e.g. `DynamicAccess.set("y", 7);` returns `7`).
 *
 * HOW
 * - Walk `EBlock` and `EDo` and filter out non-final statements that are pure literals
 *   (`EInteger`, `EFloat`, `EString`, `EBoolean`, `ENil`, `EAtom`, `ECharlist`).
 *
 * EXAMPLES
 * Haxe:
 *   payload.set("y", 7);
 * Elixir (before):
 *   payload = Map.put(payload, "y", 7)
 *   7
 * Elixir (after):
 *   payload = Map.put(payload, "y", 7)
 */
class BareLiteralDropTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EBlock(stmts):
					makeASTWithMeta(EBlock(filterNonFinalLiterals(stmts)), n.metadata, n.pos);
				case EDo(stmts2):
					makeASTWithMeta(EDo(filterNonFinalLiterals(stmts2)), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function filterNonFinalLiterals(stmts:Array<ElixirAST>):Array<ElixirAST> {
		if (stmts == null || stmts.length <= 1)
			return stmts;
		var out:Array<ElixirAST> = [];
		for (i in 0...stmts.length) {
			var s = stmts[i];
			if (i < stmts.length - 1 && isPureLiteral(s)) {
				continue;
			}
			out.push(s);
		}
		return out;
	}

	static function isPureLiteral(ast:ElixirAST):Bool {
		if (ast == null)
			return false;
		return switch (ast.def) {
			case EParen(inner):
				isPureLiteral(inner);
			case EBlock(exprs): exprs != null && exprs.length == 1 && isPureLiteral(exprs[0]);
			case EAtom(_) | EString(_) | EInteger(_) | EFloat(_) | EBoolean(_) | ENil | ECharlist(_):
				true;
			default:
				false;
		}
	}
}
#end
