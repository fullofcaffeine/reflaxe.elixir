package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseResultAssignmentMergeTransforms
 *
 * WHAT
 * - Merges adjacent assignment + case patterns of the form:
 *   x = INIT;
 *   case x do ... end
 *   into a single assignment of the case result:
 *   x = case INIT do ... end
 *
 * WHY
 * - A tail case may be folded into its adjacent input binding when that input
 *   has no remaining readers. The resulting block must still return the case value.
 * - This is not a repair for missing result assignments. An input and a result
 *   are different values; later readers must retain the input they originally saw.
 *
 * HOW
 * - Inspect the final two statements in a function body:
 *   - First statement: EMatch(PVar(name) | EBinary(Match, EVar(name), _), init)
 *   - Second statement: ECase(EVar(name), clauses)
 *   - Require no input read in case guards, bodies, or pinned patterns.
 *   - Preserve the complete initializer, including assignments and effects.
 *   - Only then merge; never change an input that later statements may read.
 *
 * EXAMPLES
 * Haxe:
 *   var c = switch(todo.priority) {
 *     case "high": "border-red-500";
 *     case "medium": "border-yellow-500";
 *     case "low": "border-green-500";
 *     case _: "border-gray-300";
 *   }
 *
 * Elixir (before):
 *   c = todo.priority
 *   case c do
 *     "high" -> "border-red-500"
 *     "medium" -> "border-yellow-500"
 *     ...
 *   end
 *
 * Elixir (after):
 *   c = case todo.priority do
 *     "high" -> "border-red-500"
 *     "medium" -> "border-yellow-500"
 *     ...
 *   end
 */
class CaseResultAssignmentMergeTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EDef(name, args, guards, body):
					makeASTWithMeta(EDef(name, args, guards, rewriteBlock(body)), n.metadata, n.pos);
				case EDefp(name, args, guards, body):
					makeASTWithMeta(EDefp(name, args, guards, rewriteBlock(body)), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function rewriteBlock(body:ElixirAST):ElixirAST {
		return switch (body.def) {
			case EBlock(stmts) if (stmts != null && stmts.length >= 2):
				var out:Array<ElixirAST> = [];
				var i = 0;
				while (i < stmts.length) {
					if (i + 2 == stmts.length) {
						var s1 = stmts[i];
						var s2 = stmts[i + 1];
						var name:Null<String> = null;
						var init:Null<ElixirAST> = null;
						// Match assignment: name = init
						switch (s1.def) {
							case EMatch(pat, rhs):
								switch (pat) {
									case PVar(n): name = n;
									default:
								}
								init = rhs;
							case EBinary(Match, left, rhs2):
								switch (left.def) {
									case EVar(n2): name = n2;
									default:
								}
								init = rhs2;
							default:
						}
						if (name != null && init != null) {
							// Second statement must be case on that var
							switch (s2.def) {
								case ECase(target, clauses):
									// Moving the binding after the case is only safe when no
									// branch or guard still reads its original value. Keep
									// the entire initializer, including nested assignments.
									var branchScope = makeASTWithMeta(ECase(makeASTWithMeta(ENil, {}, s2.pos), clauses), {}, s2.pos);
									if (reflaxe.elixir.ast.analyzers.VarUseAnalyzer.usesFreeVarExact(branchScope, name)
										|| reflaxe.elixir.ast.analyzers.VarUseAnalyzer.stmtUsesVarExact(branchScope, name)) {
										out.push(stmts[i++]);
										continue;
									}
									switch (target.def) {
										case EVar(v) if (v == name):
											var merged = makeASTWithMeta(EMatch(PVar(name), makeASTWithMeta(ECase(init, clauses), s2.metadata, s2.pos)),
												s1.metadata, s1.pos);
											out.push(merged);
											i += 2; // Skip the case we merged
											continue;
										default:
									}
								default:
							}
						}
					}
					// default: push original stmt
					out.push(stmts[i]);
					i++;
				}
				makeASTWithMeta(EBlock(out), body.metadata, body.pos);
			default:
				body;
		}
	}
}
#end
