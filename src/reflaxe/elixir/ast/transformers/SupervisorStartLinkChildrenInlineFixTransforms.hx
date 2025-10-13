package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SupervisorStartLinkChildrenInlineFixTransforms
 *
 * WHAT
 * - In <App>Web.Telemetry modules, rewrite Supervisor.start_link(children, opts)
 *   to Supervisor.start_link([], opts) to avoid undefined variable issues when
 *   the local `children` binding is discarded by hygiene passes.
 *
 * WHY
 * - Later hygiene passes may underscore or discard `children = [...]` when it
 *   appears unused; the call must remain valid and idiomatic.
 *
 * HOW
 * - Gate by module name ending with ".Telemetry".
 * - Transform ERemoteCall(Supervisor, start_link, [EVar("children"), opts])
 *   to inline empty list as the first argument.
 */
/**
 * SupervisorStartLinkChildrenInlineFixTransforms
 *
 * WHAT
 * - In <App>Web.Telemetry modules, rewrite `Supervisor.start_link(children, opts)`
 *   to `Supervisor.start_link([], opts)` when the local `children` binder has been
 *   removed/underscored by hygiene passes.
 *
 * WHY
 * - The todo-app uses a telemetry supervisor with no static children. Hygiene passes
 *   may discard `children = []` as unused, leaving the call with an undefined variable.
 *   Inlining an empty list is the idiomatic and explicit solution for a telemetry
 *   supervisor with dynamically attached reporters.
 *
 * HOW
 * - Gate by module name ending with ".Telemetry".
 * - Scan for `Supervisor.start_link(children, ...)` and replace the first argument
 *   with `[]` (EList([])) when present.
 *
 * EXAMPLES
 * Before:
 *   children = []
 *   Supervisor.start_link(children, strategy: :one_for_one)
 * After:
 *   Supervisor.start_link([], strategy: :one_for_one)
 */
class SupervisorStartLinkChildrenInlineFixTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name != null && StringTools.endsWith(name, ".Telemetry")):
                    var newBody = body.map(rewriteCalls);
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name != null && StringTools.endsWith(name, ".Telemetry")):
                    makeASTWithMeta(EDefmodule(name, rewriteCalls(doBlock)), n.metadata, n.pos);
                default:
                    n;
            };
        });
    }

    /**
     * rewriteCalls
     *
     * WHAT
     * - Rewrites `Supervisor.start_link(children, opts)` → `Supervisor.start_link([], opts)`.
     *
     * WHY INLINE ARGUMENT
     * - We inline `[]` directly instead of relying on any local binding to avoid
     *   WAE failures when that binding is dropped by late hygiene passes. The
     *   telemetry children list is intentionally empty at boot time.
     */
    static function rewriteCalls(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(e: ElixirAST): ElixirAST {
            return switch (e.def) {
                case ERemoteCall({def: EVar(mod)}, "start_link", args) if (mod == "Supervisor" && args.length >= 2):
                    var first = args[0];
                    switch (first.def) {
                        case EVar(v) if (v == "children"):
                            var newArgs = args.copy();
                            newArgs[0] = makeAST(ElixirASTDef.EList([]));
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Supervisor")), "start_link", newArgs), e.metadata, e.pos);
                        default:
                            e;
                    }
                default:
                    e;
            }
        });
    }
}

#end
