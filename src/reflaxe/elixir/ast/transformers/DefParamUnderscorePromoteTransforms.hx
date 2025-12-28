package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * DefParamUnderscorePromoteTransforms
 *
 * WHAT
 * - Promotes function parameters declared with a leading underscore (e.g., `_id`)
 *   to their non-underscored form (`id`) when the body references the trimmed
 *   name. This aligns declarations with actual usage and eliminates warnings
 *   like: "the underscored variable \"_id\" is used after being set".
 *
 * WHY
 * - In idiomatic Elixir, a leading underscore indicates an intentionally unused
 *   binding. If the body references `id` while the parameter is `_id`, the code
 *   compiles but emits warnings. Promoting the binder fixes hygiene without any
 *   app-coupled heuristics.
 *
 * HOW
 * - For each def/defp:
 *   1) Gather parameter binder names.
 *   2) Collect closure-aware references from the body (VariableUsageCollector).
 *   3) For any param `_name` where `name` is referenced and no parameter named
 *      `name` exists, rename the binder to `name`.
 *   4) Body references already use `name`, so no body rewrite is needed.
 *
 * LIMITS
 * - Skips promotion when a param named `name` already exists to avoid shadowing.
 * - Does not modify anonymous function clauses (covered by other passes).

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class DefParamUnderscorePromoteTransforms {
    public static function promotePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var updated = promoteArgs(args, body);
                    makeASTWithMeta(EDef(name, updated, guards, body), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    var updated = promoteArgs(args, body);
                    makeASTWithMeta(EDefp(name, updated, guards, body), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function promoteArgs(args:Array<EPattern>, body: ElixirAST): Array<EPattern> {
        if (args == null || args.length == 0) return args;
        var refs = VariableUsageCollector.referencedInFunctionScope(body);
        // collect existing param names (non-underscored) to avoid conflicts
        var paramNames = new Map<String,Bool>();
        for (a in args) for (nm in collectPatternVars(a).keys())
            if (nm != null && nm.length > 0 && nm.charAt(0) != '_') paramNames.set(nm, true);
        // rewrite params where trimmed name is referenced and not already a param
        return [for (a in args) promotePattern(a, refs, paramNames)];
    }

    static function collectPatternVars(p:EPattern): Map<String,Bool> {
        var m = new Map<String,Bool>();
        function walk(pt:EPattern):Void {
            switch (pt) {
                case PVar(n): if (n != null) m.set(n, true);
                case PTuple(es): for (e in es) walk(e);
                case PList(es): for (e in es) walk(e);
                case PCons(h, t): walk(h); walk(t);
                case PMap(kvs): for (kv in kvs) walk(kv.value);
                case PStruct(_, fs): for (f in fs) walk(f.value);
                case PPin(inner): walk(inner);
                case PAlias(nm, pat): if (nm != null) m.set(nm, true); walk(pat);
                default:
            }
        }
        walk(p);
        return m;
    }

    static function promotePattern(p:EPattern, refs:Map<String,Bool>, existing:Map<String,Bool>): EPattern {
        return switch (p) {
            case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
                var trimmed = n.substr(1);
                if (refs.exists(trimmed) && !existing.exists(trimmed)) PVar(trimmed) else p;
            case PAlias(nm, pat) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
                var trimmedA = nm.substr(1);
                var inner = promotePattern(pat, refs, existing);
                if (refs.exists(trimmedA) && !existing.exists(trimmedA)) PAlias(trimmedA, inner) else PAlias(nm, inner);
            case PTuple(es): PTuple([for (e in es) promotePattern(e, refs, existing)]);
            case PList(es): PList([for (e in es) promotePattern(e, refs, existing)]);
            case PCons(h, t): PCons(promotePattern(h, refs, existing), promotePattern(t, refs, existing));
            case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: promotePattern(kv.value, refs, existing) }]);
            case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: promotePattern(f.value, refs, existing) }]);
            case PPin(inner): PPin(promotePattern(inner, refs, existing));
            default: p;
        }
    }
}

#end

