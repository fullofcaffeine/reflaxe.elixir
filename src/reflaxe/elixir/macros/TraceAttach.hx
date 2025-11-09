package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
#end

/**
 * TraceAttach
 *
 * WHAT
 * - Globally attaches `@:build(TracePreserve.build)` before typing (Haxe 5+) so
 *   short-form `trace(v)` calls can be rewritten to `Log.trace(v, infos)` in the
 *   macro phase for the Elixir target only.
 *
 * WHY
 * - Presence and logging snapshots expect `Log.trace/2` with file/line metadata.
 *   Haxe's `-D no_traces` strips `trace` too early in some configurations; attaching a
 *   build macro pre-typing ensures we can preserve intent deterministically.
 *
 * HOW
 * - On Haxe 5+: register via `Context.onBeforeTyping` to guarantee timing.
 * - On Haxe 4.x: attach immediately as a best-effort fallback.
 * - Guarded by target check: only for Elixir (`target.name == "elixir"` or `-D elixir_output`).
 *
 * EXAMPLES
 * Haxe:
 *   trace(user)
 * Elixir (after TracePreserve):
 *   Log.trace(user, %{file_name: ..., line_number: ..., class_name: ..., method_name: ...})
 */
class TraceAttach {
  public static macro function attach() {
    #if (macro)
    final isElixir = Context.definedValue("target.name") == "elixir" || Context.defined("elixir_output");
    if (!isElixir) return macro null;

    #if (haxe >= version("5.0.0"))
    Context.onBeforeTyping(function() {
      addAttach();
    });
    #else
    addAttach();
    #end

    return macro null;
    #else
    return null;
    #end
  }

  #if (macro)
  static function addAttach() {
    try {
      Compiler.addGlobalMetadata("", "@:build(reflaxe.elixir.macros.TracePreserve.build)");
    } catch (e:Dynamic) {}
  }
  #end
}
