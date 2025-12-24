package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;

/**
 * BoundaryEnforcer
 *
 * WHAT
 * - Enforces "no escape hatches in apps" for this repository's example applications.
 * - Fails compilation if example app sources use `__elixir__()` injections or define ad-hoc extern classes.
 *
 * WHY
 * - Example apps are the public reference for "Haxe -> idiomatic Elixir" and must not rely on
 *   raw Elixir injections or Elixir-authored modules hidden behind app-level externs.
 * - Keeping the examples pure forces missing framework surfaces into `std/` (Phoenix/Ecto/etc.),
 *   where they are reusable and documented.
 *
 * HOW
 * - Registers a `Context.onAfterTyping` hook during Elixir builds.
 * - Scans types whose source file lives under `examples/<app>/src_haxe/**` for:
 *   1) Calls to the target code injection function (`__elixir__`)
 *   2) `extern class` declarations without compiler-recognized framework annotations (e.g. `@:repo`)
 *
 * EXAMPLES
 * Disallowed (example app code):
 *   var now = untyped __elixir__("DateTime.utc_now()");
 *
 * Allowed (framework/stdlib code):
 *   // `std/*.cross.hx` may use `untyped __elixir__()` for native stdlib implementations.
 *
 * Allowed (example app boundary module):
 *   @:repo extern class Repo {}
 */
class BoundaryEnforcer {
    public static function init(): Void {
        if (!isElixirBuild()) {
            return;
        }

        // This enforcement is a repository policy for our shipped examples, not a compiler restriction.
        // Users can opt into the same guard in their own projects by defining:
        //   -D reflaxe_elixir_strict_examples
        if (!Context.defined("reflaxe_elixir_strict_examples")) {
            return;
        }

        Context.onAfterTyping(enforceExampleBoundaries);
    }

    static function enforceExampleBoundaries(types: Array<ModuleType>): Void {
        for (moduleType in types) {
            switch (moduleType) {
                case TClassDecl(classRef):
                    var classType = classRef.get();
                    if (!isExampleAppSource(classType.pos)) {
                        continue;
                    }

                    enforceExternClassRules(classType);
                    enforceNoElixirInjectionInClass(classType);

                case _:
            }
        }
    }

    static function enforceExternClassRules(classType: ClassType): Void {
        if (!classType.isExtern) {
            return;
        }

        if (isAllowedExampleExtern(classType)) {
            return;
        }

        Context.error(
            "Extern classes are not allowed in example app sources. " +
            "Move the extern to framework-level `std/` (Phoenix/Ecto/etc.), or use an annotation-driven boundary " +
            "module (e.g. `@:repo`) that the compiler can generate.",
            classType.pos
        );
    }

    static function enforceNoElixirInjectionInClass(classType: ClassType): Void {
        var allFields = classType.fields.get().concat(classType.statics.get());
        for (field in allFields) {
            var expr = field.expr();
            if (expr == null) {
                continue;
            }

            scanForElixirInjection(expr);
        }
    }

    static function scanForElixirInjection(expr: TypedExpr): Void {
        if (isElixirInjectionCall(expr)) {
            Context.error(
                "`__elixir__()` code injection is disallowed in example app sources. " +
                "Implement the feature in Haxe (preferred) or add a reusable framework wrapper in `std/`.",
                expr.pos
            );
        }

        TypedExprTools.iter(expr, scanForElixirInjection);
    }

    static function isElixirInjectionCall(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TCall(callTarget, _):
                switch (callTarget.expr) {
                    case TIdent(name):
                        name == "__elixir__";
                    case TLocal(variable):
                        variable.name == "__elixir__";
                    case TField(_, fieldAccess):
                        switch (fieldAccess) {
                            case FInstance(_, _, classField) | FStatic(_, classField) | FAnon(classField) | FClosure(_, classField):
                                classField.get().name == "__elixir__";
                            case FEnum(_, enumField):
                                enumField.name == "__elixir__";
                            case FDynamic(name):
                                name == "__elixir__";
                        }
                    case _:
                        false;
                }
            case _:
                false;
        }
    }

    static function isAllowedExampleExtern(classType: ClassType): Bool {
        return classType.meta.has(":repo") ||
            classType.meta.has(":dbTypes") ||
            classType.meta.has(":postgrexTypes") ||
            classType.meta.has(":gettext");
    }

    static function isExampleAppSource(pos: haxe.macro.Expr.Position): Bool {
        var file = Context.getPosInfos(pos).file;
        var normalized = normalizePath(file);
        return normalized.indexOf("examples/") != -1 && normalized.indexOf("/src_haxe/") != -1;
    }

    static function normalizePath(path: String): String {
        return path.split("\\").join("/");
    }

    static function isElixirBuild(): Bool {
        var targetName = Context.definedValue("target.name");
        return targetName == "elixir" || Context.defined("elixir_output");
    }
}
#end
