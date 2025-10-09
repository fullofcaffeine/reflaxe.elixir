package reflaxe.elixir;

#if macro

import haxe.macro.Context;
import haxe.macro.Compiler;
import reflaxe.ReflectCompiler;
import reflaxe.elixir.ElixirCompiler;

/**
 * CompilerInit: Bootstrap macro for target-conditional setup.
 *
 * - Adds Elixir-specific staged std overrides (`std/_std/`) ONLY when compiling for Elixir.
 * - Initializes LiveView preservation to guard against DCE removing Phoenix callbacks.
 */
class CompilerInit {
    public static function Start(): Void {
        // Determine if we are compiling for the Elixir target.
        // Prefer explicit define set by our hxml (`-D reflaxe.elixir=...`).
        var isElixirTarget = Context.defined("reflaxe.elixir")
            || (Context.defined("target.name") && Context.definedValue("target.name").toLowerCase() == "elixir")
            || Context.defined("target.elixir")
            // Heuristic for snapshot/tests: if an elixir_output define is provided, we are driving the Elixir compiler
            || Context.defined("elixir_output");

        if (isElixirTarget) {
            // Conditionally add staged .cross.hx overrides to the classpath.
            // Use a relative path; build environments already add `${SCOPE_DIR}/std`.
            Compiler.addClassPath("std/_std/");

            // Initialize LiveView method preservation to prevent DCE issues.
            try {
                reflaxe.elixir.macros.LiveViewPreserver.init();
            } catch (e:Dynamic) {
                // Non-fatal; continue compilation if preservation macro is unavailable.
            }

            // Register the Elixir compiler with ReflectCompiler using deterministic
            // file output settings for snapshots/examples. This is Elixir-target only.
            // - FilePerModule: one .ex per Haxe module
            // - fileOutputExtension: .ex
            // - outputDirDefineName: elixir_output (provided via -D elixir_output=out)
            // ElixirCompiler constructor configures file output options.
            ReflectCompiler.AddCompiler(new ElixirCompiler());

            // CRITICAL: Start the ReflectCompiler lifecycle to install onAfterTyping/onAfterGenerate
            // hooks and actually drive file generation. Without this, AddCompiler only registers
            // the compiler but no output is produced. This aligns with snapshot harness expectations
            // that simply adding our Start() macro is sufficient to produce files in `-D elixir_output`.
            // Start once; ignore duplicate-start errors from other macros/targets
            try {
                ReflectCompiler.Start();
            } catch (e:Dynamic) {
                var msg = Std.string(e);
                if (msg == null || msg.indexOf("called multiple times") < 0) {
                    throw e;
                }
            }
        }
    }
}

#end
