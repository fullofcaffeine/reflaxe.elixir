package reflaxe.elixir.ast.analyzers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import StringTools;

/**
 * ValueShapeAnalyzer
 *
 * WHAT
 * - Lightweight analyzer to classify variable "value shapes" within an AST region:
 *   - id_like: variable name is `id`, `_id`, or ends with `_id`
 *   - struct: variable is used as a field receiver (e.g., `var.field`) or bracket access
 *   - unknown: neither of the above observed
 *
 * WHY
 * - Some late renamer/normalizer passes can inadvertently rewrite an argument from an
 *   id-like scalar to a struct-like binder (or vice versa). This analyzer provides a
 *   minimal, shape-based signal to prevent incompatible rewrites without introducing
 *   target-specific heuristics or fake APIs.
 *
 * HOW
 * - Walks the AST subtree to collect usages. Name-based id detection is limited to
 *   conventional `*_id` parameters and does not couple to application names.
 *
 * LIMITATIONS
 * - This is a heuristic signal, not a full type system. It intentionally errs on the
 *   side of caution and only asserts struct-ness when a variable is a field/index receiver.
 */
class ValueShapeAnalyzer {
    public static function classify(body: ElixirAST): Map<String, String> {
        var shape = new Map<String, String>();

        inline function markIdLike(name: String): Void {
            if (name == null) return;
            var base = (name.length > 0 && name.charAt(0) == '_') ? name.substr(1) : name;
            if (base == 'id' || StringTools.endsWith(base, '_id')) {
                if (!shape.exists(name)) shape.set(name, 'id_like');
            }
        }

        function visit(e: ElixirAST): Void {
            if (e == null || e.def == null) return;
            switch (e.def) {
                case EVar(nm):
                    markIdLike(nm);
                case EField(target, _):
                    switch (target.def) {
                        case EVar(nm): shape.set(nm, 'struct');
                        default:
                    }
                    visit(target);
                case EAccess(target, key):
                    switch (target.def) {
                        case EVar(nm): shape.set(nm, 'struct');
                        default:
                    }
                    visit(target); visit(key);
                case EBlock(ss): for (s in ss) visit(s);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case ECase(expr, cs): visit(expr); for (c in cs) { if (c.guard != null) visit(c.guard); visit(c.body); }
                case ECall(t, _, as): if (t != null) visit(t); if (as != null) for (a in as) visit(a);
                case ERemoteCall(t2, _, as2): visit(t2); if (as2 != null) for (a in as2) visit(a);
                case EList(els): for (el in els) visit(el);
                case ETuple(els): for (el in els) visit(el);
                case EMap(pairs): for (p in pairs) { visit(p.key); visit(p.value); }
                default:
            }
        }
        visit(body);
        return shape;
    }

    public static inline function isIdLike(name: String, shapes: Map<String, String>): Bool {
        if (name == null) return false;
        var base = (name.length > 0 && name.charAt(0) == '_') ? name.substr(1) : name;
        return (base == 'id' || StringTools.endsWith(base, '_id')) || (shapes.exists(name) && shapes.get(name) == 'id_like');
    }

    public static inline function isStructLike(name: String, shapes: Map<String, String>): Bool {
        return name != null && shapes.exists(name) && shapes.get(name) == 'struct';
    }
}

#end

