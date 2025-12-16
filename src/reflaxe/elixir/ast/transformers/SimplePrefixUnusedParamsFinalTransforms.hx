package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.EPattern;

/**
 * SimplePrefixUnusedParamsFinalTransforms
 *
 * WHAT
 * - Ultra-final safety net that prefixes unused function parameters with underscore.
 *
 * WHY
 * - Some edge cases slip past builder-time usage detection and earlier hygiene passes
 *   (e.g., when function bodies are unavailable or analysis order hides usage).
 *   This pass operates directly on the Elixir AST at the end to ensure idiomatic shapes.
 *
 * HOW
 * - For EDef/EDefp/EDefmacro/EDefmacrop, collect PVar arg names.
 * - If a param name is not referenced in the body, rename to "_" + name (if not already underscored).
 */
class SimplePrefixUnusedParamsFinalTransforms {
    static inline function preserveParamName(name: Null<String>): Bool {
        return name == "assigns" || name == "opts" || name == "args" || name == "conn" || name == "params";
    }

    static function collectVarUsage(ast: ElixirAST, target: String): Bool {
        var used = false;
        if (ast == null) return false;
        ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            if (!used) switch (n.def) {
                case EVar(name) if (name == target):
                    used = true;
                default:
            }
            return n;
        });
        return used;
    }

    static function renameInPattern(p: EPattern, renames: Map<String,String>): EPattern {
        return switch (p) {
            case PVar(n):
                renames.exists(n) ? PVar(renames.get(n)) : p;
            case PTuple(ps): PTuple(ps.map(pp -> renameInPattern(pp, renames)));
            case PList(ps): PList(ps.map(pp -> renameInPattern(pp, renames)));
            case PMap(pairs): PMap([for (pair in pairs) { key: pair.key, value: renameInPattern(pair.value, renames) }]);
            case PCons(h, t): PCons(renameInPattern(h, renames), renameInPattern(t, renames));
            case PPin(pp): PPin(renameInPattern(pp, renames));
            default: p;
        };
    }

    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case EDef(name, args, guards, body):
                    var ren = new Map<String,String>();
                    // Identify unused vars
                    for (a in args) switch (a) {
                        case PVar(vn):
                            if (vn != null && vn.length > 0 && vn.charAt(0) != "_" && !preserveParamName(vn) && !collectVarUsage(body, vn)) {
                                ren.set(vn, "_" + vn);
                            }
                        default:
                    }
                    if (ren.keys().hasNext()) {
                        var newArgs = args.map(a -> renameInPattern(a, ren));
                        return makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos);
                    }
                    return n;
                case EDefp(name, args, guards, body):
                    var ren2 = new Map<String,String>();
                    for (a in args) switch (a) {
                        case PVar(vn): if (vn != null && vn.length > 0 && vn.charAt(0) != "_" && !preserveParamName(vn) && !collectVarUsage(body, vn)) ren2.set(vn, "_" + vn);
                        default:
                    }
                    if (ren2.keys().hasNext()) {
                        var newArgs2 = args.map(a -> renameInPattern(a, ren2));
                        return makeASTWithMeta(EDefp(name, newArgs2, guards, body), n.metadata, n.pos);
                    }
                    return n;
                case EDefmacro(name, args, guards, body):
                    var ren3 = new Map<String,String>();
                    for (a in args) switch (a) {
                        case PVar(vn): if (vn != null && vn.length > 0 && vn.charAt(0) != "_" && !preserveParamName(vn) && !collectVarUsage(body, vn)) ren3.set(vn, "_" + vn);
                        default:
                    }
                    if (ren3.keys().hasNext()) {
                        var newArgs3 = args.map(a -> renameInPattern(a, ren3));
                        return makeASTWithMeta(EDefmacro(name, newArgs3, guards, body), n.metadata, n.pos);
                    }
                    return n;
                case EDefmacrop(name, args, guards, body):
                    var ren4 = new Map<String,String>();
                    for (a in args) switch (a) {
                        case PVar(vn): if (vn != null && vn.length > 0 && vn.charAt(0) != "_" && !preserveParamName(vn) && !collectVarUsage(body, vn)) ren4.set(vn, "_" + vn);
                        default:
                    }
                    if (ren4.keys().hasNext()) {
                        var newArgs4 = args.map(a -> renameInPattern(a, ren4));
                        return makeASTWithMeta(EDefmacrop(name, newArgs4, guards, body), n.metadata, n.pos);
                    }
                    return n;
                default:
                    return n;
            }
        });
    }
}

#end
