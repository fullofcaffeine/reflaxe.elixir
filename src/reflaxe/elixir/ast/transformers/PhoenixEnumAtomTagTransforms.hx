package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.NameUtils;

/**
 * PhoenixEnumAtomTagTransforms
 *
 * WHAT
 * - Rewrites generated Phoenix.* enum-like modules that return index-tagged tuples
 *   (e.g., {0}, {1, arg}) into atom-tagged tuples using the function name as the tag
 *   (e.g., {:raise}, {:check, arg}).
 *
 * WHY
 * - Some framework enum helpers are emitted without @:elixirIdiomatic, producing
 *   non-idiomatic numeric tags. Phoenix/Ecto idioms expect atom tags; this pass
 *   ensures we output atoms without depending on app-specific names.
 *
 * HOW
 * - Targets modules whose name starts with "Phoenix." only.
 * - For each public function whose body is a tuple with an integer as first element,
 *   replace the first element with an atom built from the function name (snake_case).
 * - Preserves arguments/arity by keeping subsequent tuple elements as arg refs.
 *
 * EXAMPLES
 *   def raise(), do: {0}           → def raise(), do: {:raise}
 *   def check(arg), do: {0, arg}   → def check(arg), do: {:check, arg}
 */
class PhoenixEnumAtomTagTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDefmodule(name, doBlock) if (name != null && StringTools.startsWith(name, "Phoenix.")):
                    var newDo = rewriteModule(doBlock);
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteModule(doBlock: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(doBlock, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EBlock(stmts):
                    var out = [];
                    for (s in stmts) out.push(rewriteStmt(s));
                    makeASTWithMeta(EBlock(out), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }

    static function rewriteStmt(stmt: ElixirAST): ElixirAST {
        return switch (stmt.def) {
            case EDef(fname, args, guards, body):
                var newBody = rewriteBody(fname, args, body);
                makeASTWithMeta(EDef(fname, args, guards, newBody), stmt.metadata, stmt.pos);
            case EDefp(fname, args, guards, body):
                var newBody2 = rewriteBody(fname, args, body);
                makeASTWithMeta(EDefp(fname, args, guards, newBody2), stmt.metadata, stmt.pos);
            default:
                stmt;
        }
    }

    static function rewriteBody(fname: String, args: Array<EPattern>, body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case ETuple(elements) if (elements.length > 0):
                switch (elements[0].def) {
                    case EInteger(_idx):
                        var tag = NameUtils.toSnakeCase(fname);
                        var newElements = elements.copy();
                        newElements[0] = makeAST(EAtom(tag));
                        makeASTWithMeta(ETuple(newElements), body.metadata, body.pos);
                    default:
                        body;
                }
            default:
                body;
        }
    }
}

#end

