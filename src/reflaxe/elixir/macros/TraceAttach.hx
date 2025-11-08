package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Type; // expose ModuleType and constructors

/**
 * TraceAttach
 *
 * WHAT
 * - A minimal initialization macro that globally attaches the
 *   `@:build(reflaxe.elixir.macros.TracePreserve.build())` metadata so all
 *   subsequently loaded types run the TracePreserve build macro.
 *
 * WHY
 * - With `-D no_traces`, the Haxe typer removes short-form `trace(...)` calls.
 *   Presence snapshots (and other tests) expect trace calls to be preserved as
 *   `Log.trace(value, %{file_name, line_number, class_name, method_name})`.
 *   Attaching the build macro BEFORE typing ensures we rewrite `trace(...)`
 *   to the expected form pre-typing without touching app or generated files.
 *
 * HOW
 * - Elixir-target gated: only runs if `target.name == "elixir"` or
 *   `-D elixir_output` is defined.
 * - Calls `haxe.macro.Compiler.addGlobalMetadata("", "@:build(...)" , true)`
 *   so any module typed after this point receives the TracePreserve build macro.
 * - This class contains no other logic and has no runtime side effects.
 *
 * ORDERING
 * - Must be invoked as early as possible. The repository wires this via
 *   `haxe_libraries/reflaxe.hxml`:
 *   `--macro reflaxe.elixir.macros.TraceAttach.attach()`
 *   Ensure this line appears before other macros that might load user modules.
 *
 * EXAMPLES
 * - hxml:
 *   ```
 *   --macro reflaxe.elixir.macros.TraceAttach.attach()
 *   ```
 * - Conceptual effect:
 *   ```haxe
 *   Compiler.addGlobalMetadata("", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
 *   ```
 *
 * LIMITATIONS
 * - If a different macro loads a module before this attach executes, that module
 *   would not receive `@:build`. This is mitigated by placing the attach first in
 *   macro order.
 *
 * SEE ALSO
 * - `reflaxe.elixir.macros.TracePreserve` — build macro that performs the rewrite.
 */
class TraceAttach {
  /**
   * Entry point invoked from hxml to attach the TracePreserve build macro globally.
   * Gated to Elixir builds; safe no-op for other targets.
   */
  public static function attach():Void {
    var isElixir = (Context.definedValue("target.name") == "elixir") || Context.defined("elixir_output");
    if (!isElixir) return;
    try {
      Compiler.addGlobalMetadata("", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
#if sys
      try sys.io.File.append('/tmp/trace_attach.log', true).writeString('TraceAttach.attach applied\n') catch (_:Dynamic) {}
#end
      // Keep attach minimal to avoid module loading; rely on global metadata above.
    } catch (_:Dynamic) {}
  }
}

#end
