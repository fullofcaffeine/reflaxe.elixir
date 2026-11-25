package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Type;
import reflaxe.ReflectCompiler;

/**
 * Keeps the set of types that a build can generate fixed before Haxe finishes
 * typing, so that a warm compilation-server request builds the same modules
 * as a fresh build.
 *
 * THE PROBLEM
 * - When code asks Haxe for a type by name (`Context.getType`,
 *   `Context.getModule`), Haxe records that the "current module" depends on
 *   the module of that type. After typing, the current module of these
 *   requests is not a module that asked for anything: Haxe's expression
 *   filters leave it set to the last class that they processed. In a small
 *   probe this is `reflaxe.elixir.runtime.HaxeThrow`; in an application it
 *   can be any class.
 * - A compilation server keeps that dependency. In the next request, Haxe
 *   reuses the "current module" and also loads every module that it depends
 *   on, so a module that was first typed during generation is now part of
 *   the typed program. A fresh build never types it before generation.
 * - Example: a template with `<.form :let={f}>` made the linter ask for
 *   `phoenix.Phoenix.Form`. The second warm request then built 19 classes
 *   instead of 14 and wrote `phoenix/*.ex` and `ecto/*.ex` files that a fresh
 *   build never writes. Each later request typed more, until 26 classes.
 *
 * THE RULE
 * - Code that runs during generation reads types only from the typed program
 *   (`findType`). It never asks Haxe to load or resolve a module.
 * - A module that generation needs but the program may not use is loaded in
 *   Haxe's after-typing step (`registerRuntimeSupportLoad`), the same way in
 *   every request. There, Haxe has no current module, so it records no
 *   dependency on an unrelated module. Haxe types such a module completely
 *   before dead-code elimination, as it does for a module that the program
 *   uses.
 * - A module that only this load added ("runtime support only") is not
 *   generated, except `StringTools` when generated code needs its helpers.
 *
 * WHAT IT LOADS
 * - `StringTools`, whose helpers generated code calls, when the program does
 *   not use it.
 * - `phoenix.Phoenix`, when the program has a template (it types `HXX`) and
 *   does not use `phoenix.Phoenix`. The template linter reads the `Form` and
 *   `FormField` types from it to check `<.form :let={f}>` and
 *   `<.inputs_for :let={f}>` values.
 *
 * LIMITS
 * - Other generation-time lookups by name remain (router and controller
 *   metadata, discovered hook and tag registries, component props by type
 *   name). They usually ask for modules that the program already typed; a
 *   lookup of such a module still records a dependency that can keep the
 *   module in a later warm request after the last program reference is
 *   removed. Move them to `findType` before relying on them in that case.
 */
class TypingPhaseTypes {
	/** True after the after-typing callback ran once in this request. **/
	static var supportLoadChecked = false;

	/** True when this request asked Haxe for a runtime-support module. **/
	static var supportLoadStarted = false;

	/**
	 * The `ReflectCompiler.typeKey` of each type that only the runtime-support
	 * load made Haxe type in this request, or null when it added none.
	 */
	static var supportOnlyTypeKeys:Null<Map<String, Bool>> = null;

	/**
	 * The types of the typed program by dotted path, set when generation
	 * starts, or null before that. Statics are not persistent, so each request
	 * starts with null.
	 */
	static var typedTypesByPath:Null<Map<String, ModuleType>> = null;

	/**
	 * Registers the after-typing callback that loads the runtime-support
	 * modules (see WHAT IT LOADS) that the typed program does not contain.
	 *
	 * Why it loads `StringTools` for every program instead of only for a
	 * program that needs it: the need is known only after dead-code
	 * elimination (`ElixirCompiler.filterTypes`), which comes after typing.
	 * Loading it always costs one cached module on a warm request, and the
	 * module is generated only when generated code calls its helpers.
	 */
	public static function registerRuntimeSupportLoad():Void {
		reflaxe.elixir.debug.CompilerPhaseTimings.onAfterTyping("runtime_support_load", loadRuntimeSupport);
	}

	static function loadRuntimeSupport(types:Array<ModuleType>):Void {
		// Haxe calls each after-typing callback once with the whole typed
		// program, and again with only the types that the callbacks of the
		// previous call made Haxe type. No other callback of this compiler
		// loads a type there (before this load, Reflaxe kept only the last
		// call's types and would have built almost nothing), so every type of
		// a later call comes from this load.
		if (supportLoadChecked) {
			if (!supportLoadStarted)
				return;
			final keys = supportOnlyTypeKeys != null ? supportOnlyTypeKeys : new Map<String, Bool>();
			for (moduleType in types)
				keys.set(ReflectCompiler.typeKey(commonData(moduleType)), true);
			supportOnlyTypeKeys = keys;
			return;
		}
		supportLoadChecked = true;
		// Migration-only builds generate only `@:migration` classes.
		if (Context.defined("ecto_migrations_exs"))
			return;
		var hasStringTools = false;
		var hasTemplates = false;
		var hasPhoenix = false;
		for (moduleType in types) {
			final type = commonData(moduleType);
			if (isStringTools(moduleType))
				hasStringTools = true;
			else if (type.module == "HXX")
				hasTemplates = true;
			else if (type.module == "phoenix.Phoenix")
				hasPhoenix = true;
		}
		final paths = [];
		if (!hasStringTools)
			paths.push("StringTools");
		if (hasTemplates && !hasPhoenix)
			paths.push("phoenix.Phoenix");
		for (path in paths) {
			supportLoadStarted = true;
			try {
				Context.getModule(path);
			} catch (_:haxe.Exception) {}
		}
	}

	/**
	 * Returns true when only the runtime-support load made Haxe type this
	 * type: no module of the typed program uses it.
	 */
	public static function isRuntimeSupportOnly(moduleType:ModuleType):Bool {
		final keys = supportOnlyTypeKeys;
		return keys != null && keys.exists(ReflectCompiler.typeKey(commonData(moduleType)));
	}

	/** Returns true for the top-level `StringTools` class. **/
	public static function isStringTools(moduleType:ModuleType):Bool {
		return switch (moduleType) {
			case TClassDecl(classRef): final classType = classRef.get(); classType.name == "StringTools" && classType.pack.length == 0;
			default:
				false;
		}
	}

	/**
	 * Remembers the typed program for `findType`. Call it once when
	 * generation starts, with every type that Haxe typed in this request.
	 */
	public static function beginGeneration(moduleTypes:Array<ModuleType>):Void {
		final byPath = new Map<String, ModuleType>();
		for (moduleType in moduleTypes) {
			final type = commonData(moduleType);
			final realPath = sourcePath(type);
			final lastDot = realPath.lastIndexOf(".");
			final name = lastDot == -1 ? realPath : realPath.substr(lastDot + 1);
			final moduleLastDot = type.module.lastIndexOf(".");
			final moduleName = moduleLastDot == -1 ? type.module : type.module.substr(moduleLastDot + 1);
			// `Context.getType` accepts `pack.Module.Type` for every type and
			// `pack.Module` for the type that has the module's name.
			if (name == moduleName)
				byPath.set(type.module, moduleType);
			byPath.set(type.module + "." + name, moduleType);
		}
		typedTypesByPath = byPath;
	}

	/**
	 * Returns the type with the dotted path `path`, like `Context.getType`,
	 * or null when there is no such type.
	 *
	 * During generation it reads only the typed program, so it never makes
	 * Haxe type a module or record a dependency; a type that the program did
	 * not type is not found. Before generation (for example from a macro that
	 * Haxe calls while it types a module) it asks Haxe, where the dependency
	 * belongs to the module that Haxe is typing.
	 *
	 * Example: `findType("phoenix.Phoenix.Form")` returns the `Form` typedef
	 * when the program uses `phoenix.Phoenix` or has a template (see
	 * `registerRuntimeSupportLoad`), and null otherwise.
	 */
	public static function findType(path:String):Null<Type> {
		final byPath = typedTypesByPath;
		if (byPath == null) {
			try {
				return Context.getType(path);
			} catch (_:haxe.Exception) {
				return null;
			}
		}
		final moduleType = byPath.get(path);
		if (moduleType == null)
			return null;
		return switch (moduleType) {
			case TClassDecl(ref): TInst(ref, [for (param in ref.get().params) param.t]);
			case TEnumDecl(ref): TEnum(ref, [for (param in ref.get().params) param.t]);
			case TTypeDecl(ref): TType(ref, [for (param in ref.get().params) param.t]);
			case TAbstract(ref): TAbstract(ref, [for (param in ref.get().params) param.t]);
		};
	}

	/** The dotted path that the Haxe source gives to the type (see `ReflectCompiler.typeKey`). **/
	static function sourcePath(type:BaseType):String {
		final realPath = type.meta.has(":realPath") ? type.meta.extract(":realPath") : [];
		if (realPath.length > 0 && realPath[0].params != null && realPath[0].params.length > 0) {
			switch (realPath[0].params[0].expr) {
				case EConst(CString(value, _)):
					return value;
				default:
			}
		}
		return type.pack.concat([type.name]).join(".");
	}

	static function commonData(moduleType:ModuleType):BaseType {
		return switch (moduleType) {
			case TClassDecl(ref): ref.get();
			case TEnumDecl(ref): ref.get();
			case TTypeDecl(ref): ref.get();
			case TAbstract(ref): ref.get();
		};
	}
}
#end
