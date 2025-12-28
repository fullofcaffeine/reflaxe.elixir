package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PinnedVarRequireEctoQueryTransforms
 *
 * WHAT
 * - Ensures `require Ecto.Query` is present in any module whose body contains
 *   the Elixir pin operator at the AST level (EPin nodes), which typically
 *   indicates Ecto.Query macro usage in conditions.
 *
 * WHY
 * - Without `require Ecto.Query`, remote macro calls like `Ecto.Query.where/2`
 *   won’t expand and the pin operator is considered misplaced by the compiler.
 *   This pass adds a deterministic safeguard based on EPin presence.
 *
 * HOW
 * - For EModule/EDefmodule bodies, scan recursively for any EPin occurrence.
 * - If found and no existing ERequire("Ecto.Query"), prepend one at the top.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class PinnedVarRequireEctoQueryTransforms {
    static function bodyHasPin(body:Array<ElixirAST>):Bool {
        var found = false;
        for (b in body) if (!found) {
            ElixirASTTransformer.transformNode(b, function(x:ElixirAST):ElixirAST {
                if (found) return x;
                switch (x.def) {
                    case EPin(_): found = true; return x;
                    default: return x;
                }
            });
        }
        return found;
    }
    static function hasRequire(body:Array<ElixirAST>):Bool {
        for (b in body) switch (b.def) {
            case ERequire(mod, _) if (mod == "Ecto.Query"): return true;
            default:
        }
        return false;
    }
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    if (bodyHasPin(body) && !hasRequire(body)) {
                        var req = makeAST(ERequire("Ecto.Query", null));
                        makeASTWithMeta(EModule(name, attrs, [req].concat(body)), n.metadata, n.pos);
                    } else n;
                case EDefmodule(name, doBlock):
                    // Extract body statements from block
                    var stmts:Array<ElixirAST> = switch (doBlock.def) {
                        case EBlock(ss): ss;
                        case EDo(ss2): ss2;
                        default: [doBlock];
                    };
                    if (bodyHasPin(stmts) && !hasRequire(stmts)) {
                        var req2 = makeAST(ERequire("Ecto.Query", null));
                        var newDo: ElixirAST = switch (doBlock.def) {
                            case EBlock(_): makeASTWithMeta(EBlock([req2].concat(stmts)), doBlock.metadata, doBlock.pos);
                            case EDo(_): makeASTWithMeta(EDo([req2].concat(stmts)), doBlock.metadata, doBlock.pos);
                            default: doBlock;
                        };
                        makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }
}

#end

