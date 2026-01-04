package reflaxe.elixir;

#if macro

import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;

/**
 * CompilerBootstrap
 *
 * WHAT
 * - Performs the earliest possible target-conditional classpath injection for Reflaxe.Elixir.
 *
 * WHY
 * - Consumer installs rely on `extraParams.hxml` to invoke our bootstrap macros.
 * - Some compiler modules reference types under this repo’s `std/` (Phoenix/Ecto surfaces).
 * - If we wait until `CompilerInit.Start()` to inject `std/`, Haxe may type those compiler modules
 *   (via imports) *before* the injection runs, leading to missing-type failures in fresh projects.
 *
 * HOW
 * - Invoked first from `extraParams.hxml`.
 * - If the current compilation appears to be an Elixir build (`-D elixir_output` or custom target),
 *   compute the library root from this file’s resolved path and add `std/` + `std/_std` to the classpath.
 *
 * EXAMPLES
 * Haxe build.hxml:
 *   -lib reflaxe.elixir
 *   -D elixir_output=lib/my_app_hx
 *
 * `extraParams.hxml` (implicit via -lib):
 *   --macro reflaxe.elixir.CompilerBootstrap.Start()
 *   --macro reflaxe.elixir.CompilerInit.Start()
 */
class CompilerBootstrap {
	static var bootstrapped: Bool = false;

	public static function Start() {
		if (bootstrapped) return;
		bootstrapped = true;

		// Only activate when compiling to Elixir. For Haxe 4 builds, `target.name` may be unset;
		// `-D elixir_output=...` is the stable signal for this target.
		var targetName = Context.definedValue("target.name");
		if (targetName != "elixir" && !Context.defined("elixir_output")) {
			return;
		}

		try {
			var bootstrapPath = Context.resolvePath("reflaxe/elixir/CompilerBootstrap.hx");
			var elixirDir = Path.directory(bootstrapPath); // .../src/reflaxe/elixir
			var reflaxeDir = Path.directory(elixirDir);     // .../src/reflaxe
			var srcDir = Path.directory(reflaxeDir);        // .../src
			var libraryRoot = Path.directory(srcDir);       // .../

			var standardLibrary = Path.normalize(Path.join([libraryRoot, "std"]));
			var stagedStd = Path.normalize(Path.join([libraryRoot, "std/_std"]));

			Compiler.addClassPath(standardLibrary);
			Compiler.addClassPath(stagedStd);
		} catch (e: haxe.Exception) {
			// If resolvePath fails in certain contexts, skip silently (non-Elixir targets)
		}
	}
}

#end

