package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer.OptimizedUsageIndex;

/**
 * DefParamUnusedUnderscoreTransforms
 *
 * WHAT
 * - Prefix unused function parameters with underscore in Phoenix Web/Live/Presence
 *   modules to eliminate warnings-as-errors without altering semantics.
 *
 * WHY
 * - Phoenix callbacks and helpers often accept parameters that are not always used
 *   in all shapes. Elixir warns on unused parameters; prefixing with underscore is
 *   idiomatic and explicit.
 *
 * HOW
 * - Scope to Phoenix modules by metadata (preferred) and name heuristics (fallback):
 *   - `metadata.isPhoenixWeb` / `metadata.isController` / `metadata.isLiveView` / `metadata.isPresence`
 *   - or module names that contain "Web.", end with ".Live"/".Presence", or end with "Web".
 *   Within such modules, for each EDef/EDefp, compute
 *   a conservative usage index for the body + guards (O(N) once) and underscore
 *   PVar(name) parameters that are not present in that usage index (O(1) per param).
 *
 * EXAMPLES
 * Before:
 *   def get_users_editing_todo(socket, todo_id) do ... end  # when todo_id unused
 * After:
 *   def get_users_editing_todo(socket, _todo_id) do ... end
 */
class DefParamUnusedUnderscoreTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    // Gate to Phoenix contexts only (shape-based + metadata)
                    var isPhoenixCtx = (n.metadata?.isPhoenixWeb == true)
                        || (n.metadata?.isController == true)
                        || (n.metadata?.isLiveView == true)
                        || (n.metadata?.isPresence == true)
                        || (name != null && name.indexOf("Controller") != -1)
                        || (name != null && ((name.indexOf("Web.") >= 0) || StringTools.endsWith(name, ".Live") || StringTools.endsWith(name, ".Presence") || StringTools.endsWith(name, "Web")));
                    // Do not alter Gettext modules to avoid breaking ngettext/dngettext count param
                    if (!isPhoenixCtx || (name != null && StringTools.endsWith(name, ".Gettext"))) return n;
                    var newBody = [];
                    for (b in body) newBody.push(rewriteDefs(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var isPhoenixCtx2 = (n.metadata?.isPhoenixWeb == true)
                        || (n.metadata?.isController == true)
                        || (n.metadata?.isLiveView == true)
                        || (n.metadata?.isPresence == true)
                        || (name != null && name.indexOf("Controller") != -1)
                        || (name != null && ((name.indexOf("Web.") >= 0) || StringTools.endsWith(name, ".Live") || StringTools.endsWith(name, ".Presence") || StringTools.endsWith(name, "Web")));
                    if (!isPhoenixCtx2 || (name != null && StringTools.endsWith(name, ".Gettext"))) return n;
                    makeASTWithMeta(EDefmodule(name, rewriteDefs(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteDefs(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EDef(name, args, guards, body):
                    // Build a conservative usage index once and reuse for all params.
                    var newArgs = underscoreUnusedParamsWithAnalyzer(args, body, guards);
                    makeASTWithMeta(EDef(name, newArgs, guards, body), x.metadata, x.pos);
                case EDefp(name, args2, guards2, body2):
                    // Build a conservative usage index once and reuse for all params.
                    var newArgs2 = underscoreUnusedParamsWithAnalyzer(args2, body2, guards2);
                    makeASTWithMeta(EDefp(name, newArgs2, guards2, body2), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }

    /**
     * Build usage indices once and reuse for each param pattern.
     */
    static function underscoreUnusedParamsWithAnalyzer(args: Array<EPattern>, body: ElixirAST, guards: Null<ElixirAST>): Array<EPattern> {
        if (args == null) return args;

        // Fast path: if there are no underscoreable binders, avoid building usage indices.
        if (!hasUnderscoreableBinder(args)) return args;

        var bodyUsage = OptimizedVarUseAnalyzer.build([body]);
        var guardUsage = guards != null ? OptimizedVarUseAnalyzer.build([guards]) : null;

        // Check each parameter pattern individually using the prebuilt usage index.
        var result: Array<EPattern> = [];
        for (a in args) {
            result.push(underscorePatternWithAnalyzer(a, bodyUsage, guardUsage));
        }
        return result;
    }

    /**
     * Underscore a pattern if it's a PVar that's not used in the body or guards.
     */
    static function underscorePatternWithAnalyzer(p: EPattern, bodyUsage: OptimizedUsageIndex, guardsUsage: Null<OptimizedUsageIndex>): EPattern {
        return switch (p) {
            case PVar(name):
                // Never underscore Phoenix-idiomatic parameter names that are commonly used indirectly
                var preserve = isPreservedParamName(name);
                if (preserve || name == null || name.length == 0 || name.charAt(0) == '_') {
                    p;
                } else {
                    var usedInBody = OptimizedVarUseAnalyzer.usedLater(bodyUsage, 0, name);
                    var usedInGuards = guardsUsage != null && OptimizedVarUseAnalyzer.usedLater(guardsUsage, 0, name);
                    if (usedInBody || usedInGuards) {
                        p; // Keep unchanged - parameter is used
                    } else {
                        PVar("_" + name); // Add underscore prefix
                    }
                }
            case PTuple(es): PTuple([for (e in es) underscorePatternWithAnalyzer(e, bodyUsage, guardsUsage)]);
            case PList(es): PList([for (e in es) underscorePatternWithAnalyzer(e, bodyUsage, guardsUsage)]);
            case PCons(h, t): PCons(underscorePatternWithAnalyzer(h, bodyUsage, guardsUsage), underscorePatternWithAnalyzer(t, bodyUsage, guardsUsage));
            case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: underscorePatternWithAnalyzer(kv.value, bodyUsage, guardsUsage) }]);
            case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: underscorePatternWithAnalyzer(f.value, bodyUsage, guardsUsage) }]);
            case PPin(inner): PPin(underscorePatternWithAnalyzer(inner, bodyUsage, guardsUsage));
            default: p;
        };
    }

    static inline function isPreservedParamName(name: String): Bool {
        return name == "assigns" || name == "opts" || name == "args" || name == "conn" || name == "params";
    }

    static function hasUnderscoreableBinder(args: Array<EPattern>): Bool {
        var found = false;
        function visit(p: EPattern): Void {
            if (found) return;
            switch (p) {
                case PVar(name) if (name != null && name.length > 0 && name.charAt(0) != '_' && !isPreservedParamName(name)):
                    found = true;
                case PTuple(es) | PList(es):
                    for (e in es) visit(e);
                case PCons(h, t):
                    visit(h);
                    visit(t);
                case PMap(kvs):
                    for (kv in kvs) visit(kv.value);
                case PStruct(_, fs):
                    for (f in fs) visit(f.value);
                case PPin(inner):
                    visit(inner);
                default:
            }
        }
        if (args != null) for (a in args) visit(a);
        return found;
    }
}

#end
