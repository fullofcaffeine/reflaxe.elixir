package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * RemoteCallModuleAliasCaseNormalizeTransforms
 *
 * WHAT
 * - Ensures remote call module targets are valid Elixir aliases (UpperCamelCase)
 *   when they are currently emitted as lowercase identifiers.
 *
 * WHY
 * - In Elixir, `Module.fun/arity` requires the module segment(s) to be aliases.
 *   Lowercase module targets (e.g. `users.list_users()`) are interpreted as
 *   variables and cause hard compile errors ("undefined variable users").
 * - Some upstream builder/transform interactions can accidentally downcase a
 *   module reference in expression position. This pass is a safe, target-syntax
 *   guardrail that restores a valid alias form.
 *
 * HOW
 * - Walk the AST and:
 *   - For `ERemoteCall(EVar(name), ...)` where `name` begins with a lowercase
 *     letter, rewrite to an alias-cased version.
 *   - For `ECapture(EField(EVar(name), fun), arity)` where `name` begins with a
 *     lowercase letter, rewrite similarly.
 * - Alias casing:
 *   - `users` → `Users`
 *   - `user_live` → `UserLive`
 *   - `my_app.users` → `MyApp.Users`
 *
 * EXAMPLES
 * Before:
 *   users = users.list_users(nil)
 * After:
 *   users = Users.list_users(nil)
 */
@:nullSafety(Off)
class RemoteCallModuleAliasCaseNormalizeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(module, funcName, args):
                    var fixedModule = normalizeModuleExpr(module);
                    if (fixedModule == module) n else makeASTWithMeta(ERemoteCall(fixedModule, funcName, args), n.metadata, n.pos);

                case ECapture(inner, arity):
                    var fixedInner = switch (inner.def) {
                        case EField(modExpr, fieldName):
                            var fixedMod = normalizeModuleExpr(modExpr);
                            fixedMod == modExpr ? inner : makeASTWithMeta(EField(fixedMod, fieldName), inner.metadata, inner.pos);
                        default:
                            inner;
                    };
                    if (fixedInner == inner) n else makeASTWithMeta(ECapture(fixedInner, arity), n.metadata, n.pos);

                default:
                    n;
            }
        });
    }

    static function normalizeModuleExpr(moduleExpr: ElixirAST): ElixirAST {
        if (moduleExpr == null || moduleExpr.def == null) return moduleExpr;
        return switch (moduleExpr.def) {
            case EVar(name):
                var fixed = normalizeAliasName(name);
                fixed == name ? moduleExpr : makeASTWithMeta(EVar(fixed), moduleExpr.metadata, moduleExpr.pos);
            default:
                moduleExpr;
        };
    }

    static function normalizeAliasName(name: String): String {
        if (name == null || name.length == 0) return name;
        var parts = name.split(".");
        var changed = false;
        for (i in 0...parts.length) {
            var seg = parts[i];
            if (seg == null || seg.length == 0) continue;
            // Preserve special forms and already-alias segments.
            var first = seg.charAt(0);
            if (first == "_" || (first.toUpperCase() == first && first.toLowerCase() != first)) continue;
            // Only rewrite when the segment begins with a lowercase letter.
            if (first.toLowerCase() == first && first.toUpperCase() != first) {
                var aliased = snakeToAlias(seg);
                if (aliased != seg) {
                    parts[i] = aliased;
                    changed = true;
                }
            }
        }
        return changed ? parts.join(".") : name;
    }

    static function snakeToAlias(seg: String): String {
        if (seg == null || seg.length == 0) return seg;
        var pieces = seg.split("_");
        if (pieces.length <= 1) {
            var c = seg.charAt(0);
            return c.toUpperCase() + seg.substr(1);
        }
        var out = new StringBuf();
        for (p in pieces) {
            if (p == null || p.length == 0) continue;
            out.add(p.charAt(0).toUpperCase());
            if (p.length > 1) out.add(p.substr(1));
        }
        return out.toString();
    }
}

#end

