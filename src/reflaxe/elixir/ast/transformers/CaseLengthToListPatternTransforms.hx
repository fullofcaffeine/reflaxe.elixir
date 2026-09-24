package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * Converts zero/singleton length cases for known list literals when every clause has an exact
 * list-pattern equivalent. A partial conversion changes the switch domain:
 * an integer pattern cannot match a list, and a cons is not a singleton.
 *
 * An arbitrary expression can return nil or another non-list value. Preserve
 * its length call and error behavior instead of letting a wildcard accept it.
 * Other shapes retain the original numeric switch. Guards and bodies keep
 * their original bindings; this optimization cannot repair missing aliases.
 */
class CaseLengthToListPatternTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case ECase(target, clauses):
					var listExpr:Null<ElixirAST> = extractListFromLength(target);
					if (listExpr == null || !canConvertAll(clauses)) n else {
						var newClauses = [];
						for (cl in clauses) {
							var newPat = switch (cl.pattern) {
								case PLiteral({def: EInteger(0)}): PList([]);
								case PLiteral({def: EInteger(1)}):
									PList([PWildcard]);
								case PWildcard | PVar("_"):
									PVar("_");
								default:
									// Keep existing pattern
									cl.pattern;
							};
							newClauses.push({pattern: newPat, guard: cl.guard, body: cl.body});
						}
						makeASTWithMeta(ECase(listExpr, newClauses), n.metadata, n.pos);
					}
				default:
					n;
			}
		});
	}

	static function extractListFromLength(e:ElixirAST):Null<ElixirAST> {
		return switch (e.def) {
			case ERemoteCall({def: EVar(mod)}, "length", [list = {def: EList(_)}]) if (mod == "Kernel" || mod == "Enum"): list;
			case ECall(null, "length", [list = {def: EList(_)}]): list;
			default: null;
		}
	}

	static function canConvertAll(clauses:Array<ECaseClause>):Bool {
		for (clause in clauses) {
			switch (clause.pattern) {
				case PLiteral({def: EInteger(0 | 1)}) | PWildcard | PVar("_"):
				default:
					// Includes named fallback bindings: they must still receive a length.
					return false;
			}
		}
		return true;
	}
}
#end
