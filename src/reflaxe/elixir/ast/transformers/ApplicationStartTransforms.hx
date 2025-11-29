package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;
import reflaxe.elixir.ast.naming.ElixirAtom;
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
/**
 * ApplicationStartTransforms
 *
 * WHAT
 * - Normalizes `Supervisor.start_link(children, opts)` in Application.start/2 by
 *   aligning argument names to actually declared locals and appending the call when
 *   missing (with safe default opts).
 *
 * WHY
 * - Hygiene and extraction passes may rename or remove locals like `children`/`opts`.
 *   Aligning call arguments to declared binders and providing defaults when needed
 *   prevents undefined-variable errors while preserving idiomatic Elixir.
 *
 * HOW
 * - Scan the function body to detect declarations for `children`/`opts` (including
 *   underscored variants), rewrite call-site arguments accordingly, and if the call
 *   is missing add `Supervisor.start_link(children, [strategy: :one_for_one, ...])`.
 *
 * EXAMPLES
 * Before:
 *   _children = [...]; _opts = [strategy: :one_for_one]; Supervisor.start_link(children, opts)
 * After:
 *   children = [...]; opts = [strategy: :one_for_one]; Supervisor.start_link(children, opts)
 */
class ApplicationStartTransforms {
    /**
     * normalizeStartLinkArgsPass
     *
     * WHAT
     * - Align `Supervisor.start_link(children, opts)` with locally declared names and
     *   append a call with default keyword opts if absent.
     *
     * WHY DEFAULT/INLINE OPTS
     * - Using a keyword list literal at the call site avoids relying on a separate
     *   `opts` binding that might be removed by late hygiene passes. It keeps the
     *   generated code explicit and WAE-safe without changing semantics.
     */
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
                            case EBinary(Match, left, _):
                                switch (left.def) {
                                    case EVar(v2):
                                        if (v2 == "children" || v2 == "_children") declaredChildren = v2;
                                        if (v2 == "opts" || v2 == "_opts") declaredOpts = v2;
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

                    var transformedBody = ElixirASTTransformer.transformNode(body, rewrite);
                    // Ensure Supervisor.start_link(children, opts) exists; if missing, append it
                    var hasStartLink = false;
                    var finalBody: ElixirAST = null;
                    switch (transformedBody.def) {
                        case EBlock(stmts):
                            for (s in stmts) switch (s.def) {
                                case ERemoteCall(_, fn, _) if (fn == "start_link"):
                                    hasStartLink = true;
                                case EBinary(Match, _, rhs):
                                    switch (rhs.def) { case ERemoteCall(_, fn2, _) if (fn2 == "start_link"): hasStartLink = true; default: }
                                default:
                            }
                            if (!hasStartLink && declaredChildren != null) {
                                var appended = stmts.copy();
                                var defaultOpts = makeAST(EKeywordList([
                                    { key: "strategy", value: makeAST(EAtom(ElixirAtom.fromString(":one_for_one"))) }
                                ]));
                                appended.push(makeAST(ERemoteCall(makeAST(EVar("Supervisor")), "start_link", [makeAST(EVar(declaredChildren)), defaultOpts])));
                                finalBody = makeASTWithMeta(EBlock(appended), transformedBody.metadata, transformedBody.pos);
                            } else finalBody = transformedBody;
                        default:
                            if (!hasStartLink && declaredChildren != null) {
                                var defaultOpts2 = makeAST(EKeywordList([
                                    { key: "strategy", value: makeAST(EAtom(ElixirAtom.fromString(":one_for_one"))) }
                                ]));
                                finalBody = makeASTWithMeta(EBlock([transformedBody, makeAST(ERemoteCall(makeAST(EVar("Supervisor")), "start_link", [makeAST(EVar(declaredChildren)), defaultOpts2]))]), transformedBody.metadata, transformedBody.pos);
                            } else finalBody = transformedBody;
                    }
                    makeASTWithMeta(EDef(name, params, guards, finalBody), node.metadata, node.pos);

                default:
                    node;
            }
        });
    }
}

#end
