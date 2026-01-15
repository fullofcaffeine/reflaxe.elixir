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
        ":phxHookNames",
        ":phxEventNames",
        ":application",
        ":supervisor",
        ":genserver"
    ];

    public static function ensureKept(): Null<Array<Field>> {
        #if eval
        final clsRef = Context.getLocalClass();
        if (clsRef == null) return null;

        final cls = clsRef.get();
        final meta = cls.meta;
        if (meta == null) return null;

        final fields = Context.getBuildFields();
        final isSchema = meta.has(":schema");

        if (isSchema) {
            for (field in fields) {
                if (isSchemaField(field)) ensureSchemaFieldKept(field);
            }
        }

        var shouldKeepModule = false;
        for (metaName in keepMetas) {
            if (meta.has(metaName)) {
                shouldKeepModule = true;
                break;
            }
        }

        if (!isSchema && !shouldKeepModule) return null;

        #if debug_annotated_module_enumerator
        trace('[AnnotatedModuleEnumerator] keep ' + ((cls.pack.length > 0) ? (cls.pack.join(".") + "." + cls.name) : cls.name));
        #end

        if (!shouldKeepModule) return fields;

        final keepAllPublicStatic = meta.has(":controller")
            || meta.has(":channel")
            || meta.has(":socket")
            || meta.has(":router")
            || meta.has(":endpoint")
            || meta.has(":phoenixWeb")
            || meta.has(":phoenixWebModule");

        final keepOnlyComponentFunctions = meta.has(":component");
        final keepNames = buildKeepNameSet(meta);

        for (field in fields) {
            if (keepAllPublicStatic) {
                ensureFieldKept(field);
                continue;
            }
            if (keepOnlyComponentFunctions) {
                if (fieldMetaHas(field.meta, ":component")) ensureFieldKept(field);
                continue;
            }
            if (keepNames.exists(field.name)) ensureFieldKept(field);
        }

        if (!meta.has(":keep")) meta.add(":keep", [], cls.pos);
        if (!meta.has(":used")) meta.add(":used", [], cls.pos);
        return fields;
        #end
        return null;
    }

    static function ensureFieldKept(field: Field): Void {
        if (!isPublicStatic(field)) return;
        if (field.meta == null) field.meta = [];
        if (!fieldMetaHas(field.meta, ":keep")) {
            field.meta.push({ name: ":keep", params: [], pos: field.pos });
        }
    }

    static function ensureSchemaFieldKept(field: Field): Void {
        if (field.access != null) {
            for (a in field.access) {
                if (a == APrivate) return;
            }
        }
        if (field.meta == null) field.meta = [];
        if (!fieldMetaHas(field.meta, ":keep")) {
            field.meta.push({ name: ":keep", params: [], pos: field.pos });
        }
    }

    static function isSchemaField(field: Field): Bool {
        return switch (field.kind) {
            case FVar(_, _) | FProp(_, _, _, _):
                fieldMetaHas(field.meta, ":field")
                    || fieldMetaHas(field.meta, ":virtual")
                    || fieldMetaHas(field.meta, ":belongs_to")
                    || fieldMetaHas(field.meta, ":has_many")
                    || fieldMetaHas(field.meta, ":has_one")
                    || fieldMetaHas(field.meta, ":many_to_many");
            default:
                false;
        }
    }

    static function isPublicStatic(field: Field): Bool {
        if (field.access == null) return false;
        var isStatic = false;
        for (a in field.access) {
            if (a == AStatic) isStatic = true;
            if (a == APrivate) return false;
        }
        return isStatic;
    }

    static function fieldMetaHas(meta: Null<Array<MetadataEntry>>, metaName: String): Bool {
        if (meta == null) return false;
        for (m in meta) {
            if (m.name == metaName) return true;
        }
        return false;
    }

    static function buildKeepNameSet(classMeta: haxe.macro.Type.MetaAccess): Map<String, Bool> {
        final names: Map<String, Bool> = new Map();

        if (classMeta.has(":application")) {
            names.set("start", true);
            names.set("stop", true);
            names.set("prep_stop", true);
            names.set("prepStop", true);
            names.set("config_change", true);
            names.set("configChange", true);
        }

        if (classMeta.has(":supervisor")) {
            names.set("child_spec", true);
            names.set("childSpec", true);
            names.set("start_link", true);
            names.set("startLink", true);
            names.set("init", true);
        }

        if (classMeta.has(":genserver")) {
            names.set("child_spec", true);
            names.set("childSpec", true);
            names.set("start_link", true);
            names.set("startLink", true);
            names.set("init", true);
            names.set("handle_call", true);
            names.set("handleCall", true);
            names.set("handle_cast", true);
            names.set("handleCast", true);
            names.set("handle_info", true);
            names.set("handleInfo", true);
            names.set("handle_continue", true);
            names.set("handleContinue", true);
            names.set("terminate", true);
            names.set("code_change", true);
            names.set("codeChange", true);
        }

        if (classMeta.has(":liveview")) {
            names.set("mount", true);
            names.set("render", true);
            names.set("handle_event", true);
            names.set("handleEvent", true);
            names.set("handle_info", true);
            names.set("handleInfo", true);
            names.set("handle_params", true);
            names.set("handleParams", true);
            names.set("terminate", true);
        }

        return names;
    }
}

#end
