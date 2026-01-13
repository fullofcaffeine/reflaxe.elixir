package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * NativeModulePreserver
 *
 * WHAT
 * - Preserves annotation-only `@:native("Some.Elixir.Module")` classes from being eliminated by Haxe DCE.
 *
 * WHY
 * - In Phoenix/Elixir projects, some modules must exist at runtime even if they have no Haxe-visible
 *   references (e.g., modules referenced by config, supervision trees, or framework conventions).
 * - With `-dce full`, Haxe can remove an empty class even if it is intended to emit an Elixir module,
 *   causing runtime errors like “The module X does not exist”.
 *
 * HOW
 * - Registers a global build macro in `CompilerInit.Start()` via `Compiler.addGlobalMetadata`.
 * - When a class is built, if it:
 *   - has `@:native(<string>)` where the native name looks like an Elixir module (`contains(".")`),
 *   - is not `extern`,
 *   - declares no fields/statics (annotation-only),
 *   then we:
 *   - call `Compiler.keep(<typePath>)` to ensure it participates in generation,
 *   - add `@:keep` and `@:used` so it survives DCE.
 *
 * EXAMPLES
 * Haxe:
 *   @:native("MyAppWeb.Presence")
 *   class Presence {}
 *
 * Elixir:
 *   defmodule MyAppWeb.Presence do
 *   end
 */
class NativeModulePreserver {
    public static function init(): Void {
        try {
            Compiler.addGlobalMetadata("", "@:build(reflaxe.elixir.macros.NativeModulePreserver.ensureKept())");
        } catch (_: haxe.Exception) {}
    }

    public static function ensureKept(): Null<Array<Field>> {
        #if eval
        final classRef = Context.getLocalClass();
        if (classRef == null) return null;

        final cls = classRef.get();
        if (cls.isExtern) return null;
        if (cls.meta == null || !cls.meta.has(":native")) return null;

        final nativeName = extractNativeName(cls.meta);
        if (nativeName == null || nativeName.indexOf(".") == -1) return null;

        final fields = Context.getBuildFields();
        if (fields.length > 0) return null;

        final typePath = (cls.pack.length > 0) ? (cls.pack.join(".") + "." + cls.name) : cls.name;
        Compiler.keep(typePath);

        if (!cls.meta.has(":keep")) cls.meta.add(":keep", [], cls.pos);
        if (!cls.meta.has(":used")) cls.meta.add(":used", [], cls.pos);
        #end
        return null;
    }

    static function extractNativeName(meta: haxe.macro.Type.MetaAccess): Null<String> {
        final entries = meta.extract(":native");
        if (entries == null || entries.length == 0) return null;
        if (entries[0].params == null || entries[0].params.length == 0) return null;

        return switch (entries[0].params[0].expr) {
            case EConst(CString(value, _)):
                value;
            default:
                null;
        }
    }
}

#end

