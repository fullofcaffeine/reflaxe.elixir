package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * AnnotatedModuleEnumerator
 *
 * WHAT
 * - Global build macro that marks framework-annotated modules (`@:repo`, `@:presence`, `@:endpoint`, etc.)
 *   as `@:keep` so Haxe DCE cannot eliminate them when they are referenced only indirectly at runtime.
 *
 * WHY
 * - Phoenix/Ecto/OTP modules are frequently referenced by strings or generated macros (supervision trees,
 *   `use AppWeb, ...`, etc.). From Haxe’s point of view, these modules can look unused and be removed by DCE,
 *   causing runtime failures like “module X was given as a child to a supervisor but it does not exist”.
 *
 * HOW
 * - Attached via `Compiler.addGlobalMetadata("", "@:build(...)")` in `CompilerInit.Start()`.
 * - For each built class, if it carries any of the supported framework annotations, add `@:keep` (and `@:used`)
 *   to preserve the type through DCE so it reaches the Elixir AST pipeline.
 *
 * EXAMPLES
 * Haxe:
 *   @:native("MyAppWeb.Presence")
 *   @:presence
 *   class Presence implements PresenceBehavior {}
 *
 * Elixir:
 *   defmodule MyAppWeb.Presence do
 *     use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
 *   end
 */
class AnnotatedModuleEnumerator {
    static final keepMetas: Array<String> = [
        ":repo",
        ":presence",
        ":endpoint",
        ":router",
        ":phoenixWeb",
        ":phoenixWebModule",
        ":component",
        ":controller",
        ":channel",
        ":socket",
        ":liveview",
        ":application",
        ":supervisor"
    ];

    public static function ensureKept(): Null<Array<Field>> {
        #if eval
        final clsRef = Context.getLocalClass();
        if (clsRef == null) return null;

        final cls = clsRef.get();
        final meta = cls.meta;
        if (meta == null) return null;

        var shouldKeep = false;
        for (metaName in keepMetas) {
            if (meta.has(metaName)) {
                shouldKeep = true;
                break;
            }
        }

        if (!shouldKeep) return null;

        #if debug_annotated_module_enumerator
        trace('[AnnotatedModuleEnumerator] keep ' + ((cls.pack.length > 0) ? (cls.pack.join(".") + "." + cls.name) : cls.name));
        #end

        if (!meta.has(":keep")) meta.add(":keep", [], cls.pos);
        if (!meta.has(":used")) meta.add(":used", [], cls.pos);
        #end
        return null;
    }
}

#end
