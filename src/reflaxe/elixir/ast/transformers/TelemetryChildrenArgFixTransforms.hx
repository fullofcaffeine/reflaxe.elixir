package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * TelemetryChildrenArgFixTransforms
 *
 * WHAT
 * - Repairs `Supervisor.start_link(children, ...)` calls in <App>Web.Telemetry when
 *   local binders were altered by hygiene (e.g., `_children = ...` or `_ = ...`).
 *
 * WHY
 * - Hygiene passes can underscore or discard a local `children` binding as unused,
 *   leading to undefined-variable errors at the call site. This pass restores a
 *   consistent and idiomatic call by either:
 *   1) upgrading `_ = expr` to `_children = expr` and using `_children`, or
 *   2) inlining `[]` when appropriate (handled in a follow-up pass for safety).
 *
 * HOW
 * - Gate by module name ending with ".Telemetry".
 * - Scan for `_ = expr` or `children = expr` preceding `Supervisor.start_link(children, ...)`.
 * - If found, either bind `_children` explicitly or inline the RHS into the call,
 *   preserving semantics and avoiding WAE.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
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

    /**
     * fixInNode
     *
     * WHAT
     * - Rewrites call-site arguments to use `_children` when an underscored binding
     *   exists; otherwise, leaves the call unchanged.
     *
     * WHY INLINE EXPLANATION
     * - This pass prefers reusing an existing `_children` binding to keep code readable.
     *   When such a binding is absent, the companion inline fix pass will inline `[]`,
     *   which is appropriate for an empty telemetry tree and prevents undefined vars.
     */
    static function fixInNode(node: ElixirAST): ElixirAST {
        // Special handling for start_link/1: upgrade `_ = expr` to `_children = expr` when start_link(children, ...) present
        node = upgradeWildcardChildrenBinding(node);

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
                            // Prefer _children if present; otherwise inline [] to avoid undefined variable
                            if (hasUnderscoredChildren) {
                                makeASTWithMeta(ERemoteCall(makeAST(EVar("Supervisor")), "start_link", [makeAST(ElixirASTDef.EVar("_children")), opts]), e.metadata, e.pos);
                            } else {
                                makeASTWithMeta(ERemoteCall(makeAST(EVar("Supervisor")), "start_link", [makeAST(ElixirASTDef.EList([])), opts]), e.metadata, e.pos);
                            }
                        default:
                            e;
                    }
                default:
                    e;
            }
        });
    }

    /**
     * upgradeWildcardChildrenBinding
     *
     * WHAT
     * - If the code previously had `_ = expr` followed by `Supervisor.start_link(children, ...)`,
     *   upgrade the wildcard to `_children = expr` and switch the call-site to `_children`.
     *
     * WHY
     * - Wildcard assignments are ignored by Elixir, but the call-site expects a concrete
     *   variable. Binding `_children` is a minimal, local repair that avoids undefineds.
     */
    static function upgradeWildcardChildrenBinding(node: ElixirAST): ElixirAST {
        return switch (node.def) {
            case EDef("start_link", args, guards, body):
                switch (body.def) {
                    case EBlock(stmts):
                        // Detect pattern: `_ = expr` or `children = expr` followed by `Supervisor.start_link(children, opts)`
                        var wildcardIdx = -1;
                        var childrenAssignIdx = -1;
                        var startLinkIdx = -1;
                        for (i in 0...stmts.length) switch (stmts[i].def) {
                            case EMatch(PWildcard, _): if (wildcardIdx == -1) wildcardIdx = i;
                            case EBinary(Match, leftAssign, _):
                                switch (leftAssign.def) { case EVar(nm) if (nm == "children"): if (childrenAssignIdx == -1) childrenAssignIdx = i; default: }
                            case ERemoteCall({def: EVar(mod)}, "start_link", [firstArg, _]) if (mod == "Supervisor"):
                                switch (firstArg.def) { case EVar(v) if (v == "children"): startLinkIdx = i; default: }
                            default:
                        }
                        if (startLinkIdx != -1 && ((wildcardIdx != -1 && wildcardIdx < startLinkIdx) || (childrenAssignIdx != -1 && childrenAssignIdx < startLinkIdx))) {
                            // Inline the wildcard assignment RHS directly into start_link(children, ...)
                            var w = (wildcardIdx != -1) ? stmts[wildcardIdx] : stmts[childrenAssignIdx];
                            var rhsExpr: Null<ElixirAST> = null;
                            switch (w.def) { case EMatch(_, rhs): rhsExpr = rhs; default: }
                            switch (w.def) { case EBinary(Match, _, rhs): if (rhsExpr == null) rhsExpr = rhs; default: }
                            if (rhsExpr == null) return node;
                            var call = stmts[startLinkIdx];
                            var newCall: ElixirAST = switch (call.def) {
                                case ERemoteCall(moduleExpr, "start_link", args) if (args.length >= 1):
                                    var newArgs = args.copy();
                                    newArgs[0] = rhsExpr;
                                    makeASTWithMeta(ERemoteCall(moduleExpr, "start_link", newArgs), call.metadata, call.pos);
                                default: call;
                            };
                            var newStmts = [];
                            var dropIdx = (wildcardIdx != -1) ? wildcardIdx : childrenAssignIdx;
                            for (i in 0...stmts.length) if (i != dropIdx) newStmts.push(i == startLinkIdx ? newCall : stmts[i]);
                            var newBody = makeASTWithMeta(EBlock(newStmts), body.metadata, body.pos);
                            makeASTWithMeta(EDef("start_link", args, guards, newBody), node.metadata, node.pos);
                        } else node;
                    default:
                        node;
                }
            default:
                node;
        }
    }
}

#end
