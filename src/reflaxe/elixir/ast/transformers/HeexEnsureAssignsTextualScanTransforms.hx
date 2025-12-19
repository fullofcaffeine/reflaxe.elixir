package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexEnsureAssignsTextualScanTransforms
 *
 * WHAT
 * - Extremely-late safety pass that ensures functions containing ~H sigils
 *   have a local `assigns` map when they do not declare assigns/_assigns.
 *
 * WHY
 * - Some ~H fragments originate very late (after multiple rewrites). This pass
 *   uses a textual scan (printer) to detect ~H in the function body and injects
 *   `assigns = %{}` if missing, avoiding Phoenix macro expansion errors.
 *
 * HOW
 * - For EDef/EDefp without assigns/_assigns:
 *   - Print the body to string and search for "~H\"" or "~H\"\"\"".
 *   - If found and body not already prefixed with assigns binding, wrap body in
 *     a block that first binds assigns to %{}.
 */
class HeexEnsureAssignsTextualScanTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) | EDefp(name, args, guards, body):
                    var hasAssignsParam = false;
                    for (a in args) switch (a) {
                        case PVar(p) if (p == "assigns" || p == "_assigns"): hasAssignsParam = true;
                        default:
                    }
                    if (hasAssignsParam) return n;
                    // Avoid double-injection if the first statement already binds assigns
                    var alreadyBinds = false;
                    switch (body.def) {
                        case EBlock(stmts) if (stmts.length > 0):
                            switch (stmts[0].def) {
                                case EMatch(PVar(v), e) if (v == "assigns"):
                                    alreadyBinds = true;
                                default:
                            }
                        default:
                    }
                    if (alreadyBinds) return n;
                    var printed:String = null;
                    try {
                        printed = reflaxe.elixir.ast.ElixirASTPrinter.printAST(body);
                    } catch (e) {}
                    if (printed != null && (printed.indexOf("~H\"") != -1 || printed.indexOf("~H\"\"\"") != -1)) {
                        var wrapped = makeAST(EBlock([
                            makeAST(EMatch(PVar("assigns"), makeAST(EMap([])))),
                            body
                        ]));
                        var def = Type.enumConstructor(n.def) == "EDef"
                            ? EDef(name, args, guards, wrapped)
                            : EDefp(name, args, guards, wrapped);
                        return makeASTWithMeta(def, n.metadata, n.pos);
                    }
                    n;
                default:
                    n;
            }
        });
    }
}

#end
