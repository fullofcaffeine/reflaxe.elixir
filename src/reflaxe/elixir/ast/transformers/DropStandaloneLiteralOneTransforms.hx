package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
using StringTools;

/**
 * DropStandaloneLiteralOneTransforms
 *
 * WHAT
 * - Removes standalone integer literals (1 or 0) that appear as statements in
 *   block/do contexts, which cause "code block contains unused literal" warnings.
 *
 * WHY
 * - Some lowerings introduce bare numeric literals to keep shapes; they are
 *   not needed in Elixir and trigger warnings-as-errors.
 *
 * HOW
 * - In EBlock([...]) and EDo([...]) filter out EInteger(1|0) and EFloat(0.0)
 *   when they appear as top-level statements (not within expressions).
 */
class DropStandaloneLiteralOneTransforms {
    public static function dropPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out: Array<ElixirAST> = [];
                    for (s in stmts) switch (s.def) {
                        case EInteger(v) if (v == 1 || v == 0):
                            // drop
                        case EFloat(f) if (f == 0.0):
                            // drop
                        case ERaw(code) if (code.trim() == "1" || code.trim() == "0"):
                            // drop ERaw numeric sentinels
                        default:
                            out.push(s);
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                case EDo(stmts):
                    var out2: Array<ElixirAST> = [];
                    for (s in stmts) switch (s.def) {
                        case EInteger(v) if (v == 1 || v == 0):
                        case EFloat(f) if (f == 0.0):
                        case ERaw(code) if (code.trim() == "1" || code.trim() == "0"):
                        default:
                            out2.push(s);
                    }
                    makeASTWithMeta(EDo(out2), n.metadata, n.pos);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var b = cl.body;
                        switch (b.def) {
                            case EBlock(stmts3):
                                var out3: Array<ElixirAST> = [];
                                for (s in stmts3) switch (s.def) {
                                    case EInteger(v3) if (v3 == 1 || v3 == 0):
                                    case EFloat(f3) if (f3 == 0.0):
                                    case ERaw(code3) if (code3.trim() == "1" || code3.trim() == "0"):
                                    default: out3.push(s);
                                }
                                newClauses.push({ args: cl.args, guard: cl.guard, body: makeASTWithMeta(EBlock(out3), b.metadata, b.pos) });
                            default:
                                newClauses.push(cl);
                        }
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                // Do NOT rewrite numeric literals inside EIf/ECase branches – they are legitimate values
                default:
                    n;
            }
        });
    }
}

#end
