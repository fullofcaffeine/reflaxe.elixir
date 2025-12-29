package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;

/**
 * StrictModeEnforcer
 *
 * WHAT
 * - Adds an opt-in "strict mode" safety profile for Haxe→Elixir projects.
 * - When enabled, rejects:
 *   1) `untyped` expressions in project sources (including `untyped __elixir__()`).
 *   2) Explicit `Dynamic` types in public code (use `elixir.types.Term` at boundaries instead).
 *   3) Ad-hoc `extern class` definitions in app code unless explicitly annotated.
 *
 * WHY
 * - Keep application code "Haxe-first" and structurally analyzable by the compiler pipeline.
 * - Make unsafe escape hatches explicit so projects can adopt a Gleam-like discipline when desired.
 *
 * HOW
 * - Enabled by defining `-D reflaxe_elixir_strict` in the user's `.hxml`.
 * - Registers `Context.onAfterTyping` and:
 *   - Scans only project-local sources (under the current working directory), excluding this compiler’s
 *     own `src/reflaxe/**` and `std/**` sources.
 *   - Traverses typed expressions to detect `TUntyped`.
 *   - Walks types to detect `Dynamic` occurrences (allowing `elixir.types.Term` as the explicit boundary type).
 *   - Flags `extern class` declarations unless annotated with an allowed boundary metadata (e.g. `@:repo`)
 *     or explicitly marked as unsafe (`@:unsafeExtern`).
 *
 * EXAMPLES
 * Haxe (strict mode enabled):
 *   class Main {
 *     static function main() {
 *       var raw: Dynamic = 1; // ❌ rejected (use Term or a concrete type)
 *       untyped __elixir__("DateTime.utc_now()"); // ❌ rejected (move to std/ or a wrapper)
 *     }
 *   }
 *
 * Haxe (allowed boundary):
 *   import elixir.types.Term;
 *   class Main {
 *     static function handle(params: Term) {
 *       // ✅ params are explicitly boundary-typed
 *     }
 *   }
 */
class StrictModeEnforcer {
    public static function init(): Void {
        if (!isElixirBuild()) {
            return;
        }

        if (!Context.defined("reflaxe_elixir_strict")) {
            return;
        }

        var projectRoot = normalizePath(Sys.getCwd());
        Context.onAfterTyping(types -> enforce(types, projectRoot));
    }

    static function enforce(types: Array<ModuleType>, projectRoot: String): Void {
        for (moduleType in types) {
            switch (moduleType) {
                case TClassDecl(classRef):
                    var classType = classRef.get();
                    if (!isStrictProjectSource(classType.pos, projectRoot)) {
                        continue;
                    }

                    enforceExternClassRules(classType);
                    enforceNoDynamicTypesInClass(classType);
                    enforceNoUntypedExpressionsInClass(classType);

                case TEnumDecl(enumRef):
                    var enumType = enumRef.get();
                    if (!isStrictProjectSource(enumType.pos, projectRoot)) {
                        continue;
                    }

                    enforceNoDynamicTypesInEnum(enumType);

                case TTypeDecl(typeRef):
                    var defType = typeRef.get();
                    if (!isStrictProjectSource(defType.pos, projectRoot)) {
                        continue;
                    }

                    enforceNoDynamicType(defType.type, defType.pos, "typedef " + defType.name);

                case TAbstractDecl(absRef):
                    var abstractType = absRef.get();
                    if (!isStrictProjectSource(abstractType.pos, projectRoot)) {
                        continue;
                    }

                    enforceNoDynamicType(abstractType.type, abstractType.pos, "abstract " + abstractType.name);
            }
        }
    }

    static function enforceExternClassRules(classType: ClassType): Void {
        if (!classType.isExtern) {
            return;
        }

        if (isAllowedStrictExtern(classType)) {
            return;
        }

        Context.error(
            "Strict mode forbids ad-hoc `extern class` declarations in application code. " +
            "Move the extern to `std/` (framework-level), use a compiler-supported boundary annotation (e.g. `@:repo`), " +
            "or explicitly acknowledge the escape hatch with `@:unsafeExtern`.",
            classType.pos
        );
    }

    static function isAllowedStrictExtern(classType: ClassType): Bool {
        return classType.meta.has(":repo") ||
            classType.meta.has(":dbTypes") ||
            classType.meta.has(":postgrexTypes") ||
            classType.meta.has(":gettext") ||
            classType.meta.has(":unsafeExtern");
    }

    static function enforceNoDynamicTypesInClass(classType: ClassType): Void {
        var fields = classType.fields.get().concat(classType.statics.get());
        for (field in fields) {
            enforceNoDynamicType(field.type, field.pos, classType.name + "." + field.name);
        }
    }

    static function enforceNoDynamicTypesInEnum(enumType: EnumType): Void {
        for (constructor in enumType.constructs) {
            enforceNoDynamicType(constructor.type, constructor.pos, enumType.name + "." + constructor.name);
        }
    }

    static function enforceNoDynamicType(type: Type, pos: haxe.macro.Expr.Position, label: String): Void {
        if (!containsDynamic(type)) {
            return;
        }

        Context.error(
            "Strict mode forbids `Dynamic` in application types (" + label + "). " +
            "Prefer concrete types, or use `elixir.types.Term` as an explicit BEAM boundary type.",
            pos
        );
    }

    static function containsDynamic(type: Type): Bool {
        return switch (type) {
            case TDynamic(_):
                true;
            case TFun(args, ret):
                args.exists(arg -> containsDynamic(arg.t)) || containsDynamic(ret);
            case TInst(_, params) | TEnum(_, params) | TType(_, params):
                params.exists(containsDynamic);
            case TAbstract(abstractRef, params):
                if (isAllowedDynamicAbstract(abstractRef.get())) {
                    false;
                } else {
                    params.exists(containsDynamic);
                }
            case TAnon(anonRef):
                anonRef.get().fields.exists(field -> containsDynamic(field.type));
            case TLazy(thunk):
                containsDynamic(thunk());
            case TMono(monoRef):
                var resolved = monoRef.get();
                resolved != null && containsDynamic(resolved);
        }
    }

    static function isAllowedDynamicAbstract(abstractType: AbstractType): Bool {
        var path = abstractType.module + "." + abstractType.name;
        return path == "elixir.types.Term";
    }

    static function enforceNoUntypedExpressionsInClass(classType: ClassType): Void {
        var fields = classType.fields.get().concat(classType.statics.get());
        for (field in fields) {
            var expr = field.expr();
            if (expr == null) {
                continue;
            }
            scanForUntyped(expr);
        }
    }

    static function scanForUntyped(expr: TypedExpr): Void {
        switch (expr.expr) {
            case TUntyped(_):
                Context.error(
                    "Strict mode forbids `untyped` in application code (including `untyped __elixir__()` injections). " +
                    "Prefer typed wrappers or move target-specific code into `std/`.",
                    expr.pos
                );
            case _:
        }

        TypedExprTools.iter(expr, scanForUntyped);
    }

    static function isStrictProjectSource(pos: haxe.macro.Expr.Position, projectRoot: String): Bool {
        var root = ensureTrailingSlash(projectRoot);
        var file = normalizePath(Context.getPosInfos(pos).file);
        if (file == null || file == "") {
            return false;
        }

        if (!Path.isAbsolute(file)) {
            file = normalizePath(Path.join([root, file]));
        }

        if (!StringTools.startsWith(file, root)) {
            return false;
        }

        // Exclude compiler/framework sources when developing this repository.
        // In consumer projects, these directories typically don't exist under the app root,
        // so the check is effectively a no-op.
        if (file.indexOf("/src/reflaxe/") != -1 || file.indexOf("/std/") != -1) {
            return false;
        }

        return true;
    }

    static function ensureTrailingSlash(path: String): String {
        var normalized = normalizePath(path);
        return StringTools.endsWith(normalized, "/") ? normalized : normalized + "/";
    }

    static function normalizePath(path: String): String {
        return Path.normalize(path).split("\\").join("/");
    }

    static function isElixirBuild(): Bool {
        var targetName = Context.definedValue("target.name");
        return targetName == "elixir" || Context.defined("elixir_output");
    }
}
#end
