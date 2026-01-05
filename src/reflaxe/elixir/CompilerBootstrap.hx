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
 * - The compiler relies on a patched vendored Reflaxe framework under `vendor/reflaxe/` for
 *   critical filesystem fixes; consumer installs must see those sources without requiring a
 *   separate `-lib reflaxe` dependency.
 *
 * HOW
 * - Invoked first from `extraParams.hxml`.
 * - If the current compilation appears to be an Elixir build (`-D elixir_output` or custom target),
 *   compute the library root from this file’s resolved path and add:
 *   - `std/` + `std/_std` (Phoenix/Ecto/etc externs + staged overrides)
 *   - `vendor/reflaxe/src` (vendored Reflaxe framework)
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

		// For Haxe 4 builds, `target.name` may be unset; `-D elixir_output=...` is the stable signal
		// for this target. We still inject vendored Reflaxe unconditionally so `CompilerInit` can type
		// even in non-Elixir contexts where the library may be present.
		var targetName = Context.definedValue("target.name");
		var isElixirBuild = (targetName == "elixir" || Context.defined("elixir_output"));

		try {
			var bootstrapPath = Context.resolvePath("reflaxe/elixir/CompilerBootstrap.hx");
			var elixirDir = Path.directory(bootstrapPath); // .../src/reflaxe/elixir
			var reflaxeDir = Path.directory(elixirDir);     // .../src/reflaxe
			var srcDir = Path.directory(reflaxeDir);        // .../src
			var libraryRoot = Path.directory(srcDir);       // .../

			var vendoredReflaxe = Path.normalize(Path.join([libraryRoot, "vendor", "reflaxe", "src"]));

			Compiler.addClassPath(vendoredReflaxe);

			if (!isElixirBuild) {
				return;
			}

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
