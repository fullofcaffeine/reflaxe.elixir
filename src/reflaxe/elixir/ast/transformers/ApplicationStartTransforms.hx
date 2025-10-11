package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * ApplicationStartTransforms
 *
 * WHAT
 * - Aligns Supervisor.start_link(children, opts) argument names with the locally
 *   declared binders inside Application.start/2 (e.g., `children` vs `_children`).
 *
 * WHY
 * - Hygiene passes can underscore apparently-unused locals, leaving call sites
 *   still referencing the base names and causing undefined-variable errors.
 *
 * HOW
 * - In def start/2, collect EMatch(PVar) locals for `children`/`opts` (with or
 *   without underscore) and rewrite subsequent Supervisor.start_link/2 arguments
 *   to the actually declared names.
 *
 * EXAMPLES
 * Haxe:
 *   @:elixir.module("TodoApp.Application") class App { static function start() {} }
 *
 * Elixir before:
 *   def start(_t,_a) do
 *     _children = [...]
 *     _opts = [strategy: :one_for_one]
 *     Supervisor.start_link(children, opts)
 *   end
 *
 * Elixir after:
 *   def start(_t,_a) do
 *     _children = [...]
 *     _opts = [strategy: :one_for_one]
 *     Supervisor.start_link(_children, _opts)
 *   end
 */
class ApplicationStartTransforms {
    public static function normalizeStartLinkArgsPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, params, guards, body) if (name == "start"):
                    var declaredChildren: Null<String> = null;
                    var declaredOpts: Null<String> = null;

                    // Collect declared names from simple match binders inside this function
                    ASTUtils.walk(body, function(n: ElixirAST) {
                        switch (n.def) {
                            case EMatch(p, _):
                                switch (p) {
                                    case PVar(v):
                                        if (v == "children" || v == "_children") declaredChildren = v;
                                        if (v == "opts" || v == "_opts") declaredOpts = v;
                                    default:
                                }
                            default:
                        }
                    });

                    // If nothing collected, return as-is
                    if (declaredChildren == null && declaredOpts == null) return node;
                    // If we plan to rename declarations to non-underscored, update our expected names
                    if (declaredChildren == "_children") declaredChildren = "children";
                    if (declaredOpts == "_opts") declaredOpts = "opts";

                    // Rewrite Supervisor.start_link(children, opts) args if needed
                    function rewrite(n: ElixirAST): ElixirAST {
                        return switch (n.def) {
                            // Rename local declarations to non-underscored names for idiomatic usage
                            case EMatch(PVar(v), expr) if (v == "_children"):
                                makeASTWithMeta(EMatch(PVar("children"), expr), n.metadata, n.pos);
                            case EMatch(PVar(v), expr) if (v == "_opts"):
                                makeASTWithMeta(EMatch(PVar("opts"), expr), n.metadata, n.pos);
                            case ERemoteCall(mod, fn, args) if (fn == "start_link" && args != null && args.length == 2):
                                var isSupervisor = switch (mod.def) { case EVar(m): m == "Supervisor"; default: false; };
                                if (!isSupervisor) return n;

                                var newArgs = args.copy();
                                switch (newArgs[0].def) {
                                    case EVar(v) if (declaredChildren != null && v != declaredChildren && (v == "children" || v == "_children")):
                                        newArgs[0] = makeASTWithMeta(EVar(declaredChildren), newArgs[0].metadata, newArgs[0].pos);
                                    default:
                                }
                                switch (newArgs[1].def) {
                                    case EVar(v) if (declaredOpts != null && v != declaredOpts && (v == "opts" || v == "_opts")):
                                        newArgs[1] = makeASTWithMeta(EVar(declaredOpts), newArgs[1].metadata, newArgs[1].pos);
                                    default:
                                }
                                // Only rebuild call if we actually changed something
                                if (newArgs[0] != args[0] || newArgs[1] != args[1]) {
                                    makeASTWithMeta(ERemoteCall(mod, fn, newArgs), n.metadata, n.pos);
                                } else {
                                    n;
                                }
                            default:
                                n;
                        }
                    }

                    var newBody = ElixirASTTransformer.transformNode(body, rewrite);
                    makeASTWithMeta(EDef(name, params, guards, newBody), node.metadata, node.pos);

                default:
                    node;
            }
        });
    }
}

#end
