package reflaxe.elixir;

#if macro
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import StringTools;
import sys.FileSystem;
import sys.io.File;

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
 *   - `std/elixir/_std/` (source-layout Haxe stdlib overrides)
 *   - `std/` (Phoenix/Ecto/etc externs + target-owned support APIs)
 *   - `vendor/reflaxe/src` (vendored Reflaxe framework)
 *   - `vendor/phoenix_shared/src` (shared Phoenix channel/LiveEvent protocol types)
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
	static var bootstrapped:Bool = false;

	static function argsContainDefine(args:Array<String>, defineName:String):Bool {
		var i = 0;
		while (i < args.length) {
			var arg = args[i];
			if (arg == "-D" || arg == "--define") {
				if (i + 1 < args.length) {
					var defineArg = args[i + 1];
					if (defineArg == defineName || StringTools.startsWith(defineArg, defineName + "="))
						return true;
				}
				i += 2;
				continue;
			}

			if (StringTools.startsWith(arg, "-D" + defineName))
				return true;
			i += 1;
		}

		return false;
	}

	static function hxmlContainsDefine(hxmlPath:String, defineName:String, seen:Map<String, Bool>):Bool {
		var normalizedPath = Path.normalize(hxmlPath);
		if (seen.exists(normalizedPath))
			return false;
		seen.set(normalizedPath, true);

		if (!FileSystem.exists(normalizedPath))
			return false;

		var content = File.getContent(normalizedPath);
		var args:Array<String> = [];
		for (line in content.split("\n")) {
			var raw = StringTools.trim(line);
			if (raw.length == 0)
				continue;
			if (StringTools.startsWith(raw, "#"))
				continue;

			var commentIndex = raw.indexOf("#");
			if (commentIndex >= 0)
				raw = StringTools.trim(raw.substr(0, commentIndex));
			if (raw.length == 0)
				continue;

			for (token in raw.split(" ")) {
				var t = StringTools.trim(token);
				if (t.length > 0)
					args.push(t);
			}
		}

		if (argsContainDefine(args, defineName))
			return true;

		// Handle nested hxml includes (e.g. `@other.hxml`) if present.
		for (arg in args) {
			if (StringTools.startsWith(arg, "@")) {
				var nested = arg.substr(1);
				if (hxmlContainsDefine(nested, defineName, seen))
					return true;
			}
		}

		return false;
	}

	static function existingClassPaths(paths:Array<String>):Array<String> {
		if (paths == null || paths.length == 0)
			return [];

		var existing:Array<String> = [];
		for (p in paths) {
			if (p != null && p.length > 0 && FileSystem.exists(p))
				existing.push(p);
		}
		return existing;
	}

	static function injectClassPathsFirst(paths:Array<String>):Void {
		paths = existingClassPaths(paths);
		if (paths.length == 0)
			return;

		var config = Compiler.getConfiguration();
		if (config == null) {
			for (p in paths)
				Compiler.addClassPath(p);
			return;
		}

		var classPathField = "classPath";
		var existingDynamic:Dynamic = null;
		if (Reflect.hasField(config, "classPath")) {
			existingDynamic = Reflect.field(config, "classPath");
		} else if (Reflect.hasField(config, "classPaths")) {
			classPathField = "classPaths";
			existingDynamic = Reflect.field(config, "classPaths");
		}

		if (existingDynamic == null || !Std.isOfType(existingDynamic, Array)) {
			// Fall back to append behavior if we can't introspect/replace the classpath list.
			for (p in paths)
				Compiler.addClassPath(p);
			return;
		}

		// Ensure our overrides win by putting them at the *front* of the classpath list.
		//
		// `Compiler.addClassPath` appends, which is too late to shadow the built-in stdlib paths.
		// That can cause CI-only drift under WAE where canonical stdlib modules (e.g. `haxe.ds.*`)
		// are compiled to Elixir and emit warnings.
		var existing:Array<String> = cast existingDynamic;
		var normalized = new Map<String, Bool>();
		var keep:Array<String> = [];

		for (p in paths)
			normalized.set(Path.normalize(p), true);
		for (p in existing) {
			if (!normalized.exists(Path.normalize(p)))
				keep.push(p);
		}

		Reflect.setField(config, classPathField, paths.concat(keep));
	}

	static function hasDefineInArgs(defineName:String):Bool {
		var config = Compiler.getConfiguration();
		if (config == null)
			return false;

		var args = config.args;
		if (argsContainDefine(args, defineName))
			return true;

		// In some invocations (notably `haxe build.hxml`), `config.args` may contain only the
		// hxml file path at macro time, *before* its `-D ...` lines are expanded into args.
		// Parse the referenced hxml files directly so bootstrap gating remains deterministic.
		var seen = new Map<String, Bool>();
		for (arg in args) {
			if (StringTools.endsWith(arg, ".hxml") && hxmlContainsDefine(arg, defineName, seen))
				return true;
			if (StringTools.startsWith(arg, "@")) {
				var nested = arg.substr(1);
				if (hxmlContainsDefine(nested, defineName, seen))
					return true;
			}
		}

		return false;
	}

	static function isElixirBuild():Bool {
		var targetName = Context.definedValue("target.name");
		if (targetName == "elixir")
			return true;
		if (Context.defined("elixir_output"))
			return true;

		// Haxe 4 Reflaxe targets compile under the `cross` platform. This is available
		// early (before downstream `-D elixir_output=...` defines may be observed by
		// macros invoked from a `-lib` hxml file).
		var config = Compiler.getConfiguration();
		if (config != null) {
			switch (config.platform) {
				case Cross:
					return true;
				#if (haxe >= version("5.0.0"))
				case CustomTarget("elixir"):
					return true;
				#end
				case _:
			}
		}

		// Haxe 4: Elixir builds are typically `cross` and identified via `-D elixir_output=...`.
		return hasDefineInArgs("elixir_output");
	}

	public static function Start() {
		if (bootstrapped)
			return;
		bootstrapped = true;

		var shouldInjectStd = isElixirBuild();

		try {
			var bootstrapPath = Context.resolvePath("reflaxe/elixir/CompilerBootstrap.hx");
			var elixirDir = Path.directory(bootstrapPath); // .../src/reflaxe/elixir
			var reflaxeDir = Path.directory(elixirDir); // .../src/reflaxe
			var srcDir = Path.directory(reflaxeDir); // .../src
			var libraryRoot = Path.directory(srcDir); // .../

			var vendoredReflaxe = Path.normalize(Path.join([libraryRoot, "vendor", "reflaxe", "src"]));
			var vendoredPhoenixShared = Path.normalize(Path.join([libraryRoot, "vendor", "phoenix_shared", "src"]));
			if (FileSystem.exists(vendoredPhoenixShared))
				Compiler.define("phoenix_shared", "0.1.0");

			if (!shouldInjectStd) {
				injectClassPathsFirst([vendoredReflaxe, vendoredPhoenixShared]);
				return;
			}

			// Inject source-layout `_std` overrides before `std/` so upstream-colliding Haxe
			// modules win over the canonical stdlib before `CompilerInit` and other macro
			// modules are typed. Reflaxe package builds later flatten this `_std` root into
			// packaged `.cross.hx` files.
			var targetStdOverrides = Path.normalize(Path.join([libraryRoot, "std", "elixir", "_std"]));
			var standardLibrary = Path.normalize(Path.join([libraryRoot, "std"]));
			injectClassPathsFirst([targetStdOverrides, standardLibrary, vendoredReflaxe, vendoredPhoenixShared]);
		} catch (e:haxe.Exception) {
			// If resolvePath fails in certain contexts, skip silently (non-Elixir targets)
		}
	}
}
#end
