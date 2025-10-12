package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * TelemetryChildrenArgFixTransforms
 *
 * WHAT
 * - In <App>Web.Telemetry.start_link/1 function bodies, if a local variable
 *   assignment to _children exists and Supervisor.start_link(children, ...) uses
 *   the non-underscore name, rewrite the call to use _children to avoid
 *   undefined variable errors when unused-local renaming occurs earlier.
 *
 * WHY
 * - The UnusedLocalAssignmentUnderscoreTransforms may underscore-bind children,
 *   but Supervisor.start_link(children, ...) can still reference the old name.
 *   This pass reconciles names to prevent undefined variable errors.
 *
 * HOW
 * - Detect presence of a PVar("_children") binding in the subtree.
 * - Rewrite ERemoteCall(Supervisor, start_link, [EVar("children"), opts]) to
 *   use EVar("_children") when the underscored binding exists.
 *
 * EXAMPLES
 * Before:
 *   _children = [...]
 *   Supervisor.start_link(children, strategy: :one_for_one)
 * After:
 *   _children = [...]
 *   Supervisor.start_link(_children, strategy: :one_for_one)
 *
 * SCOPE
 * - Limited to modules whose name ends with ".Telemetry" to avoid overreach.
 */
class TelemetryChildrenArgFixTransforms {
    public static function fixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name != null && StringTools.endsWith(name, ".Telemetry")):
                    var newBody = body.map(fixInNode);
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name != null && StringTools.endsWith(name, ".Telemetry")):
                    makeASTWithMeta(EDefmodule(name, fixInNode(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function fixInNode(node: ElixirAST): ElixirAST {
        var hasUnderscoredChildren = false;
        // First scan for _children assignment in this subtree
        function scan(e: ElixirAST): Void {
            if (e == null || e.def == null) return;
            switch (e.def) {
                case EMatch(PVar(name), _): if (name == "_children") hasUnderscoredChildren = true;
                case EBlock(stmts): for (s in stmts) scan(s);
                default:
            }
        }
        scan(node);
        if (!hasUnderscoredChildren) return node;

        // Rewrite Supervisor.start_link(children, opts) -> Supervisor.start_link(_children, opts)
        return ElixirASTTransformer.transformNode(node, function(e: ElixirAST): ElixirAST {
            return switch (e.def) {
                case ERemoteCall({def: EVar(mod)}, "start_link", [firstArg, opts]) if (mod == "Supervisor"):
                    switch (firstArg.def) {
                        case EVar(v) if (v == "children"):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Supervisor")), "start_link", [makeAST(ElixirASTDef.EVar("_children")), opts]), e.metadata, e.pos);
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
