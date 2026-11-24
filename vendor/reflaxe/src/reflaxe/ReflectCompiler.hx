// =======================================================
// * ReflectCompiler
// =======================================================

package reflaxe;

#if (macro || reflaxe_runtime)

// avoid conflict with haxe.macro.Type after https://github.com/HaxeFoundation/haxe/pull/11168
import Type as HaxeType;

import haxe.display.Display.MetadataTarget;
import haxe.ds.ReadOnlyArray;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

#if eval
import sys.FileSystem;
import sys.io.File;
#end

import reflaxe.BaseCompiler;
import reflaxe.compiler.NullTypeEnforcer;
import reflaxe.config.Define;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;
import reflaxe.data.EnumOptionArg;
import reflaxe.data.EnumOptionData;
import reflaxe.input.ClassHierarchyTracker;
import reflaxe.input.ModuleUsageTracker;

using reflaxe.helpers.ArrayHelper;
using reflaxe.helpers.BaseTypeHelper;
using reflaxe.helpers.ClassFieldHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullableMetaAccessHelper;
using reflaxe.helpers.TypeHelper;

/**
	One part of a source file where Haxe says a class or a module-level field
	is written. `min` and `max` count characters, as Haxe positions do.
	`start` must match the text at `min`. See
	`ReflectCompiler.nonClassSourceText`.
**/
/**
	The facts of one type that `applyBuildCacheCheckFilter` reads, computed
	once per request (see `describeTypes`).
**/
private typedef DescribedType = {
	final moduleType: ModuleType;
	final data: BaseType;
	final key: String;
	final readWithoutDependency: Bool;
}

private typedef ClassSourceSpan = {
	final min: Int;
	final max: Int;
	final start: EReg;
	final endsWithBrace: Bool;
}

/**
	The heart of Reflaxe.

	This singleton implements the generation by calling
	functions at various compiler phases.
**/
class ReflectCompiler {
	// =======================================================
	// * Public Members
	// =======================================================
	public static var Compilers: Array<BaseCompiler> = [];

	public static function Start() {
		#if (haxe_ver < "4.3.0")
		Sys.println("Reflaxe requires Haxe version 4.3.0 or greater.");
		return;
		#elseif eval
		static var called = false;
		if(!called) {
			if(#if eval !Context.defined("display") #else true #end) {
				Context.onAfterTyping(onAfterTyping);
				Context.onAfterGenerate(onAfterGenerate);
				checkServerCache();
			}
			called = true;
		} else {
			throw "reflaxe.ReflectCompiler.Start() called multiple times.";
		}
		#end
	}

	public static function AddCompiler(compiler: BaseCompiler, options: Null<BaseCompilerOptions> = null) {
		if(!Compilers.contains(compiler)) {
			Compilers.push(compiler);
		}
		if(options != null) {
			compiler.setOptions(options);
		}
	}

	public static function MetaTemplate(name: String, doc: String, disallowMultiple: Bool = false, paramTypes: Null<Array<MetaArgumentType>> = null, targets: Null<Array<MetadataTarget>> = null, compileFunc: Null<(MetadataEntry, Array<String>) -> Null<String>> = null) {
		final params = if(paramTypes != null && paramTypes.length > 0) {
			paramTypes.map(function(p): String return p);
		} else {
			[];
		}

		final metaDesc: haxe.macro.Compiler.MetadataDescription = {
			metadata: name,
			doc: doc,
			params: params,
			platforms: [Cross],
			targets: targets
		};

		#if macro
		haxe.macro.Compiler.registerCustomMetadata(metaDesc);
		#end

		return {
			meta: metaDesc,
			disallowMultiple: disallowMultiple,
			paramTypes: paramTypes,
			compileFunc: compileFunc
		};
	}

	// =======================================================
	// * Caching System
	// =======================================================
	#if !reflaxe.disallow_build_cache_check
	public static var isCachedRebuild = false;

	/**
		True in the second and each later build request of one compilation
		server, the requests in which the cache filter may leave out a type.
		A new request starts with false, because the value is not persistent.
	**/
	static var isWarmRequest = false;
	#end

	#if !reflaxe.disallow_build_cache_check
	@:persistent static var isCachedRun = false;
	@:persistent static var previousSuccessfulModuleIds: Null<Array<String>> = null;
	@:persistent static var previousSuccessfulNonClassSourceTexts: Null<Array<String>> = null;
	static var currentModuleIds: Null<Array<String>> = null;
	static var currentNonClassSourceTexts: Null<Array<String>> = null;
	#end

	#if !reflaxe.disallow_build_cache_check
	/** Counts the requests of this macro interpreter. See `requestToken`. **/
	@:persistent static var requestCount = 0;

	/**
		A text that names this request and no other request of this server:
		the start time and the request count. See `wasTypedSinceLastPublication`.
	**/
	static var requestToken: Null<String> = null;

	/**
		The request tokens of the types whose output this server published
		last. `commitSuccessfulModuleIds` replaces it after each publication.
		See `wasTypedSinceLastPublication`.
	**/
	@:persistent static var publishedTokens: Null<Map<String, Bool>> = null;

	/**
		The `typeKey` of each type that the cache filter left out of this
		request, or null when it left out none. See `wasLeftOutByCacheFilter`.
	**/
	static var leftOutTypeKeys: Null<Map<String, Bool>> = null;
	#end

	/**
		The metadata `@:reflaxe.typedIn(token, owner)`: the request in which
		Haxe typed a class, enum, typedef or abstract, and the type that the
		metadata was made for. See `wasTypedSinceLastPublication`.
	**/
	static inline final TYPED_IN_META = ":reflaxe.typedIn";

	public static function checkServerCache() {
		#if !reflaxe.disallow_build_cache_check
		if(#if eval !Context.defined("display") #else true #end) {
			requestCount++;
			requestToken = Std.string(Sys.time()) + "/" + requestCount;
			if(!isCachedRun) {
				isCachedRun = true;
			} else {
				isWarmRequest = true;
			}
		}
		#end
	}

	/**
		Returns true when this server has not published output for the typed
		`type` as it is now: Haxe typed it in this request, or in a request that
		published nothing. Also returns true when the request cannot tell: the
		first request of a compilation server, a build without a server, or a
		build with `-D reflaxe.disallow_build_cache_check`.

		The cache filter builds such a type again. A target can keep a result
		that it computed from one type's typed body between server requests and
		compute it again only when this returns true. Call it after typing, for
		example from `BaseCompiler.filterTypes`.

		HOW
		- `onAfterTyping` adds `@:reflaxe.typedIn(token, owner)` to each type
		  that has no such metadata for itself. `owner` is `typeKey(type)`. A
		  type that Haxe reused from the server cache keeps the metadata of the
		  request that typed it. A type that Haxe typed again is a new object
		  and gets this request's token.
		- `commitSuccessfulModuleIds` keeps the tokens of all types of a request
		  that published its output (`publishedTokens`). A type whose token is
		  not in that set was typed after that publication.

		WHY each part is needed
		- Haxe saves a class's metadata after typing ("save state", which comes
		  after `onAfterTyping`) and puts it back when a later request reuses
		  the class. The metadata is part of that saved state. Metadata added
		  after output publication would be removed again on reuse.
		- Haxe keeps the typed modules of a request whenever the request had no
		  error, also when nothing was generated. An editor's JSON-RPC
		  `display/diagnostics` request types every module, has no `display`
		  define, runs Reflaxe's typing hooks, and generates nothing. A type
		  that it typed again must still count as new in the next build, so a
		  token alone is not enough: the token must also be published.
		- A macro can copy the metadata of a reused type onto a type that it
		  defines, for example `Context.defineType` with
		  `meta: base.meta.get()`. The copy carries an old, published token.
		  The owner tells the copy apart; such metadata is replaced.
		- A type without the metadata counts as new: for example a type that
		  an editor request with the `display` define typed, where Reflaxe does
		  not run.

		WHY not a build macro: Reflaxe used to record each type that its global
		build macro saw. That macro exists only after Reflaxe's initialization
		macro registered it, so it missed a type that Haxe typed earlier in the
		request, for example for a project line
		`--macro haxe.macro.Context.getType("Status")` in front of
		`-lib reflaxe.elixir`. The cache filter then left out an edited type,
		and the warm build kept its old output and reported success. Haxe also
		runs no global build macro for an instance of a `@:generic` class, such
		as `Box_String`. The metadata does not depend on when or how Haxe typed
		the type.
	**/
	public static function wasTypedSinceLastPublication(type: BaseType): Bool {
		#if !reflaxe.disallow_build_cache_check
		if(!isWarmRequest) {
			return true;
		}
		final token = ownTypedInToken(type);
		final published = publishedTokens;
		return token == null || published == null || !published.exists(token);
		#else
		return true;
		#end
	}

	/**
		Returns true when Haxe typed `type` in this request, or when the request
		cannot tell (see `wasTypedSinceLastPublication`). Unlike that function,
		this returns false for a type that an earlier request typed and did not
		publish.

		Use it to find a type that Haxe did not type again although its source
		changed: Reflaxe.Elixir's `ServerSourceFreshness.refuseStaleReuse`.
	**/
	public static function wasTypedThisRequest(type: BaseType): Bool {
		#if !reflaxe.disallow_build_cache_check
		if(!isWarmRequest) {
			return true;
		}
		final token = ownTypedInToken(type);
		return token == null || token == requestToken;
		#else
		return true;
		#end
	}

	#if !reflaxe.disallow_build_cache_check
	/**
		Returns the token of the `@:reflaxe.typedIn` metadata of `type`, or null
		when the type has none, or only one that a macro copied from another
		type.
	**/
	static function ownTypedInToken(type: BaseType): Null<String> {
		final owner = type.meta.extractStringFromFirstMeta(TYPED_IN_META, 1);
		if(owner != typeKey(type)) {
			return null;
		}
		return type.meta.extractStringFromFirstMeta(TYPED_IN_META, 0);
	}
	#end

	/**
		Returns true when the cache filter left the type with this `typeKey`
		out of this request: the type is live, and its published output from the
		last publication stays as it is. Returns false for every other type: a
		type that Reflaxe builds in this request, a type that is not live, and
		every type of a request that is not a cached rebuild.

		A target uses it to find the old output that no type of this request
		owns any more. Example: a class that became `extern` is built again and
		writes nothing, so its old file belongs to no left-out type, and the
		target deletes the file as a fresh build would not write it.
	**/
	public static function wasLeftOutByCacheFilter(key: String): Bool {
		#if !reflaxe.disallow_build_cache_check
		final keys = leftOutTypeKeys;
		return keys != null && keys.exists(key);
		#else
		return false;
		#end
	}

	/**
		Returns a key for a type that is the same before and after Haxe applies
		an `@:native` name: the source module, then the dotted path that the
		Haxe source gives to the type. Haxe stores that path in `@:realPath`
		when it renames the type, and renames it after `onAfterTyping`.
		A target can use it to remember which type wrote an output file; see
		`wasLeftOutByCacheFilter`.
	**/
	public static function typeKey(type: BaseType): String {
		final realPath = type.meta.extractStringFromFirstMeta(":realPath");
		return type.module + "\u0000" + (realPath != null ? realPath : type.pack.concat([type.name]).join("."));
	}

	/**
		Adds this request's token to each type that has no
		`@:reflaxe.typedIn` metadata for itself, and replaces metadata that a
		macro copied from another type. See `wasTypedSinceLastPublication`.
	**/
	static function markTypedTypes(moduleTypes: Array<ModuleType>) {
		#if (eval && !reflaxe.disallow_build_cache_check)
		final token = requestToken;
		if(token == null) {
			return;
		}
		// A position outside every source file. An editor request reads the
		// metadata of cached modules (`check_display_module` in Haxe), so the
		// metadata stays away from positions that a cursor can point at.
		final nowhere = Context.makePosition({ min: 0, max: 0, file: "" });
		for(moduleType in moduleTypes) {
			final type = moduleType.getCommonData();
			if(type.meta.has(TYPED_IN_META)) {
				if(ownTypedInToken(type) != null) {
					continue;
				}
				type.meta.remove(TYPED_IN_META);
			}
			final key = typeKey(type);
			type.meta.add(TYPED_IN_META, [
				{ expr: EConst(CString(token)), pos: nowhere },
				{ expr: EConst(CString(key)), pos: nowhere }
			], nowhere);
		}
		#end
	}

	/**
		Remembers the tokens of all types of this request, after its output was
		published. Every live type is then published: Reflaxe built it in this
		request, or it was published before and the cache filter left it out.
	**/
	static function commitPublishedTokens() {
		#if (eval && !reflaxe.disallow_build_cache_check)
		final types = haxeProvidedModuleTypes;
		if(types == null) {
			return;
		}
		final tokens = new Map<String, Bool>();
		for(moduleType in types) {
			final token = ownTypedInToken(moduleType.getCommonData());
			if(token != null) {
				tokens.set(token, true);
			}
		}
		publishedTokens = tokens;
		#end
	}

	// =======================================================
	// * Plugin System
	// =======================================================
	static var initCallbacks: Null<Array<Dynamic>> = null;

	/**
		Call this to access the BaseCompiler that's about to be used.
		This can be used to add callbacks to the hooks if desired.
	**/
	public static function onCompileBegin<T: BaseCompiler>(callback: (T) -> Void) {
		if(initCallbacks == null) initCallbacks = [];
		initCallbacks.push(callback);
	}

	static function callInitCallbacks<T: BaseCompiler>(compiler: T) {
		if(initCallbacks != null) {
			for(c in initCallbacks) {
				Reflect.callMethod({}, c, [compiler]);
			}
		}
	}

	// =======================================================
	// * Private Members
	// =======================================================
	static var haxeProvidedModuleTypes: Null<Array<ModuleType>>;

	static function onAfterTyping(moduleTypes: Array<ModuleType>) {
		haxeProvidedModuleTypes = moduleTypes;
		markTypedTypes(moduleTypes);
	}

	static function onAfterGenerate() {
		checkCompilers();
	}

	static function checkCompilers() {
		if(Compilers.length <= 0) {
			return;
		}

		final validCompilers = findEnabledCompilers();
		if(validCompilers.length == 1) {
			if(#if eval !Context.defined("display") #else true #end) {
				startCompiler(validCompilers[0]);
			}
		} else if(validCompilers.length > 1) {
			tooManyCompilersError(validCompilers);
		}
	}

	static function findEnabledCompilers(): Array<BaseCompiler> {
		final validCompilers = [];
		#if eval
		#if (haxe_ver > "5.0.0")
		final outputPath = switch(Compiler.getConfiguration().platform) {
			case CustomTarget(_): Compiler.getOutput();
			case _: "";
		}
		#end
		for(compiler in Compilers) {
			final outputDirDef = compiler.options.outputDirDefineName;
			final outputDir = Context.definedValue(outputDirDef);
			if(Context.defined(outputDirDef) && outputDir.length > 0) {
				compiler.setOutputDir(outputDir);
				validCompilers.push(compiler);
			#if (haxe_ver > "5.0.0")
			} else if(outputPath.length > 0) {
				compiler.setOutputDir(outputPath);
				validCompilers.push(compiler);
			#end
			} else {
				final compilerName = HaxeType.getClassName(HaxeType.getClass(compiler));
				final pos = Context.currentPos();
				final msg = 'The $compilerName compiler is enabled; however, the output directory (-D $outputDirDef) is not defined.';
				Context.error(msg, pos);
			}
		}
		#end
		return validCompilers;
	}

	static function tooManyCompilersError(compilers: Array<BaseCompiler>) {
		#if eval
		final compilerList = compilers.map(c -> HaxeType.getClassName(HaxeType.getClass(c))).join(" | ");
		final pos = Context.currentPos();
		final msg = 'Multiple compilers have been enabled, only one may be active per build: $compilerList';
		Context.error(msg, pos);
		#end
	}

	static function startCompiler(compiler: BaseCompiler) {
		#if (eval && reflaxe_measure)
		final start = new reflaxe.debug.MeasurePerformance();
		#end

		useCompiler(compiler);

		#if (eval && reflaxe_measure)
		start.measure("Reflaxe target compiled in %MILLI% milliseconds");
		#end
	}

	static function useCompiler(compiler: BaseCompiler) {
		// Copy over types provided by Haxe compiler
		final moduleTypes = compiler.filterTypes(haxeProvidedModuleTypes != null ? haxeProvidedModuleTypes.copy() : []);

		// Track Hierarchy
		if(compiler.options.trackClassHierarchy) {
			ClassHierarchyTracker.processAllClasses(moduleTypes);
		}

		// Apply other type filters
		final moduleTypes = applyModuleFilters(compiler, moduleTypes);

		// Start
		callInitCallbacks(compiler);
		compiler.onCompileStart();

		// Compile
		addClassesToCompiler(compiler, moduleTypes);

		// End
		compiler.onCompileEnd();
		for(callback in compiler.compileEndCallbacks) {
			callback();
		}

		// Compile any additional modules that
		// may be required after `onCompileEnd`.
		if(isManualDCE(compiler)) {
			dynamicallyAddModulesToCompiler(compiler);
		}

		// Generate files
		generateFiles(compiler);
		compiler.onOutputComplete();
		commitSuccessfulModuleIds();
	}

	/**
		Filters types based on defines and build cache.
	**/
	static function applyModuleFilters(compiler: BaseCompiler, moduleTypes: Array<ModuleType>) {
		final moduleTypes = applyDefineFilters(moduleTypes);
		final moduleTypes = applyBuildCacheCheckFilter(compiler, moduleTypes);
		return moduleTypes;
	}

	static function applyDefineFilters(moduleTypes: Array<ModuleType>) {
		#if (eval && reflaxe.only_generate)
		final allowedPacks = try { haxe.Json.parse(Context.definedValue(Define.OnlyGenerate)); } catch(_) { []; }
		return moduleTypes.filter(mt -> {
			final pack = mt.getCommonData().pack.join(".");
			for(allowed in allowedPacks) {
				if(StringTools.startsWith(pack, allowed)) {
					return true;
				}
			}
			return false;
		});
		#elseif (eval && reflaxe.generate_everything_except)
		final disallowedPacks = try { haxe.Json.parse(Context.definedValue(Define.GenerateEverythingExcept)); } catch(_) { []; }
		return moduleTypes.filter(mt -> {
			final pack = mt.getCommonData().pack.join(".");
			for(allowed in disallowedPacks) {
				if(StringTools.startsWith(pack, allowed)) {
					return false;
				}
			}
			return true;
		});
		#else
		return moduleTypes;
		#end
	}

	static function applyBuildCacheCheckFilter(compiler: BaseCompiler, moduleTypes: Array<ModuleType>) {
		#if !reflaxe.disallow_build_cache_check
		leftOutTypeKeys = null;
		// Each step below reads the same facts of each type. In the macro
		// interpreter, `getCommonData`, `typeKey` and the compiler's
		// `isReadWithoutDependency` each cost a few milliseconds for a program
		// of 500 types, so they are read once here for the whole request.
		final types = describeTypes(compiler, moduleTypes);
		currentModuleIds = [
			for(type in types)
				if(countsForLiveModuleSet(type)) type.moduleType.getUniqueId()
		];
		currentModuleIds.sort(Reflect.compare);
		currentNonClassSourceTexts = collectNonClassSourceTexts(types);
		final liveModuleSetChanged = previousSuccessfulModuleIds != null
			&& !previousSuccessfulModuleIds.equals(currentModuleIds);
		final nonClassSourceChanged = previousSuccessfulNonClassSourceTexts != null
			&& !previousSuccessfulNonClassSourceTexts.equals(currentNonClassSourceTexts);

		if(isWarmRequest && !liveModuleSetChanged && !nonClassSourceChanged) {
			final result = [];
			final keptKeys = new Map<String, Bool>();
			for(type in types) {
				final build = switch(type.moduleType) {
					case TClassDecl(_.get() => c):
						compiler.shouldRecompileClass(c) || wasTypedSinceLastPublication(c);
					case TEnumDecl(_):
						// Haxe types an enum again when its file or a module that it
						// uses changed. An enum that Haxe reused has the same output.
						wasTypedSinceLastPublication(type.data);
					case _:
						true; // Typedefs and abstracts produce no module of their own; always pass them on.
				}
				if(build) {
					result.push(type.moduleType);
					keptKeys.set(type.key, true);
				}
			}

			// If anything is filtered out, we ARE doing a cache rebuild.
			if(result.length != moduleTypes.length) {
				isCachedRebuild = true;
				final leftOut = new Map<String, Bool>();
				for(type in types) {
					if(!keptKeys.exists(type.key)) {
						leftOut.set(type.key, true);
					}
				}
				leftOutTypeKeys = leftOut;
			}

			return result;
		}
		#end
		return moduleTypes;
	}

	/**
		Returns true when `moduleType` counts in the live module set that
		`applyBuildCacheCheckFilter` compares between requests. A change of
		that set builds every type again.

		Classes and enums always count: they write output files, and a removed
		one must not leave its old file behind. A typedef or an abstract counts
		only when the compiler can read it without a dependency
		(`BaseCompiler.isReadWithoutDependency`). Otherwise it writes no file of
		its own, and the types that use it are typed again by Haxe. Example: a
		new `typedef RowView = {...}` in a LiveView file builds that file's
		types and their users, not every module. The hidden class that holds
		the methods of an abstract is a class, so it still counts.
	**/
	static function countsForLiveModuleSet(type:DescribedType):Bool {
		return switch(type.moduleType) {
			case TClassDecl(_) | TEnumDecl(_): true;
			case TTypeDecl(_) | TAbstract(_): type.readWithoutDependency;
		}
	}

	/**
		Returns, for each type of this request, the facts that the cache
		filter reads: the common data, the `typeKey`, and the compiler's
		`isReadWithoutDependency` answer. Each is read once per request.
	**/
	static function describeTypes(compiler:BaseCompiler, moduleTypes:Array<ModuleType>):Array<DescribedType> {
		return [
			for(moduleType in moduleTypes) {
				final data = moduleType.getCommonData();
				final key = typeKey(data);
				{
					moduleType: moduleType,
					data: data,
					key: key,
					readWithoutDependency: compiler.isReadWithoutDependency(moduleType, key)
				};
			}
		];
	}

	/**
		Returns, for each source file that defines an enum, typedef, or abstract
		that the compiler can read without a dependency
		(`BaseCompiler.isReadWithoutDependency`), the file path and the file
		text without its classes and module-level fields.

		Reflaxe can tell which types Haxe typed again (`wasTypedSinceLastPublication`):
		the types of an edited file and every type that refers to one of them.
		A compiler can also read a type that no built type refers to. For
		example, changing an unreferenced `@:phxHookNames` abstract must
		revalidate every HXX template that uses the global hook registry.
		Without this comparison, a warm build can accept a hook that a clean
		build correctly rejects.

		Only these files are compared. In any other file, an edit outside the
		classes (a comment, a typedef field, a new typedef) builds the file's
		types and the types that Haxe typed again with them. Example: in a
		LiveView file with three typedefs, a comment after the class built all
		141 classes of the todo-app (about 14 s) before this rule, and builds
		the same 3 classes as an edit inside the class now.

		When one of these texts changes, `applyBuildCacheCheckFilter` performs one
		full target regeneration. Reading exact bytes avoids trusting timestamps;
		duplicate declarations from the same source file are read only once.

		Each entry holds the text itself, not a hash of it. Haxe compares two
		strings with native code, but it runs SHA-256 in the macro interpreter,
		which cost about half a second for each warm request of a 400-file
		project. The cost is memory: the server keeps one copy of these texts.

		Why the classes are cut out: many source files declare a typedef or an
		enum beside a class or beside module-level functions. With the complete
		file text, an edit in a function body of such a file caused a full
		regeneration (36 to 74 s for a consumer backend), although the enum and
		the typedef did not change. A class in such a file now has the same rule
		as a class in a file of its own: Haxe types it again and reports it, and
		Reflaxe builds it again. `nonClassSourceText` explains what is cut and
		what stays.
	**/
	static function collectNonClassSourceTexts(types:Array<DescribedType>):Array<String> {
		#if eval
		final fullPaths = new Map<String, String>();
		function fullPath(sourceFile:String):String {
			final known = fullPaths.get(sourceFile);
			if(known != null) {
				return known;
			}
			final resolved = try FileSystem.fullPath(sourceFile) catch(_) sourceFile;
			fullPaths.set(sourceFile, resolved);
			return resolved;
		}

		// A file is compared when it declares an enum, typedef or abstract and
		// the compiler can read one of its types without a dependency.
		final nonClassFiles = new Map<String, Bool>();
		final readFiles = new Map<String, Bool>();
		final classTypes:Array<ClassType> = [];
		for(type in types) {
			final isClass = switch(type.moduleType) {
				case TClassDecl(_.get() => classType):
					classTypes.push(classType);
					true;
				case _:
					false;
			}
			final readWithoutDependency = type.readWithoutDependency;
			if(isClass && !readWithoutDependency) {
				continue;
			}
			final sourceFile = Context.getPosInfos(type.data.pos).file;
			if(sourceFile == null || sourceFile.length == 0) {
				continue;
			}
			final resolved = fullPath(sourceFile);
			if(!isClass) {
				nonClassFiles.set(resolved, true);
			}
			if(readWithoutDependency) {
				readFiles.set(resolved, true);
			}
		}
		final sourceFiles = new Map<String, Bool>();
		for(sourceFile in nonClassFiles.keys()) {
			if(readFiles.exists(sourceFile)) {
				sourceFiles.set(sourceFile, true);
			}
		}

		// Only a class that shares its file with a non-class declaration matters.
		final classSpans = new Map<String, Array<ClassSourceSpan>>();
		for(classType in classTypes) {
			final sourceFile = Context.getPosInfos(classType.pos).file;
			if(sourceFile == null || sourceFile.length == 0) {
				continue;
			}
			final resolved = fullPath(sourceFile);
			if(!sourceFiles.exists(resolved)) {
				continue;
			}
			var spans = classSpans.get(resolved);
			if(spans == null) {
				spans = [];
				classSpans.set(resolved, spans);
			}
			addClassSourceSpans(classType, sourceFile, spans);
		}

		final result = [];
		for(sourceFile in sourceFiles.keys()) {
			final text = try nonClassSourceText(File.getBytes(sourceFile).toString(), classSpans.get(sourceFile)) catch(_) "<unreadable>";
			result.push(sourceFile + "\u0000" + text);
		}
		result.sort(Reflect.compare);
		return result;
		#else
		return [];
		#end
	}

	#if eval
	/**
		Adds the places in `sourceFile` where Haxe says that `classType` is
		written: the declaration of an ordinary class or interface, or each
		function and variable of a module-level field class.

		Other kinds of class are ignored, and their text stays. The most
		important one is the hidden class that holds the methods of an abstract:
		its position is the abstract itself, which is a non-class declaration.
	**/
	static function addClassSourceSpans(classType:ClassType, sourceFile:String, spans:Array<ClassSourceSpan>) {
		switch(classType.kind) {
			case KNormal:
				// Haxe renames a class with `@:native` and keeps the source path in `@:realPath`.
				final realPath = classType.meta.extractStringFromFirstMeta(":realPath");
				final sourceName = realPath != null ? realPath.substr(realPath.lastIndexOf(".") + 1) : classType.name;
				final position = Context.getPosInfos(classType.pos);
				spans.push({
					min: position.min,
					max: position.max,
					start: new EReg("^(class|interface)\\s+" + EReg.escape(sourceName) + "\\b", ""),
					endsWithBrace: true
				});
			case KModuleFields(_):
				for(field in classType.statics.get()) {
					final position = Context.getPosInfos(field.pos);
					if(position.file != sourceFile) {
						continue;
					}
					spans.push({
						min: position.min,
						max: position.max,
						start: new EReg("^((public|private|static|inline|dynamic|extern|final|macro|overload)\\s+)*(function|var|final)\\s+" + EReg.escape(field.name) + "\\b", ""),
						endsWithBrace: false
					});
				}
			case _:
		}
	}

	/**
		Returns the text of one source file without its classes and module-level
		fields, or the complete text when any position cannot be trusted.

		What is removed: for `class Name { ... }` and `interface Name { ... }`,
		the text from the keyword to the last brace. For a module-level
		`function name(...) ...` or `var name ...`, the text from its first
		modifier to the end of its body. Each removed part leaves one zero
		character, so two files are equal only when they have the same parts in
		the same places.

		What stays: every enum, typedef and abstract; imports; text between
		declarations; and the metadata, documentation and modifiers in front of
		a class, because Haxe does not include them in the class position. An
		edit in any of these still causes a full regeneration. This function
		runs only for the files that `collectNonClassSourceTexts` compares.

		Units: a Haxe position counts characters, not bytes. A byte order mark
		is one character, and so is `é` or an emoji. `text` is the decoded file,
		and Haxe's macro interpreter also indexes a string by character, so the
		positions are used on `text` directly. An earlier version cut the raw
		bytes. In a file with non-ASCII text before a class, the cut then
		started too early and could reach over an enum or an abstract, and a
		change there was not seen.

		Each position is checked before anything is removed:
		- it lies inside the text and does not overlap another position (two
		  equal positions count once: a macro can define a second class at the
		  position of the first);
		- the text there starts with the declaration that Haxe named;
		- a class ends with `}`;
		- the text does not contain the start of an enum, typedef or abstract.
		  Haxe has no nested type declarations, so such a start inside a class
		  can only be in a string or a comment.

		When any check fails, nothing is removed from this file and the complete
		text is returned. The file then behaves as before this function existed:
		each edit in it causes a full regeneration. A failed check can thus only
		cost time. It covers classes that a macro defines with a borrowed
		position, and positions that are older than the file on disk.

		A class or field that Haxe removed as unused is not in the list, so its
		text stays.

		Example: a file holds `typedef Options = {...}` and
		`function render(options:Options) { return "a"; }`. A change of `"a"` to
		`"b"` gives the same result, and only the changed function's module is
		built again. A change in `Options` gives a different result.
	**/
	static function nonClassSourceText(text:String, spans:Null<Array<ClassSourceSpan>>):String {
		final complete = "all\u0000" + text;
		if(spans == null || spans.length == 0) {
			return complete;
		}
		spans.sort((left, right) -> left.min != right.min ? left.min - right.min : left.max - right.max);
		final nonClassStart = ~/(^|[^A-Za-z0-9_.$])(enum|typedef|abstract)\s+(abstract\s+)?[A-Z_]/;
		final result = new StringBuf();
		result.add("cut\u0000");
		var cursor = 0;
		var previousMin = -1;
		var previousMax = -1;
		for(span in spans) {
			if(span.min == previousMin && span.max == previousMax) {
				continue;
			}
			if(span.min < cursor || span.max <= span.min || span.max > text.length) {
				return complete;
			}
			final removed = text.substring(span.min, span.max);
			if(!span.start.match(removed)) {
				return complete;
			}
			if(span.endsWithBrace && !StringTools.endsWith(removed, "}")) {
				return complete;
			}
			if(nonClassStart.match(removed)) {
				return complete;
			}
			result.add(text.substring(cursor, span.min));
			result.add("\u0000");
			cursor = span.max;
			previousMin = span.min;
			previousMax = span.max;
		}
		result.add(text.substring(cursor));
		return result.toString();
	}
	#end

	/**
		Remembers the live Haxe modules only after target output was published.

		A normal compiler-server edit can safely regenerate only the classes Haxe
		retyped. A deleted class is different: there is no class left that Haxe could
		type again. Comparing the complete live module set with the last
		successful request lets `applyBuildCacheCheckFilter` detect additions,
		deletions, and renames and perform one full target rebuild. Without that full
		rebuild, a deleted Haxe module can leave its old generated target file on disk.

		The snapshot is committed here, after successful output publication, so a
		failed target build cannot become the baseline for the next server request.
	**/
	static function commitSuccessfulModuleIds() {
		#if !reflaxe.disallow_build_cache_check
		if(currentModuleIds != null) {
			previousSuccessfulModuleIds = currentModuleIds.copy();
		}
		if(currentNonClassSourceTexts != null) {
			previousSuccessfulNonClassSourceTexts = currentNonClassSourceTexts.copy();
		}
		commitPublishedTokens();
		#end
	}

	static function getAllModulesTypesForCompiler(compiler: BaseCompiler, moduleTypes: ReadOnlyArray<ModuleType>): ReadOnlyArray<ModuleType> {
		return if(compiler.options.ignoreTypes.length > 0) {
			final ignoreTypes = compiler.options.ignoreTypes;
			moduleTypes.filter(function(moduleType) {
				return !ignoreTypes.contains(moduleType.getPath());
			});
		} else {
			moduleTypes;
		}
	}

	static function getAllKeepTypes(compiler: BaseCompiler, moduleTypes: ReadOnlyArray<ModuleType>): ReadOnlyArray<ModuleType> {
		final tracker = new ModuleUsageTracker(moduleTypes, compiler);
		return tracker.nonStdTypes().filter(m -> m.getCommonData().meta.has(":keep"));
	}

	/**
		Used internally for `getAllIncludedTypes`.
	**/
	static var noValueHaxeCompilerArguments = [
		"--no-output", "--interp", "--run", "-v", "--verbose", "--debug", "-debug", "--prompt", "-prompt",
		"--no-traces", "--display", "--times", "--no-inline", "--no-opt", "--flash-strict", "--version", "-version", 
		"-h", "--help", "-help", "--help-defines", "--help-user-defines", "--help-metas", "--help-user-metas",
		"--haxelib-global",
	];

	/**
		The intent of this is to return all types included directly via command
		line arguments or `.hxml`.

		Unfortunately, there is no official method to obtain these types, so
		the Haxe compiler arguments are re-parsed to find them.

		This function may be flawed, so please report if a type or package that should
		be included is not returned from this!!
	**/
	static function getAllIncludedTypes(compiler: BaseCompiler, moduleTypes: ReadOnlyArray<ModuleType>): ReadOnlyArray<ModuleType> {
		final compilerArguments = #if macro Compiler.getConfiguration().args #else [] #end;

		var i = 0;
		final includedPaths = [];
		while(i < compilerArguments.length) {
			final arg = compilerArguments[i];
			if(StringTools.startsWith(arg, "-")) {
				if(noValueHaxeCompilerArguments.contains(arg)) {
					i++;
				} else {
					// This is a argument has a value, so skip the next one.
					i += 2;
				}
			} else {
				// No named argument, so this must be an included module or pack.
				includedPaths.push(arg);
				i++;
			}
		}

		final tracker = new ModuleUsageTracker(moduleTypes, compiler);
		return tracker.nonStdTypes().filter(m -> {
			for(path in includedPaths) {
				if(m.getCommonData().startsWithDotPath(path)) {
					return true;
				}
			}
			return false;
		});
	}

	static function addClassesToCompiler(compiler: BaseCompiler, moduleTypes: Array<ModuleType>) {
		if(isManualDCE(compiler)) {
			for(m in getAllKeepTypes(compiler, moduleTypes)) {
				compiler.addModuleTypeForCompilation(m);
			}

			for(m in getAllIncludedTypes(compiler, moduleTypes)) {
				compiler.addModuleTypeForCompilation(m);
			}

			dynamicallyAddModulesToCompiler(compiler);
		} else {
			addModulesToCompiler(compiler, getAllModulesTypesForCompiler(compiler, moduleTypes));
		}
	}

	static function dynamicallyAddModulesToCompiler(compiler: BaseCompiler) {
		while(compiler.dynamicTypeStack.length > 0) {
			final temp = compiler.dynamicTypeStack;
			compiler.dynamicTypeStack = [];
			addModulesToCompiler(compiler, temp);
		}
	}

	static function addModulesToCompiler(compiler: BaseCompiler, modules: ReadOnlyArray<ModuleType>) {
		final classDecls: Array<Ref<ClassType>> = [];
		final enumDecls: Array<Ref<EnumType>> = [];
		final defDecls: Array<Ref<DefType>> = [];
		final abstractDecls: Array<Ref<AbstractType>> = [];

		for(moduleType in modules) {
			switch(moduleType) {
				case TClassDecl(clsTypeRef): {
					classDecls.push(clsTypeRef);
				}
				case TEnumDecl(enumTypeRef): {
					enumDecls.push(enumTypeRef);
				}
				case TTypeDecl(defTypeRef): {
					defDecls.push(defTypeRef);
				}
				case TAbstract(abstractRef): {
					abstractDecls.push(abstractRef);
				}
			}
		}

		for(clsRef in classDecls) {
			final cls = clsRef.get();
			if(compiler.options.enforceNullTyping) {
				NullTypeEnforcer.checkClass(cls);
			}
			compiler.setupModule(TClassDecl(clsRef));
			if(compiler.shouldGenerateClass(cls)) {
				transpileClass(cls, compiler);
			}
		}

		for(enumRef in enumDecls) {
			final enm = enumRef.get();
			compiler.setupModule(TEnumDecl(enumRef));
			if(compiler.shouldGenerateEnum(enm)) {
				transpileEnum(enm, compiler);
			}
		}

		for(defRef in defDecls) {
			final def = defRef.get();
			compiler.setupModule(TTypeDecl(defRef));
			compiler.compileTypedef(def);
		}

		for(abstractRef in abstractDecls) {
			final ab = abstractRef.get();
			compiler.setupModule(TAbstract(abstractRef));
			compiler.compileAbstract(ab);
		}

		compiler.setupModule(null);
	}

	static function generateFiles(compiler: BaseCompiler) {
		compiler.generateFiles();
	}

	// =======================================================
	// * DCE helpers
	// =======================================================
	static function isDceOn(): Bool {
		return (#if eval Context.definedValue #else Compiler.getDefine #end ("dce")) != "no";
	}

	static function isManualDCE(compiler: BaseCompiler): Bool {
		return isDceOn() && compiler.options.manualDCE;
	}

	// =======================================================
	// * transpileClass
	// =======================================================
	static function transpileClass(cls: ClassType, compiler: BaseCompiler) {
		final varFields: Array<ClassVarData> = [];
		final funcFields: Array<ClassFuncData> = [];

		final ignoreExterns = compiler.options.ignoreExterns;

		final addField = function(field: ClassField, isStatic: Bool) {
			if(ignoreExterns && field.isExtern) {
				return;
			}

			#if reflaxe_extern_meta
			if(field.hasMeta(":reflaxe_extern")) {
				return;
			}
			#end

			switch(field.kind) {
				case FVar(readVarAccess, writeVarAccess): {
					if(shouldGenerateVar(field, compiler, isStatic, readVarAccess, writeVarAccess)) {
						final data = field.findVarData(cls, isStatic);
						if(data != null) {
							varFields.push(data);
						} else {
							throw "Variable information not found.";
						}
					}
				}
				case FMethod(methodKind): {
					if(shouldGenerateFunc(field, compiler, isStatic, methodKind)) {
						final data = field.findFuncData(cls, isStatic);
						if(data != null) {
							funcFields.push(preprocessFunction(compiler, field, data));
						} else {
							if(!compiler.options.ignoreBodilessFunctions) {
								#if eval
								Context.warning("Function information not found.", field.pos);
								#end
							}
						}
					}
				}
			}
		}

		if(cls.constructor != null) {
			final field = cls.constructor.get();
			addField(field, false);
		}

		for(field in cls.fields.get()) {
			addField(field, false);
		}

		for(field in cls.statics.get()) {
			addField(field, true);
		}
	
		compiler.compileClass(cls, varFields, funcFields);
	}

	static function preprocessFunction(compiler: BaseCompiler, field: ClassField, data: ClassFuncData): ClassFuncData {
		if(data.expr == null) {
			return data;
		}
		if(compiler.options.enforceNullTyping) {
			NullTypeEnforcer.modifyExpression(data.expr);
		}
		for(preprocessor in compiler.expressionPreprocessors) {
			preprocessor.process(data, compiler);
		}
		return data;
	}

	// =======================================================
	// * transpileEnum
	// =======================================================
	static function transpileEnum(enm: EnumType, compiler: BaseCompiler) {
		final options = [];
		for(name in enm.names) {
			final field = enm.constructs[name];
			if(field == null) continue;

			final args = switch(field.type) {
				case TFun(args, ret): args;
				case _: [];
			}

			final option = new EnumOptionData(enm, field, name);

			for(a in args) {
				final arg = new EnumOptionArg(option, a.t, a.opt, a.name);
				option.addArg(arg);
			}

			options.push(option);
		}

		compiler.compileEnum(enm, options);
	}

	// =======================================================
	// * shouldGenerateVar
	// * shouldGenerateFunc
	// =======================================================
	static function shouldGenerateVar(field: ClassField, compiler: BaseCompiler, isStatic: Bool, read: VarAccess, write: VarAccess): Bool {
		if(!compiler.shouldGenerateClassField(field)) {
			return false;
		}
		return if(field.meta.maybeHas(":isVar")) {
			true;
		} else {
			switch([read, write]) {
				case [AccNormal | AccNo | AccCtor, _]: true;
				case [_, AccNormal | AccNo | AccCtor]: true;
				case _: !compiler.options.ignoreNonPhysicalFields;
			}
		}
	}

	static function shouldGenerateFunc(field: ClassField, compiler: BaseCompiler, isStatic: Bool, kind: MethodKind): Bool {
		return compiler.shouldGenerateClassField(field);
	}
}

#end
