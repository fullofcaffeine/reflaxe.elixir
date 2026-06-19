package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Type.TConstant;
import haxe.macro.Type.AbstractType;
import haxe.macro.Type.DefType;
import haxe.macro.Type.MethodKind;
import haxe.macro.Expr.Binop;
import haxe.macro.Expr.Unop;
import haxe.macro.Expr;
import haxe.macro.Expr.Constant;
import haxe.macro.ExprTools;
import reflaxe.GenericCompiler;
import reflaxe.compiler.TargetCodeInjection;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;
import reflaxe.data.EnumOptionData;
import reflaxe.output.DataAndFileInfo;
import reflaxe.output.StringOrBytes;
import reflaxe.elixir.ElixirTyper;
import reflaxe.elixir.PhoenixMapper;
import reflaxe.elixir.SourceMapWriter;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.SchemaAssociationKind;
import reflaxe.elixir.ast.ElixirAST.SchemaAssociationMeta;
import reflaxe.elixir.ast.ElixirAST.RouterRouteMeta;
import reflaxe.elixir.ast.ElixirAST.RouterNodeMeta;
import reflaxe.elixir.ast.ElixirAST.RouterOptionMeta;
import reflaxe.elixir.ast.ElixirAST.RouterMetaValue;
import reflaxe.elixir.ast.ElixirAST.SocketChannelMeta;
import reflaxe.elixir.ast.ElixirAST.EndpointSocketMeta;
import reflaxe.elixir.ast.ReceiverReturnConventions;
import reflaxe.elixir.ast.ReceiverReturnConventions.ReceiverReturnConvention;
import reflaxe.elixir.ast.builders.ModuleBuilder;
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.ast.NameUtils;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.macros.ModuleFieldMetadataRegistry;

using StringTools;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.TypeHelper;
using reflaxe.helpers.ModuleTypeHelper;

/**
 * Internal helper result for framework-aware naming.
 *
 * Used by ElixirCompiler to keep module naming and file placement decisions
 * in sync for annotations like @:application without leaking implementation
 * details into other modules.
 */
typedef FrameworkNamingResult = {
	var moduleName:String;
	var modulePack:Array<String>;
	var outputPath:Null<String>;
}

typedef RouterRoutesSource = {
	var expr:Expr;
	var source:String;
}

/**
 * Reflaxe.Elixir compiler for generating idiomatic Elixir code from Haxe.
 * 
 * This compiler extends GenericCompiler to provide comprehensive Haxe-to-Elixir transpilation
 * with support for Phoenix applications, OTP patterns, and gradual typing.
 * 
 * Key Features:
 * - Phoenix LiveView compilation (@:liveview annotation)
 * - Ecto schema generation (@:schema annotation) 
 * - Router DSL compilation (@:router annotation)
 * - Pattern matching and guard compilation
 * - Array method optimization (transforms to Enum functions)
 * - While loop optimization (detects and converts for-in patterns)
 * - Protocol and behavior support
 * - Type-safe repository operations
 * 
 * The compiler performs macro-time transpilation, transforming Haxe's TypedExpr AST
 * into idiomatic Elixir code. It handles desugaring reversal - detecting patterns
 * that Haxe has desugared and converting them back to idiomatic target constructs.
 * 
 * ARCHITECTURE: Uses GenericCompiler<ElixirAST> following C#'s proven pattern.
 * All compilation methods return AST nodes, which are transformed and printed
 * to strings via ElixirOutputIterator at the end of compilation.
 * 
 * @see docs/05-architecture/GENERICCOMPILER_MIGRATION_PRD.md Migration rationale
 * @see docs/05-architecture/ARCHITECTURE.md Complete architectural overview
 * @see docs/03-compiler-development/TESTING.md Testing methodology and patterns
 */
class ElixirCompiler extends GenericCompiler<reflaxe.elixir.ast.ElixirAST, // CompiledClassType
	reflaxe.elixir.ast.ElixirAST, // CompiledEnumType
	reflaxe.elixir.ast.ElixirAST, // CompiledExpressionType
	reflaxe.elixir.ast.ElixirAST, // CompiledTypedefType
	reflaxe.elixir.ast.ElixirAST // CompiledAbstractType
	> {
	// Global module registry for cross-file qualification decisions
	static var globalModuleRegistry:Map<String, Bool> = new Map();

	public static function registerModule(name:String):Void {
		if (name != null && name.length > 0)
			globalModuleRegistry.set(name, true);
	}

	public static function isModuleKnown(name:String):Bool {
		return name != null && globalModuleRegistry.exists(name);
	}

	// Static instance reference for helpers to access the compiler
	public static var instance:ElixirCompiler;

	// File extension for generated Elixir files
	public var fileExtension:String = ".ex";

	// Output directory for generated files (dynamically set by Reflaxe)
	public var outputDirectory:String = "lib/";

	// Type mapping system for enhanced enum compilation
	private var typer:reflaxe.elixir.ElixirTyper;

	// Context tracking for variable substitution
	public var isInLoopContext:Bool = false;

	// Source mapping support for debugging and LLM workflows
	public var currentSourceMapWriter:Null<SourceMapWriter> = null;
	public var sourceMapOutputEnabled:Bool = false;
	public var pendingSourceMapWriters:Array<SourceMapWriter> = [];

	// Parameter mapping system for abstract type implementation methods
	public var currentFunctionParameterMap:Map<String, String> = new Map();

	// Context-aware pattern usage tracking for enum parameter optimization
	// Tracks which pattern variables are actually used in switch case bodies
	// to prevent generating orphaned enum parameter extractions
	public var patternUsageContext:Null<Map<String, Bool>> = null;

	// Return context tracking for case expression assignment
	// When true, indicates we're compiling a return expression and case results
	// need to be assigned to temp_result for proper value capture in Elixir
	public var returnContext:Bool = false;

	// Map for tracking variable renames to ensure consistency between declaration and usage
	// Track whether we're compiling in a statement context (for mutable operations)
	// When true, array.push(item) generates reassignment: array = array ++ [item]
	public var isStatementContext:Bool = false;
	// Critical for resolving _g variable collisions in desugared loops
	public var variableRenameMap:Null<Map<String, String>> = null;

	// Track inline function context across multiple expressions in a block
	// Maps inline variable names (like "struct") to their assigned values (like "struct.buf")
	public var inlineContextMap:Map<String, String> = new Map<String, String>();

	private var isCompilingAbstractMethod:Bool = false;

	public var isCompilingCaseArm:Bool = false;

	// Track when we're inside enum parameter extraction to prevent incorrect variable mappings
	public var isInEnumExtraction:Bool = false;

	// Track enum extraction variables with their indices to handle multiple parameters correctly
	// Track loop variable context to distinguish between counter and limit variables
	public var loopCounterVar:String = null; // Current loop counter variable name
	public var loopLimitVar:String = null; // Current loop limit variable name
	public var isInLoopCondition:Bool = false; // Flag when compiling loop conditions
	public var enumExtractionVars:Null<Array<{index:Int, varName:String}>> = null;
	public var currentEnumExtractionIndex:Int = 0;

	/**
	 * Current switch case body being compiled
	 * 
	 * WHY: Used by EnumIntrospectionCompiler to perform AST analysis of case bodies
	 *      to detect orphaned enum parameter extractions. This prevents generating
	 *      unused 'g = elem(spec, N)' assignments for parameters that are never referenced.
	 * 
	 * WHAT: Contains the TypedExpr of the case body currently being processed by the compiler.
	 *       Set when entering switch case compilation, cleared when exiting.
	 * 
	 * HOW: PatternMatchingCompiler sets this field when compiling each case body,
	 *      allowing EnumIntrospectionCompiler to analyze whether extracted parameters
	 *      are actually used in the subsequent case logic.
	 * 
	 * EDGE CASES: Only valid during switch case compilation, null otherwise
	 * 
	 * ARCHITECTURAL BENEFIT: Provides AST-based orphaned parameter detection without
	 *                        hardcoding specific enum names, making the solution general
	 *                        and maintainable for any enum type.
	 */
	public var currentSwitchCaseBody:Null<TypedExpr> = null;

	// Current class context for app name resolution and other class-specific operations
	public var currentClassType:Null<ClassType> = null;

	// Track instance variable names for LiveView classes to generate socket.assigns references

	/**
	 * STATE THREADING MODE
	 * 
	 * WHY: Transform mutable field assignments in Haxe to immutable struct updates in Elixir
	 * WHAT: Track when we're compiling a mutating method that needs state threading
	 * HOW: When enabled, field assignments generate struct updates that are threaded through
	 */
	public var stateThreadingEnabled:Bool = false;

	// State threading info removed - handled by AST transformer

	/**
	 * GLOBAL STRUCT METHOD COMPILATION
	 * 
	 * WHY: Fix JsonPrinter _this issue - parameter mapping gets lost in nested contexts
	 * WHAT: Track if we're compiling ANY struct method globally
	 * HOW: Set flag when compiling struct methods, use global mapping that persists through all nested compilation
	 */
	public var isCompilingStructMethod:Bool = false;

	public var globalStructParameterMap:Map<String, String> = new Map();

	// Track temporary variables consumed by array ternary optimization
	// Maps temp_array names to their replacement direct assignments
	public var consumedTempVariables:Null<Map<String, String>> = null;

	/**
	 * PRESENCE MODULE CONTEXT
	 * 
	 * WHY: Phoenix.Presence modules have injected functions that require self() as first argument
	 * WHAT: Track when we're compiling inside a @:presence module
	 * HOW: Set flag when compiling classes with @:presence metadata, use in AST builder for method calls
	 */
	public var isInPresenceModule:Bool = false;

	/**
	 * Module dependency tracking
	 * 
	 * WHY: When generating scripts with bootstrap code (static main()), we need to
	 *      ensure dependent modules are loaded in the correct order. Elixir doesn't
	 *      automatically handle module dependencies like some languages.
	 * 
	 * WHAT: Tracks which modules each module depends on (via remote calls).
	 *       Key = module name being compiled, Value = set of modules it depends on
	 * 
	 * HOW: Populated during AST building when we generate ERemoteCall nodes.
	 *      Used by output iterator to generate a bootstrap script or combine modules.
	 */
	public var moduleDependencies:Map<String, Map<String, Bool>> = new Map();

	/**
	 * Current module being compiled
	 * Used to track dependencies for the current compilation unit
	 */
	public var currentCompiledModule:String = null;

	/**
	 * Track modules that have bootstrap code (static main())
	 * These modules need special handling for script execution
	 */
	public var modulesWithBootstrap:Array<String> = [];

	/**
	 * Track module output file paths for require generation
	 * Maps module name -> relative file path from output directory
	 */
	public var moduleOutputPaths:Map<String, String> = new Map();

	/**
	 * Track module packages for proper path resolution
	 * Maps module name -> package array (e.g., "Log" -> ["haxe"])
	 */
	public var modulePackages:Map<String, Array<String>> = new Map();

	/**
	 * Cache parsed import tables by source file path for metadata expression resolution.
	 */
	private var sourceImportResolutionCache:Map<String, {directImports:Map<String, String>, wildcardImports:Array<String>}> = new Map();

	/**
	 * Map module name -> BaseType for synthetic outputs (e.g., bootstrap files)
	 * WHY: OutputManager requires a BaseType for each DataAndFileInfo; we use the module's
	 *      BaseType combined with overrideFileName to write custom files.
	 */
	public var moduleBaseTypes:Map<String, BaseType> = new Map();

	/**
	 * Constructor - Initialize the compiler with type mapping and pattern matching systems
	 */
	public function new() {
		super();
		instance = this; // Set static instance reference
		this.typer = new reflaxe.elixir.ElixirTyper();

		// Enable source mapping if requested
		this.sourceMapOutputEnabled = Context.defined("source_map_enabled") || Context.defined("source-map");

		// Initialize the BehaviorTransformer system
		// This replaces hardcoded behavior logic with a pluggable architecture
		reflaxe.elixir.behaviors.BehaviorTransformer.initialize();
		reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer = new reflaxe.elixir.behaviors.BehaviorTransformer();

		// Preprocessors are now configured in CompilerInit.hx to ensure they aren't overridden
		// The configuration was moved because options passed to ReflectCompiler.AddCompiler
		// override anything set in the constructor
	}

	/**
	 * Macro-phase type filter for special output modes.
	 *
	 * WHAT
	 * - In `-D ecto_migrations_exs` mode, restrict emission to classes annotated with `@:migration`.
	 *
	 * WHY
	 * - Ecto loads every `.exs` in `priv/repo/migrations`. If the compiler emits non-migration
	 *   helper modules into that directory, `mix ecto.migrate` can break at runtime.
	 *
	 * HOW
	 * - Filter the already-typed module list to keep only `@:migration` classes.
	 */
	public override function filterTypes(moduleTypes:Array<haxe.macro.Type.ModuleType>):Array<haxe.macro.Type.ModuleType> {
		#if eval
		var result = moduleTypes != null ? moduleTypes.copy() : [];

		// Migration-only compilation mode:
		// When emitting `.exs` migrations, we must avoid writing non-migration helper modules
		// into `priv/repo/migrations/` (Ecto loads every `.exs` in that directory).
		// This mode is opt-in via `-D ecto_migrations_exs` and expects the build to include
		// only `@:migration` classes you want to emit.
		if (Context.defined("ecto_migrations_exs")) {
			var migrations:Array<haxe.macro.Type.ModuleType> = [];
			for (mt in result) {
				switch (mt) {
					case TClassDecl(clsRef):
						var cls = clsRef.get();
						if (cls.meta != null && cls.meta.has(":migration"))
							migrations.push(mt);
					case _:
				}
			}
			return migrations;
		}
		return result;
		#else
		return moduleTypes != null ? moduleTypes : [];
		#end
	}

	// Note: Directory scanning moved to RepoDiscovery (macro phase)

	/**
	 * Override shouldGenerateClass to enforce strict std emission policy
	 *
	 * WHY: Prevent generation of Haxe std extern implementation modules and
	 *      macro-time/compiler-time dependencies (e.g., _Any.Any_Impl_, _EnumValue.EnumValue_Impl_,
	 *      haxe.iterators.ArrayIterator, haxe._call_stack.CallStack_Impl_, StringBuf, Type, ValueType)
	 *      which pollute snapshot outputs and are not required at runtime for idiomatic Elixir.
	 * WHAT: Suppress generation for internal/std utility classes unless explicitly whitelisted by
	 *      annotations (@:coreApi, @:presence, @:application, @:native for target modules).
	 * HOW: Apply name/package based filters early, then fall back to existing allow rules.
	 */
	public override function shouldGenerateClass(classType:ClassType):Bool {
		// Suppress obvious internal/impl/iterator/std support modules
		if (shouldSuppressStdEmission(classType)) {
			return false;
		}

		// Skip internal Haxe types that shouldn't generate modules
		// Module names in Elixir must start with uppercase letters
		if (classType.name.startsWith("__") || classType.name == "___Int64") {
			return false;
		}

		// Check if this is an extern class with special annotations
		if (classType.isExtern && hasSpecialAnnotations(classType)) {
			// Force generation for extern classes with framework annotations
			return true;
		}

		// Check if this is a class with @:presence annotation
		// These need to be compiled to generate Phoenix.Presence modules
		// This includes both regular classes and @:native classes (which are extern)
		if (classType.meta.has(":presence")) {
			#if debug_behavior_transformer
			#end
			return true;
		}

		// Check if this is a @:coreApi class (like Date, Sys, etc.)
		// These need to be generated as Elixir modules
		if (classType.meta.has(":coreApi")) {
			return true;
		}

		// Ensure Phoenix component modules are always generated
		// WHY: `use AppWeb, :html` imports AppWeb.CoreComponents at runtime; Haxe DCE can't see this
		// WHAT: Force generation for classes annotated with @:component (component modules)
		if (classType.meta.has(":component")) {
			return true;
		}

		// Check if this is an @:application class
		// These need to be compiled to generate OTP application modules
		if (classType.meta.has(":application")) {
			#if debug_annotation_transforms
			#end
			return true;
		}

		// Force generation for @:endpoint classes (Phoenix Endpoint modules)
		if (classType.meta.has(":endpoint")) {
			#if debug_annotation_transforms
			#end
			return true;
		}

		// Force generation for @:router classes (Phoenix Router modules)
		if (hasClassOrStaticMetadata(classType, ":router", "router")) {
			#if debug_annotation_transforms
			#end
			return true;
		}

		// Force generation for @:phoenixWebModule classes (Phoenix Web modules)
		if (classType.meta.has(":phoenixWebModule") || classType.meta.has(":phoenixWeb")) {
			#if debug_annotation_transforms
			#end
			return true;
		}

		// Force compilation of Date class when used
		// This ensures Date module with __elixir__() implementations is available
		if (classType.name == "Date" && classType.pack.length == 0) {
			return true;
		}

		// Otherwise use default behavior
		return super.shouldGenerateClass(classType);
	}

	/**
	 * Centralized suppression rules for std and internal modules
	 */
	private function shouldSuppressStdEmission(classType:ClassType):Bool {
		switch (classType.kind) {
			case KModuleFields(_):
				// Module-level fields are compiled into synthetic KModuleFields classes
				// under underscored pseudo-packages. Do not suppress them.
				return false;
			default:
		}

		// Fast checks by name
		var n = classType.name;
		if (n == null)
			return false;

		// NOTE: Do not suppress `_Impl_` modules globally.
		// Haxe abstracts compile to `<Abstract>_Impl_` modules which contain required
		// runtime functions (e.g. PositiveInt_Impl_.parse/1). We only suppress
		// truly-internal implementations via package-level rules (e.g. haxe._*).

		// Skip packages that are compiler/macro-only or Haxe-internal
		if (classType.pack != null && classType.pack.length > 0) {
			var top = classType.pack[0];
			if (top == null)
				top = "";

			// Compiler/macro-only libs (never emit as modules)
			if (top == "reflaxe" || top == "js" || top == "genes")
				return true;

			// Haxe std: allow by default, but filter internal subpackages starting with underscore.
			// `haxe.CallStack` is an abstract whose runtime functions live in
			// `haxe._CallStack.CallStack_Impl_`, so it must be emitted once the target override is real.
			if (top == "haxe") {
				if (classType.pack.length > 1) {
					var sub = classType.pack[1];
					if (sub == "_CallStack" && classType.name == "CallStack_Impl_")
						return false;
					if (sub != null && StringTools.startsWith(sub, "_"))
						return true; // _call_stack, _constraints, _int32, etc.
				}
			}

			// Underscored pseudo-packages (e.g., _Any, _EnumValue)
			if (StringTools.startsWith(top, "_"))
				return true;

			// No additional bans beyond leading underscore
		}

		return false;
	}

	/**
	 * Get the current app name from the class being compiled
	 * 
	 * @:appName annotation is crucial for Phoenix applications because:
	 * 1. **PubSub Module Names**: Phoenix.PubSub requires app-specific module names (e.g., "TodoApp.PubSub")
	 * 2. **Telemetry Modules**: Applications need telemetry modules like "TodoAppWeb.Telemetry"
	 * 3. **Endpoint Modules**: Web endpoints are named like "TodoAppWeb.Endpoint"
	 * 4. **Supervisor Names**: OTP supervisors use app-specific names like "TodoApp.Supervisor"
	 * 
	 * Without configurable app names, all generated applications would hardcode "TodoApp"
	 * making it impossible to create multiple Phoenix apps or rename projects.
	 * 
	 * Usage: @:appName("MyApp") - generates MyApp.PubSub, MyAppWeb.Telemetry, etc.
	 */
	/**
	 * Get the original variable name before Haxe's renaming.
	 * 
	 * When Haxe renames variables to avoid shadowing (e.g., todos → todos2),
	 * the original name is preserved in Meta.RealPath metadata.
	 * This function retrieves the original name if available.
	 * 
	 * @param v The TVar to get the name from
	 * @return The original variable name or the current name if no metadata exists
	 */
	/**
	 * Get the original variable name before Haxe's internal renaming
	 * 
	 * WHY: Delegates to VariableCompiler for centralized variable name management
	 * 
	 * @param v The TVar to get the name from
	 * @return The original variable name
	 */
	public function getOriginalVarName(v:TVar):String {
		return v.getNameOrMeta(":realPath");
	}

	/**
	 * Check if an expression contains a reference to a specific variable
	 * 
	 * WHY: Delegates to VariableCompiler for centralized variable analysis
	 * 
	 * @param expr The expression to analyze
	 * @param variableName The variable name to search for
	 * @return True if the expression contains a reference to the variable
	 */
	// Pipeline analysis removed - handled by AST transformer
	// Pipeline analysis methods removed - functionality moved to AST transformer
	// containsVariableReference moved to VariableCompiler.hx

	/**
	 * Generate annotation-aware output path for framework convention adherence.
	 * 
	 * Uses framework-specific paths for annotated classes:
	 * - @:router → /lib/app_web/router.ex
	 * - @:liveview → /lib/app_web/live/class_name.ex  
	 * - @:controller → /lib/app_web/controllers/class_name.ex
	 * - @:schema → /lib/app/schemas/class_name.ex
	 * - No annotation → /lib/ClassName.ex (default 1:1 mapping)
	 */
	/**
	 * Convert PascalCase to snake_case for Elixir file naming conventions.
	 * Examples: TodoApp → todo_app, UserController → user_controller
	 */
	/**
	 * DEPRECATED: Framework-aware file relocation is now handled using Reflaxe's built-in system
	 * 
	 * Files are now placed in correct Phoenix locations during compilation using:
	 * - setOutputFileName() for custom file names 
	 * - setOutputFileDir() for custom directory paths
	 * 
	 * This approach is better because:
	 * 1. No post-compilation file moves needed
	 * 2. Integrates properly with Reflaxe's OutputManager
	 * 3. Respects Reflaxe's file tracking and cleanup
	 * 4. Works with all Reflaxe features (source maps, etc.)
	 * 
	 * See setFrameworkAwareOutputPath() for the new implementation.
	 */
	/**
	 * Convert Haxe names to Elixir naming conventions
	 * Uses NameUtils for consistency
	 */
	public function toElixirName(haxeName:String):String {
		return reflaxe.elixir.ast.NameUtils.toElixirName(haxeName);
	}

	/**
	 * Convert package.ClassName to package/class_name.ex path
	 * Examples: 
	 * - haxe.CallStack → haxe/call_stack  
	 * - TestDocClass → test_doc_class
	 * - my.nested.Module → my/nested/module
	 */
	private function convertPackageToDirectoryPath(classType:ClassType):String {
		if (classType.pack.length == 0)
			return "";

		var segments = classType.pack.map(function(segment) {
			return reflaxe.elixir.ast.NameUtils.toSnakeCase(segment);
		});

		return segments.join("/");
	}

	/**
	 * Get the output path for a module (for tracking)
	 *
	 * NOTE: For framework-aware modules (e.g. @:application), the compiler calls
	 * `setFrameworkAwareOutputPath` which computes a concrete `outputPath` and
	 * stores it in `moduleOutputPaths`. This helper is used as a fallback when
	 * no framework override exists.
	 */
	public function getModuleOutputPath(moduleName:String, pack:Array<String> = null):String {
		var fileName = reflaxe.elixir.ast.NameUtils.toSnakeCase(moduleName) + ".ex";

		if (pack != null && pack.length > 0) {
			var dirPath = pack.map(function(segment) {
				return reflaxe.elixir.ast.NameUtils.toSnakeCase(segment);
			}).join("/");
			return dirPath + "/" + fileName;
		}

		return fileName;
	}

	/**
	 * Set output path for ANY module type using the universal naming system.
	 * This ensures consistent snake_case naming for all generated files.
	 */
	private function setUniversalOutputPath(moduleName:String, pack:Array<String> = null):Void {
		// Convert module name to snake_case
		var fileName = reflaxe.elixir.ast.NameUtils.toSnakeCase(moduleName);

		// Set the output file name
		setOutputFileName(fileName);

		// Convert package to directory path if provided
		if (pack != null && pack.length > 0) {
			var dirPath = pack.map(function(segment) {
				return reflaxe.elixir.ast.NameUtils.toSnakeCase(segment);
			}).join("/");

			setOutputFileDir(dirPath);
		}
	}

	/**
	 * setFrameworkAwareOutputPath
	 *
	 * WHAT
	 * - Computes framework-specific module names and file paths for annotated
	 *   classes such as `@:application`, while delegating all other classes to
	 *   the universal snake_case naming system.
	 *
	 * WHY
	 * - Phoenix conventions expect OTP application modules like
	 *   `TodoApp.Application` to live under `lib/todo_app/application.ex`.
	 *   Previously the compiler generated correct module names via
	 *   `ModuleBuilder.extractModuleName`, but still wrote files as
	 *   `lib/todo_app.ex`, causing `TodoApp.Application` to be missing at
	 *   runtime for the todo-app.
	 *
	 * HOW
	 * - For `@:application` classes:
	 *     - Derives the app module prefix from `PhoenixMapper.getAppModuleName`
	 *       (backed by `-D app_name` / @:appName annotations).
	 *     - Sets `moduleName` to `<App>.Application`.
	 *     - Sets `outputPath` and OutputManager state to
	 *       `todo_app/application.ex` (snake_case app name + fixed filename).
	 *   All other classes:
	 *     - Use `setUniversalOutputPath` + `getModuleOutputPath` for the
	 *       existing snake_case-per-module behavior.
	 *
	 * EXAMPLES
	 * Haxe:
	 *   @:application
	 *   @:appName("TodoApp")
	 *   class TodoApp { ... }
	 *
	 * Elixir (before – buggy):
	 *   # No TodoApp.Application module generated; runtime crash at boot.
	 *
	 * Elixir (after):
	 *   # lib/todo_app/application.ex
	 *   defmodule TodoApp.Application do
	 *     use Application
	 *     def start(type, args), do: ...
	 *   end
	 */
	private function setFrameworkAwareOutputPath(classType:ClassType, moduleName:String, modulePack:Array<String>):FrameworkNamingResult {
		// Migrations: when emitting `.exs` files for Ecto, we must place them under
		// `priv/repo/migrations/` with timestamped filenames. This is opt-in and
		// expects a dedicated build that compiles only `@:migration` classes.
		if (Context.defined("ecto_migrations_exs") && classType.meta.has(":migration")) {
			var appModuleName = reflaxe.elixir.PhoenixMapper.getAppModuleName();

			var migrationName = extractStringMeta(classType, ":migrationName");
			if (migrationName == null || migrationName == "") {
				migrationName = reflaxe.elixir.ast.NameUtils.toSnakeCase(classType.name);
			}

			var migrationTimestamp = extractStringMeta(classType, ":migrationTimestamp");
			if (migrationTimestamp == null || migrationTimestamp == "") {
				Context.error('Missing migration timestamp for ${classType.name}. Add one via @:migration({timestamp: "20240101120000"}) (or generate with `mix haxe.gen.migration`).',
					classType.pos);
				migrationTimestamp = "00000000000000";
			}

			var fileStem = migrationTimestamp + "_" + migrationName;
			setOutputFileName(fileStem);
			setOutputFileDir("");

			var outputPath = fileStem + ".exs";
			return {
				moduleName: appModuleName + ".Repo.Migrations." + classType.name,
				modulePack: [],
				outputPath: outputPath
			};
		}

		// Application modules: map to lib/<app_snake>/application.ex
		if (classType.meta.has(":application")) {
			var appModuleName = reflaxe.elixir.PhoenixMapper.getAppModuleName();
			var appSnake = reflaxe.elixir.ast.NameUtils.toSnakeCase(appModuleName);

			// Final Elixir module name (TodoApp.Application)
			var finalModuleName = appModuleName + ".Application";
			var finalPack:Array<String> = [appSnake];

			// File placement: lib/todo_app/application.ex
			setOutputFileName("application");
			setOutputFileDir(appSnake);

			var outputPath = appSnake + "/application.ex";
			#if debug_annotation_transforms
			#end
			return {
				moduleName: finalModuleName,
				modulePack: finalPack,
				outputPath: outputPath
			};
		}

		// Endpoint modules: map to lib/<app_snake>_web/endpoint.ex
		if (classType.meta.has(":endpoint")) {
			var appModuleName = reflaxe.elixir.PhoenixMapper.getAppModuleName();
			var appSnake = reflaxe.elixir.ast.NameUtils.toSnakeCase(appModuleName);
			var webSnake = appSnake + "_web";

			// Final Elixir module name (TodoAppWeb.Endpoint)
			var finalModuleName = appModuleName + "Web.Endpoint";
			var finalPack:Array<String> = [webSnake];

			// File placement: lib/todo_app_web/endpoint.ex
			setOutputFileName("endpoint");
			setOutputFileDir(webSnake);

			var outputPath = webSnake + "/endpoint.ex";
			#if debug_annotation_transforms
			#end
			return {
				moduleName: finalModuleName,
				modulePack: finalPack,
				outputPath: outputPath
			};
		}

		// Router modules: map to lib/<app_snake>_web/router.ex
		if (hasClassOrStaticMetadata(classType, ":router", "router")) {
			var appModuleName = reflaxe.elixir.PhoenixMapper.getAppModuleName();
			var appSnake = reflaxe.elixir.ast.NameUtils.toSnakeCase(appModuleName);
			var webSnake = appSnake + "_web";

			// Final Elixir module name (TodoAppWeb.Router)
			var finalModuleName = appModuleName + "Web.Router";
			var finalPack:Array<String> = [webSnake];

			// File placement: lib/todo_app_web/router.ex
			setOutputFileName("router");
			setOutputFileDir(webSnake);

			var outputPath = webSnake + "/router.ex";
			#if debug_annotation_transforms
			#end
			return {
				moduleName: finalModuleName,
				modulePack: finalPack,
				outputPath: outputPath
			};
		}

		// PhoenixWeb modules: map to lib/<app_snake>_web.ex
		if (classType.meta.has(":phoenixWebModule") || classType.meta.has(":phoenixWeb")) {
			var appModuleName = reflaxe.elixir.PhoenixMapper.getAppModuleName();
			var appSnake = reflaxe.elixir.ast.NameUtils.toSnakeCase(appModuleName);

			// Final Elixir module name (TodoAppWeb)
			var finalModuleName = appModuleName + "Web";
			var finalPack:Array<String> = [];

			// File placement: lib/todo_app_web.ex (at lib root)
			setOutputFileName(appSnake + "_web");
			setOutputFileDir("");

			var outputPath = appSnake + "_web.ex";
			#if debug_annotation_transforms
			#end
			return {
				moduleName: finalModuleName,
				modulePack: finalPack,
				outputPath: outputPath
			};
		}

		// Default path: snake_case(moduleName) under snake_case(pack)
		setUniversalOutputPath(moduleName, modulePack);
		return {
			moduleName: moduleName,
			modulePack: modulePack,
			outputPath: null
		};
	}

	static inline function extractStringMeta(classType:ClassType, metaName:String):Null<String> {
		if (classType.meta == null || !classType.meta.has(metaName))
			return null;
		var entries = classType.meta.extract(metaName);
		if (entries == null || entries.length == 0)
			return null;
		var first = entries[0];
		if (first.params == null || first.params.length == 0)
			return null;
		return switch (first.params[0].expr) {
			case EConst(CString(value, _)): value;
			case EConst(CInt(value, _)): value;
			default: null;
		};
	}

	/**
	 * Resolve the Elixir function name for a generated class method.
	 *
	 * WHAT
	 * - `@:native("...")` on a method is authoritative and emitted exactly.
	 * - `@:liveview` modules normalize exact known Haxe-style callback names to Phoenix names.
	 * - All other methods keep the compiler's existing safe snake_case behavior.
	 *
	 * WHY
	 * Phoenix calls callbacks by atom name at runtime (`handle_event/3`, `handle_info/2`, etc.).
	 * Users should be able to write either canonical Elixir names or Haxe-style names without
	 * remembering boilerplate metadata, while explicit `@:native` must remain a precise escape hatch.
	 *
	 * HOW
	 * Resolve explicit native metadata first, then apply a small exact-name LiveView callback map.
	 * The map is intentionally not fuzzy: arbitrary helper names still use regular snake_case.
	 *
	 * EXAMPLES
	 * - `handleEvent` in `@:liveview` -> `handle_event`
	 * - `handleAsync` in `@:liveview` -> `handle_async`
	 * - `@:native("handle_event") function eventCallback` -> `handle_event`
	 */
	private function resolveDefinitionFunctionName(field:ClassField, classType:ClassType):String {
		if (field == null)
			return "";

		var nativeName = field.getNameOrNative();
		if (nativeName != null && nativeName != field.name)
			return nativeName;

		if (classType != null && classType.meta != null && classType.meta.has(":liveview")) {
			var callbackName = normalizeLiveViewCallbackName(field.name);
			if (callbackName != null)
				return callbackName;
		}

		return reflaxe.elixir.ast.NameUtils.toSafeElixirFunctionName(field.name);
	}

	private inline function normalizeLiveViewCallbackName(name:String):Null<String> {
		return switch (name) {
			case "mount": "mount";
			case "render": "render";
			case "handleEvent" | "handle_event": "handle_event";
			case "handleInfo" | "handle_info": "handle_info";
			case "handleParams" | "handle_params": "handle_params";
			case "handleAsync" | "handle_async": "handle_async";
			case "terminate": "terminate";
			default: null;
		};
	}

	/**
	 * Required implementation for GenericCompiler - implements class compilation
	 * @param classType The Haxe class type
	 * @param varFields Class variables
	 * @param funcFields Class functions
	 * @return ElixirAST representing the compiled module
	 */
	public function compileClassImpl(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>):Null<reflaxe.elixir.ast.ElixirAST> {
		#if debug_compilation_flow
		#end

		if (classType == null)
			return null;

		// Skip standard library/internal classes that shouldn't generate Elixir modules
		if (isStandardLibraryClass(classType.name) || shouldSuppressStdEmission(classType)) {
			#if debug_compilation_flow
			#end
			return null;
		}

		// Check for @:native annotation to determine base module name/pack
		var moduleName = classType.name;
		var modulePack = classType.pack;

		var nativeMetaEntries = collectClassAndStaticMetadata(classType, ":native", "native");

		if (nativeMetaEntries != null && nativeMetaEntries.length > 0 && nativeMetaEntries[0].params != null && nativeMetaEntries[0].params.length > 0) {
			switch (nativeMetaEntries[0].params[0].expr) {
				case EConst(CString(s, _)):
					// Parse the native module name for package and name
					var parts = s.split(".");
					if (parts.length > 1) {
						moduleName = parts[parts.length - 1];
						modulePack = parts.slice(0, parts.length - 1).map(p -> reflaxe.elixir.ast.NameUtils.toSnakeCase(p));
					} else {
						moduleName = s;
						modulePack = [];
					}
				default:
					// Keep original if annotation is malformed
			}
		}

		// Apply framework-aware naming (e.g., @:application → TodoApp.Application,
		// lib/todo_app/application.ex) while preserving default behavior for other
		// modules via the universal naming system.
		var frameworkNaming = setFrameworkAwareOutputPath(classType, moduleName, modulePack);
		moduleName = frameworkNaming.moduleName;
		modulePack = frameworkNaming.modulePack;

		// Set current module for dependency tracking using the final module name
		currentCompiledModule = moduleName;
		// Initialize dependency map for this module if not exists
		if (!moduleDependencies.exists(moduleName)) {
			moduleDependencies.set(moduleName, new Map<String, Bool>());
		}

		// Track the output path for this module. Use the framework override when
		// provided; otherwise fall back to universal naming rules.
		var outputPath = frameworkNaming.outputPath != null ? frameworkNaming.outputPath : getModuleOutputPath(moduleName, modulePack);
		moduleOutputPaths.set(moduleName, outputPath);
		// Track BaseType for synthetic outputs
		moduleBaseTypes.set(moduleName, classType);

		// Store current class context for use in expression compilation
		this.currentClassType = classType;

		// Activate behavior transformer based on class metadata
		// This replaces the old isInPresenceModule flag with a more generic system
		#if debug_behavior_transformer
		#end

		if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
			var behaviorName = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.checkAndActivateBehavior(classType);
			#if debug_behavior_transformer
			if (behaviorName != null) {} else {}
			#end
		}

		// Use AST pipeline for class compilation
		var moduleAST = buildClassAST(classType, varFields, funcFields);

		// Ensure Phoenix component modules are always emitted
		// WHAT: Classes annotated with @:component define Phoenix.Component functions
		// WHY: Phoenix apps using `use AppWeb, :html` import AppWeb.CoreComponents unconditionally
		//      Even if DCE removes unused functions, the module itself must exist at runtime
		// HOW: Mark the module AST with metadata.forceEmit so the output iterator never suppresses it
		if (classType.meta.has(":component")) {
			if (moduleAST != null) {
				if (moduleAST.metadata == null)
					moduleAST.metadata = {};
				Reflect.setField(moduleAST.metadata, "forceEmit", true);
			}
		}

		#if debug_compilation_flow
		#end

		// Return AST directly - transformation and printing handled by ElixirOutputIterator
		return moduleAST;
	}

	/**
	 * Required implementation for GenericCompiler - implements enum compilation
	 */
	public function compileEnumImpl(enumType:EnumType, options:Array<EnumOptionData>):Null<reflaxe.elixir.ast.ElixirAST> {
		if (enumType == null)
			return null;

		// Set output file path with snake_case naming
		setUniversalOutputPath(enumType.name, enumType.pack);

		// Use AST pipeline for enum compilation
		var enumAST = buildEnumAST(enumType, options);

		// Return AST directly - transformation and printing handled by ElixirOutputIterator
		return enumAST;
	}

	/**
	 * Compile expression - required by GenericCompiler (implements abstract method)
	 * 
	 * WHY: Delegates to AST builder to construct typed AST nodes
	 * WHAT: Clean entry point that routes TypedExpr compilation to AST generation
	 * HOW: Returns ElixirAST nodes that are later transformed and printed
	 */
	/**
	 * Override compileExpression to handle __elixir__ injection properly using Reflaxe's system
	 * 
	 * WHY: We need to use checkTargetCodeInjectionGeneric like other Reflaxe compilers (C#, etc.)
	 * to properly handle __elixir__() injection with the GenericCompiler base class.
	 * 
	 * WHAT: Uses Reflaxe's built-in TargetCodeInjection system for code injection
	 * 
	 * HOW: Calls checkTargetCodeInjectionGeneric and processes the results into ERaw nodes
	 */
	public override function compileExpression(expr:TypedExpr, topLevel:Bool = false):Null<reflaxe.elixir.ast.ElixirAST> {
		// Check for target code injection using Reflaxe's built-in system
		switch (expr.expr) {
			case TCall(e, args):
				// Use Reflaxe's TargetCodeInjection system like C# compiler does
				if (options.targetCodeInjectionName != null) {
					#if debug_injection
					#end

					final result = TargetCodeInjection.checkTargetCodeInjectionGeneric(options.targetCodeInjectionName, expr, this);

					#if debug_injection
					if (result == null) {} else {}
					#end

					if (result != null) {
						// Special-case: Build AST for known patterns instead of ERaw strings
						var ectoAst = tryBuildEctoWhereAST(result, expr.pos);
						if (ectoAst != null) {
							return ectoAst;
						}
						// Process the injection result as string fallback
						var finalCode = "";
						var insideString = false; // Track if we're currently inside a string literal

						#if debug_injection
						#end

						for (i in 0...result.length) {
							var entry = result[i];
							switch (entry) {
								case Left(code):
									// Direct string code - check for string delimiters
									#if debug_injection
									#end

									finalCode += code;

									// Update insideString state by counting unescaped quotes
									var j = 0;
									while (j < code.length) {
										if (code.charAt(j) == '"' && (j == 0 || code.charAt(j - 1) != '\\')) {
											insideString = !insideString;
											#if debug_injection
											#end
										}
										j++;
									}

									#if debug_injection
									#end

								case Right(ast):
									// Compiled AST - convert to string
									var astStr = reflaxe.elixir.ast.ElixirASTPrinter.printAST(ast);
									var astSubstitution = reflaxe.elixir.ast.ElixirASTPrinter.printASTForInjectionSubstitution(ast);

									#if debug_injection
									#end

									if (insideString) {
										// Inside string literal: ensure the interpolated expression is a single valid expression
										// Wrap multi-statement or assignment-heavy outputs in an IIFE inside #{...}
										var needsIife = (astStr.indexOf("\n") != -1)
											|| (astStr.indexOf("=") != -1 && astStr.indexOf("==") == -1);
										var wrapped = needsIife ? '(fn -> ' + astStr + ' end).()' : astStr;
										finalCode += '#{' + wrapped + '}';
									} else {
										// Outside string: direct substitution
										#if debug_injection
										#end
										finalCode += astSubstitution;
									}
							}
						}

						#if debug_injection
						#end

						// Return as raw Elixir code
						return reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERaw(finalCode));
					}

					// WORKAROUND: Reflaxe's checkTargetCodeInjectionGeneric only detects TIdent,
					// but Haxe sometimes types untyped __elixir__() as TField or other patterns.
					// Manually check for __elixir__ in TField, TLocal, etc.
					var isInjectionCall = switch (e.expr) {
						case TIdent(id): id == options.targetCodeInjectionName;
						case TField(_, fa):
							switch (fa) {
								case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
									cf.get().name == options.targetCodeInjectionName;
								case FEnum(_, ef):
									ef.name == options.targetCodeInjectionName;
								case FDynamic(s):
									s == options.targetCodeInjectionName;
							}
						case TLocal(v): v.name == options.targetCodeInjectionName;
						case _: false;
					};

					#if debug_injection
					if (isInjectionCall) {}
					#end

					if (isInjectionCall && args.length > 0) {
						// Manual injection processing (same as Reflaxe's algorithm)
						final injectionString:String = switch (args[0].expr) {
							case TConst(TString(s)): s;
							case _: "";
						};

						if (injectionString != "") {
							#if debug_injection
							#end

							// Try Ecto where AST build from manual path
							if (injectionString.indexOf("Ecto.Query.where") != -1
								&& injectionString.indexOf("[t]") != -1
								&& args.length >= 3) {
								var queryAst = compileExpression(args[1]);
								var rhsAst = compileExpression(args[2]);
								if (queryAst != null && rhsAst != null) {
									var rx = ~/\[t\]\s*,\s*t\.([a-zA-Z0-9_]+)\s*(==|!=|<=|>=|<|>)\s*\^\(/;
									if (rx.match(injectionString)) {
										var fieldName = rx.matched(1);
										var opStr = rx.matched(2);
										var binding = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EList([
											reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("t"))
										]));
										var rhsStr = reflaxe.elixir.ast.ElixirASTPrinter.printAST(rhsAst);
										var condition = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERaw('t.' + fieldName
											+ ' ' + opStr + ' ^(' + rhsStr + ')'));
										var whereCall = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERemoteCall(reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("Ecto.Query")),
											"where",
											[queryAst, binding, condition]));
										return whereCall;
									}
								}
							}

							// Build finalCode by processing character by character
							var finalCode = "";
							var insideString = false;
							var i = 0;

							while (i < injectionString.length) {
								var char = injectionString.charAt(i);

								// Track string state
								if (char == '"' && (i == 0 || injectionString.charAt(i - 1) != '\\')) {
									insideString = !insideString;
									finalCode += char;
									i++;
									continue;
								}

								// Check for {N} placeholder
								if (char == '{' && i + 1 < injectionString.length) {
									var j = i + 1;
									var numStr = "";

									// Collect digits
									while (j < injectionString.length && injectionString.charAt(j) >= '0' && injectionString.charAt(j) <= '9') {
										numStr += injectionString.charAt(j);
										j++;
									}

									// Check if we found a valid placeholder like {0}, {1}, etc.
									if (numStr != "" && j < injectionString.length && injectionString.charAt(j) == '}') {
										final num = Std.parseInt(numStr);
										if (num != null && num + 1 < args.length) {
											// Compile the argument
											var argAst = compileExpression(args[num + 1]);
											if (argAst != null) {
												var argStr = reflaxe.elixir.ast.ElixirASTPrinter.printAST(argAst);
												var argSubstitution = reflaxe.elixir.ast.ElixirASTPrinter.printASTForInjectionSubstitution(argAst);

												#if debug_injection
												#end

												if (insideString) {
													// Inside string: wrap in #{...} for interpolation
													finalCode += '#{$argStr}';
												} else {
													// Outside string: direct substitution
													finalCode += argSubstitution;
												}

												// Skip past the placeholder
												i = j + 1;
												continue;
											}
										}
									}
								}

								// Regular character - just append
								finalCode += char;
								i++;
							}

							#if debug_injection
							#end

							return reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERaw(finalCode));
						}
					}
				}
			case _:
		}

		// Not an injection, use normal compilation
		return super.compileExpression(expr, topLevel);
	}

	/**
	 * Attempts to build a typed ElixirAST for Ecto.Query.where injection patterns.
	 * Recognizes strings generated by TypedQueryLambda where code looks like:
	 * (require Ecto.Query; Ecto.Query.where({0}, [t], t.<field> <op> ^({1})))
	 */
	private function tryBuildEctoWhereAST(result:Array<haxe.ds.Either<String, reflaxe.elixir.ast.ElixirAST>>,
			?pos:haxe.macro.Expr.Position):Null<reflaxe.elixir.ast.ElixirAST> {
		if (result == null)
			return null;
		// Concatenate string parts and capture first two AST args ({0} and {1})
		var code = new StringBuf();
		var queryAst:Null<reflaxe.elixir.ast.ElixirAST> = null;
		var rhsAst:Null<reflaxe.elixir.ast.ElixirAST> = null;
		for (entry in result)
			switch (entry) {
				case Left(s):
					code.add(s);
				case Right(ast):
					if (queryAst == null)
						queryAst = ast;
					else if (rhsAst == null)
						rhsAst = ast;
			}
		var s = code.toString();
		#if debug_injection
		#end
		// Fast check: contains Ecto.Query.where and [t]
		if (s.indexOf("Ecto.Query.where") == -1 || s.indexOf("[t]") == -1)
			return null;
		// Extract field and operator in pattern: [t], t.<field> <op> ^(
		var fieldName:String = null;
		var opStr:String = null;
		var rx = ~/\[t\]\s*,\s*t\.([a-zA-Z0-9_]+)\s*(==|!=|<=|>=|<|>)\s*\^\(/;
		if (rx.match(s)) {
			fieldName = rx.matched(1);
			opStr = rx.matched(2);
		} else {
			#if debug_injection
			#end
			return null;
		}
		if (queryAst == null || rhsAst == null)
			return null;
		// Build AST: Ecto.Query.where(queryAst, [t], t.field <op> ^(rhs))
		var mod = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERemoteCall(reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("Kernel")),
			"require", [
			reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("Ecto.Query"))
		]));
		// We do not emit explicit require; compiler can add imports elsewhere.
		var binding = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EList([
			reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("t"))
		]));
		// Build condition as structured AST to enable downstream analysis (no ERaw)
		var lhsField = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EField(reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("t")),
			fieldName));
		inline function toOp(op:String):reflaxe.elixir.ast.ElixirAST.EBinaryOp {
			return switch (op) {
				case "==": reflaxe.elixir.ast.ElixirAST.EBinaryOp.Equal;
				case "!=": reflaxe.elixir.ast.ElixirAST.EBinaryOp.NotEqual;
				case "<": reflaxe.elixir.ast.ElixirAST.EBinaryOp.Less;
				case "<=": reflaxe.elixir.ast.ElixirAST.EBinaryOp.LessEqual;
				case ">": reflaxe.elixir.ast.ElixirAST.EBinaryOp.Greater;
				case ">=": reflaxe.elixir.ast.ElixirAST.EBinaryOp.GreaterEqual;
				default: reflaxe.elixir.ast.ElixirAST.EBinaryOp.Equal; // conservative fallback
			};
		}
		var pinnedRhs = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EPin(rhsAst));
		var condition = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EBinary(toOp(opStr), lhsField, pinnedRhs));
		var whereCall = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERemoteCall(reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("Ecto.Query")),
			"where", [queryAst, binding, condition]));
		return whereCall;
	}

	/**
	 * Creates a properly initialized CompilationContext
	 *
	 * WHY: Centralizes context creation to ensure all contexts have proper initialization
	 * including feature flags and supporting helpers.
	 *
	 * WHAT: Creates a fresh CompilationContext for a compilation unit.
	 *
	 * HOW: Initializes context, wires compiler references, and applies feature toggles.
	 */
	private function createCompilationContext():CompilationContext {
		var context = new CompilationContext();
		context.compiler = this;

		// Check if we're compiling within an ExUnit test class
		// This enables proper handling of instance variables in test methods
		if (currentClassType != null && currentClassType.meta.has(":exunit")) {
			context.isInExUnitTest = true;
			#if debug_exunit
			#end
		}

		// Initialize behavior transformer
		if (context.behaviorTransformer == null) {
			context.behaviorTransformer = new reflaxe.elixir.behaviors.BehaviorTransformer();
		}

		// Initialize feature flags from compiler defines
		initializeFeatureFlags(context);

		return context;
	}

	/**
	 * Initialize feature flags from compiler defines (-D flags)
	 *
	 * WHY: Allow users to enable/disable features via command line without
	 * code changes. Critical for gradual migration and testing.
	 *
	 * WHAT: Reads specific -D defines and sets corresponding feature flags
	 * in the compilation context.
	 *
	 * HOW: Check for known feature defines and set them in the context
	 *
	 * Examples:
	 * - -D elixir.feature.new_module_builder=true
	 * - -D elixir.feature.loop_builder_enabled=true
	 * - -D elixir.feature.idiomatic_comprehensions=true
	 */
	private function initializeFeatureFlags(context:CompilationContext):Void {
		// Check for individual feature flags
		if (haxe.macro.Context.defined("elixir.feature.new_module_builder")) {
			var value = haxe.macro.Context.definedValue("elixir.feature.new_module_builder");
			context.setFeatureFlag("new_module_builder", value != "false");
		}

		// Enable loop_builder by default - can be disabled with -D elixir.feature.loop_builder_enabled=false
		if (haxe.macro.Context.defined("elixir.feature.loop_builder_enabled")) {
			var value = haxe.macro.Context.definedValue("elixir.feature.loop_builder_enabled");
			context.setFeatureFlag("loop_builder_enabled", value != "false");
		} else {
			// Default to enabled for better loop generation
			context.setFeatureFlag("loop_builder_enabled", true);
		}

		if (haxe.macro.Context.defined("elixir.feature.idiomatic_comprehensions")) {
			var value = haxe.macro.Context.definedValue("elixir.feature.idiomatic_comprehensions");
			context.setFeatureFlag("idiomatic_comprehensions", value != "false");
		}

		if (haxe.macro.Context.defined("elixir.feature.pattern_extraction")) {
			var value = haxe.macro.Context.definedValue("elixir.feature.pattern_extraction");
			context.setFeatureFlag("pattern_extraction", value != "false");
		}

		// Global flag to enable all experimental features
		if (haxe.macro.Context.defined("elixir.feature.experimental")) {
			var value = haxe.macro.Context.definedValue("elixir.feature.experimental");
			if (value != "false") {
				context.setFeatureFlag("new_module_builder", true);
				context.setFeatureFlag("loop_builder_enabled", true);
				context.setFeatureFlag("idiomatic_comprehensions", true);
				context.setFeatureFlag("pattern_extraction", true);
			}
		}

		// Debug flag to print enabled features
		#if debug_feature_flags
		for (key in context.astContext.featureFlags.keys()) {}
		#end
	}

	/**
	 * Implement the required abstract method for expression compilation
	 *
	 * WHY: Reflaxe's GenericCompiler calls this to compile individual expressions.
	 * This is the correct integration point for our AST pipeline.
	 * Function boundary detection enables persistent context for variable naming consistency.
	 *
	 * WHAT: Builds AST for individual expressions, with function boundary detection
	 *
	 * HOW: Detects TFunction boundaries and delegates to compileFunctionWithPersistentContext()
	 *      for function-scoped transformation contexts. Other expressions use standard flow.
	 */
	public function compileExpressionImpl(expr:TypedExpr, topLevel:Bool):Null<reflaxe.elixir.ast.ElixirAST> {
		// CRITICAL: Function boundary detection for persistent context
		// WHY: Functions need persistent nameMapping across all statements in their body
		// WHAT: TFunction indicates function definition with parameters and body
		// HOW: Delegate to specialized method that maintains context across statements
		switch (expr.expr) {
			case TFunction(f):
				return compileFunctionWithPersistentContext(expr, f, topLevel);
			default:
				// Standard compilation flow for non-function expressions
		}

		// Create a fresh compilation context for this expression
		// This ensures complete isolation between compilation units during parallel execution
		var context = createCompilationContext();

		// CRITICAL: Preprocess TypedExpr to eliminate infrastructure variables FIRST
		// This must happen BEFORE any other processing to ensure clean patterns
		expr = reflaxe.elixir.preprocessor.TypedExprPreprocessor.preprocess(expr);

		// Capture infrastructure-variable substitutions produced by the TypedExpr preprocessor.
		// Some builders recompile sub-expressions and need ID-based substitutions available.
		context.infraVarSubstitutions = reflaxe.elixir.preprocessor.TypedExprPreprocessor.getLastSubstitutions();

		// Build AST for the expression with compilation context
		// Pass context as second parameter to ensure isolated state
		var ast = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);

		// Apply transformations to all expressions, not just function bodies
		// Pass context to transformer as well
		if (ast != null) {
			var originalAstId = Std.string(ast);
			var transformedAst = reflaxe.elixir.ast.ElixirASTTransformer.transform(ast, context);
			var transformedAstId = Std.string(transformedAst);

			ast = transformedAst;
		}

		return ast;
	}

	/**
	 * Compile function with persistent transformation context
	 *
	 * WHY: Variable renames must be consistent across all statements in a function body.
	 *      Previous approach created fresh context per expression, losing nameMapping.
	 *
	 * WHAT: Compiles function with single parent context shared across all body statements
	 *
	 * HOW:
	 * 1. Create function-scoped parent context
	 * 2. Process function body by preprocessing and analyzing usage
	 * 3. Build AST using the persistent context
	 * 4. Apply transformations with the same context
	 * 5. Return completed function AST
	 *
	 * @param expr The complete TFunction expression
	 * @param f The TFunc structure containing parameters and body
	 * @param topLevel Whether this is a top-level function
	 * @return ElixirAST node for the function
	 */
	function compileFunctionWithPersistentContext(expr:TypedExpr, f:haxe.macro.Type.TFunc, topLevel:Bool):Null<reflaxe.elixir.ast.ElixirAST> {
		// Create function-scoped parent context that persists across all statements
		var functionContext = createCompilationContext();

		// Preprocess the entire function expression
		var preprocessedExpr = reflaxe.elixir.preprocessor.TypedExprPreprocessor.preprocess(expr);

		// Capture infrastructure-variable substitutions produced by the TypedExpr preprocessor.
		functionContext.infraVarSubstitutions = reflaxe.elixir.preprocessor.TypedExprPreprocessor.getLastSubstitutions();

		// Build AST using the function-scoped context
		// The builder will process parameters and create the function structure
		var ast = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(preprocessedExpr, functionContext);

		// Apply transformations with the persistent context
		// This ensures nameMapping from parameters flows into body
		if (ast != null) {
			var transformedAst = reflaxe.elixir.ast.ElixirASTTransformer.transform(ast, functionContext);
			ast = transformedAst;
		}

		return ast;
	}

	/**
	 * Generate output iterator for converting AST to strings
	 * 
	 * WHY: GenericCompiler produces AST nodes, but Reflaxe needs strings for file output
	 * WHAT: Returns an iterator that processes all compiled AST nodes
	 * HOW: Delegates to ElixirOutputIterator which handles transformation and printing
	 */
	public function generateOutputIterator():Iterator<DataAndFileInfo<StringOrBytes>> {
		return new ElixirOutputIterator(this);
	}

	/**
	 * Get modules sorted by dependency order (topological sort)
	 * 
	 * WHY: When generating scripts with bootstrap code, modules must be loaded
	 *      in dependency order to avoid "module not found" errors.
	 * 
	 * WHAT: Returns a list of module names sorted so that dependencies come before
	 *       modules that depend on them.
	 * 
	 * HOW: Simple topological sort - modules with no dependencies first,
	 *      then modules that only depend on already-sorted modules.
	 * 
	 * @return Array of module names in dependency order
	 */
	public function getSortedModules():Array<String> {
		var sorted:Array<String> = [];
		var remaining = new Map<String, Bool>();

		// Collect all modules
		for (moduleName in moduleDependencies.keys()) {
			remaining.set(moduleName, true);
		}

		// Keep adding modules that have all dependencies satisfied
		while (remaining.keys().hasNext()) {
			var added = false;
			for (moduleName in remaining.keys()) {
				var deps = moduleDependencies.get(moduleName);
				var canAdd = true;

				// Check if all dependencies are already in sorted list
				if (deps != null) {
					for (dep in deps.keys()) {
						if (remaining.exists(dep)) {
							canAdd = false;
							break;
						}
					}
				}

				if (canAdd) {
					sorted.push(moduleName);
					remaining.remove(moduleName);
					added = true;
				}
			}

			// Break if we can't add any more (circular dependencies)
			if (!added) {
				// Debug trace for circular dependency detection
				#if debug_module_sorting
				#end

				// Add remaining modules anyway to avoid infinite loop
				for (moduleName in remaining.keys()) {
					sorted.push(moduleName);
				}

				// CRITICAL FIX: Clear the remaining map to actually exit the while loop
				remaining.clear();
				break;
			}
		}

		return sorted;
	}

	/**
	 * Check if a class has special annotations that need framework-specific handling
	 */
	function hasSpecialAnnotations(classType:ClassType):Bool {
		return classType.meta.has(":endpoint")
			|| classType.meta.has(":liveview")
			|| classType.meta.has(":schema")
			|| classType.meta.has(":repo")
			|| classType.meta.has(":dbTypes")
			|| classType.meta.has(":postgrexTypes")
			|| classType.meta.has(":gettext")
			|| classType.meta.has(":application")
			|| classType.meta.has(":genserver")
			|| hasClassOrStaticMetadata(classType, ":router", "router")
			|| classType.meta.has(":controller")
			|| classType.meta.has(":presence")
			|| classType.meta.has(":phoenixWeb")
			|| classType.meta.has(":phoenixWebModule")
			|| classType.meta.has(":exunit")
			|| classType.meta.has(":coreApi"); // Include @:coreApi classes like Date
	}

	/**
	 * Discover dependencies by pre-compiling function bodies
	 * 
	 * WHY: Dependencies are tracked when ERemoteCall nodes are generated during function compilation.
	 *      We need to discover these before building the module structure.
	 * 
	 * WHAT: Compiles all function bodies to trigger dependency tracking without generating output
	 * 
	 * HOW: Iterates through all functions and compiles their expressions, which populates
	 *      the moduleDependencies map as a side effect of trackDependency() calls
	 */
	function discoverDependencies(classType:ClassType, funcFields:Array<ClassField>):Void {
		#if debug_compilation_flow
		#end

		// Activate behavior transformer for dependency discovery
		// This replaces the old isInPresenceModule flag with a generic system
		var previousBehavior:Null<String> = null;
		if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
			previousBehavior = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.activeBehavior;
			var behaviorName = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.checkAndActivateBehavior(classType);
			#if debug_behavior_transformer
			if (behaviorName != null) {}
			#end
		}

		// Set compiler reference for dependency tracking
		reflaxe.elixir.ast.ElixirASTBuilder.compiler = this;

		// Compile each function body to discover dependencies
		for (func in funcFields) {
			var funcExpr = func.expr();
			if (funcExpr != null) {
				// Compile the function body - this triggers dependency tracking
				// We don't need the result, just the side effect of tracking
				switch (funcExpr.expr) {
					case TFunction(tfunc):
						if (tfunc.expr != null) {
							// Create context for dependency tracking
							var context = createCompilationContext();
							context.currentClass = classType;
							context.currentFunction = func;
							context.setCurrentPosition(func.pos);

							// Initialize behavior transformer if needed
							if (context.behaviorTransformer == null) {
								context.behaviorTransformer = new reflaxe.elixir.behaviors.BehaviorTransformer();
							}

							// CRITICAL: Preprocess function body to eliminate infrastructure variables
							tfunc.expr = reflaxe.elixir.preprocessor.TypedExprPreprocessor.preprocess(tfunc.expr);

							// Capture infrastructure-variable substitutions produced by the TypedExpr preprocessor.
							context.infraVarSubstitutions = reflaxe.elixir.preprocessor.TypedExprPreprocessor.getLastSubstitutions();

							// Build AST which triggers dependency tracking
							reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr, context);
						}
					default:
						// Not a function, skip
				}
			}
		}

		#if debug_dependencies
		var deps = moduleDependencies.get(currentCompiledModule);
		if (deps != null) {}
		#end

		// Restore previous behavior state
		if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
			reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.activeBehavior = previousBehavior;
		}

		#if debug_compilation_flow
		#end
	}

	/**
	 * Build AST for a class (generates Elixir module)
	 */
	function buildClassAST(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>):Null<reflaxe.elixir.ast.ElixirAST> {
		#if debug_behavior_transformer
		#end

		// Skip built-in types and std/internal classes that shouldn't generate modules
		if (isBuiltinAbstractType(classType.name) || isStandardLibraryClass(classType.name) || shouldSuppressStdEmission(classType)) {
			return null;
		}

		#if (macro && debug_migration_build)
		if (Context.defined("ecto_migrations_exs") && classType.meta != null && classType.meta.has(":migration")) {
			Sys.println('[MigrationBuild] '
				+ classType.module
				+ '.'
				+ classType.name
				+ ' funcFields='
				+ (funcFields != null ? Std.string(funcFields.length) : "null"));
			if (funcFields != null) {
				for (funcData in funcFields) {
					var hasBody = funcData != null && funcData.expr != null;
					Sys.println('  - ' + funcData.field.name + ' hasBody=' + (hasBody ? "true" : "false"));
				}
			}
		}
		#end

		// Activate behavior transformer if this class has a behavior annotation
		// This ensures that when the class's methods are compiled, the behavior transformer
		// is active and can inject self() or other behavior-specific transformations
		var previousBehavior:Null<String> = null;
		if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
			previousBehavior = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.activeBehavior;
			var behaviorName = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.checkAndActivateBehavior(classType);
			#if debug_behavior_transformer
			if (behaviorName != null) {} else {}
			#end
		}

		// Special-case: Generate Gettext module skeletons from @:gettext classes
		if (classType.meta.has(":gettext")) {
			var moduleName = reflaxe.elixir.ast.builders.ModuleBuilder.extractModuleName(classType);
			// Determine otp_app from module prefix before "Web" when available (TodoAppWeb.* → :todo_app)
			var appPrefix:Null<String> = null;
			var webIdx = moduleName.indexOf("Web");
			if (webIdx > 0)
				appPrefix = moduleName.substr(0, webIdx);
			if (appPrefix == null || appPrefix.length == 0) {
				try
					appPrefix = reflaxe.elixir.PhoenixMapper.getAppModuleName()
				catch (e) {}
			}
			if (appPrefix == null || appPrefix.length == 0)
				appPrefix = classType.name; // conservative fallback
			var appAtom = reflaxe.elixir.ast.NameUtils.toSnakeCase(appPrefix);
			// Build: defmodule <Module> do\n  use Gettext.Backend, otp_app: :app\nend
			var useStmt = reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EUse("Gettext.Backend", [
				reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EKeywordList([
					{
						key: "otp_app",
						value: reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EAtom(appAtom))
					}
				]))
			]));
			var mod = {
				def: reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EDefmodule(moduleName, {
					def: reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EBlock([useStmt]),
					metadata: {},
					pos: classType.pos
				}),
				metadata: {},
				pos: classType.pos
			};
			// Ensure this is emitted even if empty of functions
			Reflect.setField(mod.metadata, "forceEmit", true);
			return mod;
		}

		// ALWAYS use ModuleBuilder for ALL other classes to eliminate duplication
		// All classes go through ModuleBuilder now for consistency

		#if debug_module_builder
		#end

		// PASS 1: Discover dependencies by pre-compiling function bodies
		// This populates the moduleDependencies map before we build the module
		// Extract ClassField array from ClassFuncData array for discoverDependencies
		var funcClassFields = funcFields.map(fd -> fd.field);
		discoverDependencies(classType, funcClassFields);

		// PASS 2: Build the module with discovered dependencies
		// Set compiler reference for dependency tracking and bootstrap generation
		reflaxe.elixir.ast.ElixirASTBuilder.compiler = this;

		// Create a compilation context for this class
		var context = createCompilationContext();

		// Set current class in context for same-module optimization
		context.currentClass = classType;

		// Collect instance field names (snake_case) for this class *including inherited fields*.
		// Used to avoid parameter/field naming collisions and to drive instance-field lowering.
		var instanceFieldNames:Map<String, Bool> = new Map();
		for (snakeFieldName in collectInstanceVarSnakeNames(classType)) {
			instanceFieldNames.set(snakeFieldName, true);
		}

		// Build fields from the funcFields parameter (which is already ClassFuncData array)
		var fields:Array<reflaxe.elixir.ast.ElixirAST> = [];

		inline function ast(def:ElixirASTDef):reflaxe.elixir.ast.ElixirAST {
			return reflaxe.elixir.ast.ElixirAST.makeAST(def);
		}

		// --------------------------------------------------------------------
		// Static variable backing store (process-local)
		//
		// Haxe static vars are mutable and global in their target runtime. Elixir has
		// no mutable module-level state, so we emulate statics using the process
		// dictionary. This provides:
		// - Correct semantics within a process (including ExUnit test isolation)
		// - No global ETS/Agent lifecycle requirements
		//
		// NOTE: This is intentionally process-local; cross-process shared state should
		// be modeled explicitly (GenServer/Agent/ETS) in user code.
		// --------------------------------------------------------------------
		if (varFields != null) {
			var staticVars:Array<{name:String, init:reflaxe.elixir.ast.ElixirAST}> = [];
			var isRouterModule = hasClassOrStaticMetadata(classType, ":router", "router");
			var isRouterModuleFieldCarrier = isRouterModule && switch (classType.kind) {
				case KModuleFields(_):
					true;
				default:
					false;
			};

			for (varData in varFields) {
				if (!varData.isStatic)
					continue;
				// Module-level router declarations use static fields as compile-time configuration only.
				// Do not emit runtime static accessors for synthetic KModuleFields router carriers.
				if (isRouterModuleFieldCarrier)
					continue;
				// Module-level `final routes = [...]` is router configuration input and should not
				// emit runtime static accessor functions in generated router modules.
				if (isRouterModule && varData.field.name == "routes")
					continue;

				var elixirName = reflaxe.elixir.ast.NameUtils.toSnakeCase(varData.field.name);
				var initExpr:Null<TypedExpr> = null;

				try
					initExpr = varData.field.expr()
				catch (e) {}
				if (initExpr == null) {
					var untypedDefault = varData.getDefaultUntypedExpr();
					if (untypedDefault != null) {
						try
							initExpr = Context.typeExpr(untypedDefault)
						catch (e) {}
					}
				}

				var initAst = if (initExpr != null) {
					initExpr = reflaxe.elixir.preprocessor.TypedExprPreprocessor.preprocess(initExpr);
					reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(initExpr, context);
				} else {
					ast(ENil);
				};

				staticVars.push({name: elixirName, init: initAst});
			}

			if (staticVars.length > 0) {
				// Internal helpers:
				// - __haxe_static_key__/1: {:__haxe_static__, __MODULE__, key}
				// - __haxe_static_get__/2: read-or-init
				// - __haxe_static_put__/2: write
				// Plus per-var wrappers: var/0 + var/1

				var staticNs = ast(EAtom("__haxe_static__"));
				var setTag = ast(EAtom("set"));
				var selfModule = ast(EVar(reflaxe.elixir.ast.builders.ModuleBuilder.extractModuleName(classType)));

				function buildStaticKeyExpr(keyAtom:reflaxe.elixir.ast.ElixirAST):reflaxe.elixir.ast.ElixirAST {
					return ast(ETuple([staticNs, selfModule, keyAtom]));
				}

				// __haxe_static_get__(key, init)
				var getKeyPat:EPattern = PVar("key");
				var getInitPat:EPattern = PVar("init");
				var getKeyVar = ast(EVar("key"));
				var getInitVar = ast(EVar("init"));
				var getStaticKeyVar = ast(EVar("static_key"));
				var getValueVar = ast(EVar("value"));

				var getBody = ast(EBlock([
					ast(EMatch(PVar("static_key"), buildStaticKeyExpr(getKeyVar))),
					ast(ECase(ast(ERemoteCall(ast(EVar("Process")), "get", [getStaticKeyVar])), [
						{
							pattern: PTuple([PLiteral(setTag), PVar("value")]),
							body: getValueVar
						},
						{
							pattern: PLiteral(ast(ENil)),
							body: ast(EBlock([
								ast(EMatch(PVar("value"), getInitVar)),
								ast(ERemoteCall(ast(EVar("Process")), "put", [getStaticKeyVar, ast(ETuple([setTag, getValueVar]))])),
								getValueVar
							]))
						}
					]))
				]));

				fields.push(ast(EDefp("__haxe_static_get__", [getKeyPat, getInitPat], null, getBody)));

				// __haxe_static_put__(key, value)
				var putKeyPat:EPattern = PVar("key");
				var putValuePat:EPattern = PVar("value");
				var putKeyVar = ast(EVar("key"));
				var putValueVar = ast(EVar("value"));
				var putStaticKeyVar = ast(EVar("static_key"));
				var putBody = ast(EBlock([
					ast(EMatch(PVar("static_key"), buildStaticKeyExpr(putKeyVar))),
					ast(ERemoteCall(ast(EVar("Process")), "put", [putStaticKeyVar, ast(ETuple([setTag, putValueVar]))])),
					putValueVar
				]));

				fields.push(ast(EDefp("__haxe_static_put__", [putKeyPat, putValuePat], null, putBody)));

				// Per-static-var wrappers (public) for local + remote reads/writes:
				// def var(), do: __haxe_static_get__(:var, <init>)
				// def var(value), do: __haxe_static_put__(:var, value)
				for (sv in staticVars) {
					var keyAtom = ast(EAtom(sv.name));
					var getCall = ast(ECall(null, "__haxe_static_get__", [keyAtom, sv.init]));
					fields.push(ast(EDef(sv.name, [], null, getCall)));

					var setCall = ast(ECall(null, "__haxe_static_put__", [keyAtom, ast(EVar("value"))]));
					fields.push(ast(EDef(sv.name, [PVar("value")], null, setCall)));
				}
			}
		}

		// Compile each function field
		for (funcData in funcFields) {
			var isConstructor = funcData.field.name == "new";

			// Skip functions without body - they might be extern or abstract
			var expr = funcData.expr;
			if (expr == null)
				continue;

			// IMPORTANT: tempVarRenameMap must be function-scoped.
			// We store both ID-based and NAME-based keys in this map (for declaration/reference
			// alignment). If we reuse it across functions, NAME-based entries can leak and cause
			// cross-function renames (e.g. `page` references rewritten to `per_page` in an
			// unrelated function). Keep the map isolated per function body compilation.
			var previousTempVarRenameMap = context.tempVarRenameMap;
			context.tempVarRenameMap = new Map();
			// Infrastructure-var init tracking is also name-keyed (g/_g/etc) and must be
			// function-scoped to avoid cross-function leakage when Haxe reuses temp names.
			var previousInfraVarInitValues = context.infrastructureVarInitValues;
			context.infrastructureVarInitValues = new Map();
			// Local-var init tracking must also be function-scoped (TVar.id is not guaranteed
			// globally unique across independent TypedExpr trees).
			var previousLocalVarInitValuesById = context.localVarInitValuesById;
			context.localVarInitValuesById = new Map();
			// Preprocessor substitutions are TVar.id-keyed but IDs are not guaranteed globally
			// unique across independent TypedExpr trees. Keep substitutions scoped per function.
			var previousInfraVarSubstitutions = context.infraVarSubstitutions;
			context.infraVarSubstitutions = new Map();
			// Loop control state must not leak across functions (break/continue context).
			var previousLoopControlStateStack = context.loopControlStateStack;
			context.loopControlStateStack = [];
			// Reset anonymous temp naming per function for deterministic output.
			var previousAnonymousTempVarCounter = context.anonymousTempVarCounter;
			context.anonymousTempVarCounter = 0;

			// Track current function for method-level metadata checks (e.g. HXX escape hatches).
			var previousCurrentFunction = context.currentFunction;
			context.currentFunction = funcData.field;

			try {
				// Preprocess the function body to eliminate infrastructure variables
				expr = reflaxe.elixir.preprocessor.TypedExprPreprocessor.preprocess(expr);
				// Capture infrastructure-variable substitutions produced by the preprocessor for
				// any builder paths that recompile sub-expressions by TVar.id.
				context.infraVarSubstitutions = reflaxe.elixir.preprocessor.TypedExprPreprocessor.getLastSubstitutions();

				#if debug_ast_builder
				if (expr != null) {
					switch (expr.expr) {
						case TReturn(e) if (e != null):
							switch (e.expr) {
								case TSwitch(_, cases, _):
								case TLocal(v):
								default:
							}
						case TBlock(exprs):
							if (exprs.length > 0) {
								var last = exprs[exprs.length - 1];
							}
						default:
					}
				}
				#end

				// Check if this is an ExUnit test method FIRST
				// ExUnit test methods are special - they're NOT instance methods
				// even if they appear to be in the Haxe class structure
				// Note: In some cases, metadata is stored with the colon prefix (":test")
				// Check both with and without colon to be safe
				var isExUnitTestMethod = funcData.field.meta.has("test")
					|| funcData.field.meta.has("setup")
					|| funcData.field.meta.has("setupAll")
					|| funcData.field.meta.has("teardown")
					|| funcData.field.meta.has("teardownAll")
					|| funcData.field.meta.has(":test")
					|| funcData.field.meta.has(":setup")
					|| funcData.field.meta.has(":setupAll")
					|| funcData.field.meta.has(":teardown")
					|| funcData.field.meta.has(":teardownAll");

				#if debug_exunit
				// Let's see what metadata IS present
				if (funcData.field.name.indexOf("test") == 0) {
					var metaList = [];
					for (m in funcData.field.meta.get()) {
						metaList.push(m.name);
					}
				}
				#end

				// Set method context for instance methods
				// Instance methods need a struct parameter in Elixir
				var isStaticMethod = funcData.isStatic;

				if (isExUnitTestMethod) {
					// ExUnit test functions are standalone, not methods on a struct
					// They don't have access to instance variables via 'this'
					context.isInClassMethodContext = false;
					context.currentReceiverParamName = null;
					context.isInExUnitTest = true;
					#if debug_exunit
					#end
				} else {
					// Regular method handling
					context.isInClassMethodContext = !isStaticMethod;
					context.isInExUnitTest = false;

					// For instance methods, set the receiver parameter name to "struct"
					if (!isStaticMethod) {
						context.currentReceiverParamName = "struct";
					} else {
						context.currentReceiverParamName = null;
					}
				}

				// Populate tempVarRenameMap for function parameters BEFORE building the body
				// This fixes the issue where parameters with numeric suffixes (like options2)
				// aren't mapped correctly in the function body
				//
				// ALSO: Mark function parameter IDs in the compilation context so builder heuristics
				// (e.g. enum-index pattern recovery) can distinguish true function params from
				// pattern payload binders. This prevents incorrect binder selection like
				// `{:error, default_value} -> default_value` when the body simply references a
				// function parameter.
				var functionParameterIdKeys:Array<String> = [];
				if (funcData.tfunc != null) {
					#if debug_variable_renaming
					#end

					for (arg in funcData.tfunc.args) {
						var originalName = arg.v.name;
						var idKey = Std.string(arg.v.id);
						functionParameterIdKeys.push(idKey);
						context.functionParameterIds.set(idKey, true);

						#if debug_variable_renaming
						#end

						// Check if parameter has numeric suffix that indicates shadowing
						var strippedName = originalName;
						var renamedPattern = ~/^(.+?)(\d+)$/;
						if (renamedPattern.match(originalName)) {
							var baseWithoutSuffix = renamedPattern.matched(1);
							var suffix = renamedPattern.matched(2);

							// Only strip suffix for common field names
							var commonFieldNames = [
								"options",
								"columns",
								"name",
								"value",
								"type",
								"data",
								"fields",
								"items",
								"priority"
							];
							if ((suffix == "2" || suffix == "3") && commonFieldNames.indexOf(baseWithoutSuffix) >= 0) {
								strippedName = baseWithoutSuffix;

								#if debug_variable_renaming
								#end
							}
						}

						// Register the mapping for use in function body
						// Use toSafeElixirParameterName to handle reserved keywords
						var baseName = reflaxe.elixir.ast.NameUtils.toSafeElixirParameterName(strippedName);

						// Avoid colliding with instance-field binders inside methods/constructors.
						// Many Haxe patterns use ctor args like `options` while also having a field named `options`.
						// If we emit both as `options`, later passes cannot reliably distinguish param reads from
						// instance-field state. Prefer a descriptive, stable suffix over numeric shadow suffixes.
						if (instanceFieldNames.exists(baseName) && !StringTools.endsWith(baseName, "_param")) {
							baseName = baseName + "_param";
						}
						// NOTE: Do not prefix unused parameters here.
						// Unused parameter hygiene is handled centrally in `prefixUnusedParametersPass`,
						// which also accounts for template-string usage (EEx/HEEx) that Haxe's TypedExpr
						// usage detection cannot see.
						var finalName = baseName;
						#if debug_variable_renaming
						#end

						if (!context.tempVarRenameMap.exists(idKey)) {
							#if debug_variable_renaming
							#end

							// Dual-key storage: ID for pattern positions, name for EVar references
							context.tempVarRenameMap.set(idKey, finalName); // ID-based (pattern matching)
							context.tempVarRenameMap.set(originalName, finalName); // NAME-based (EVar renaming)

							#if debug_variable_renaming
							#end

							#if debug_variable_renaming
							#end

							#if debug_hygiene
							#end
						} else {
							#if debug_variable_renaming
							#end
						}
					}

					#if debug_variable_renaming
					#end
				}

				// Build the function body with proper context
				// Special handling for direct switch returns that may have lost context
				#if debug_switch_return
				if (expr != null) {} else {}
				#end

				#if debug_exunit
				#end

				var funcBody = switch (expr.expr) {
					case TReturn(e) if (e != null):
						#if debug_switch_return
						#end

						// Check if it's a return of a switch (potentially wrapped in metadata)
						var innerExpr = e;
						switch (e.expr) {
							case TMeta(_, inner):
								#if debug_switch_return
								#end
								innerExpr = inner;
							case _:
						}

						#if debug_switch_return
						#end

						switch (innerExpr.expr) {
							case TSwitch(_, _, _):
								#if debug_switch_return
								#end
								// For direct switch returns, build the switch expression and wrap in parentheses
								// This ensures the full case structure is preserved
								var switchAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e, context);

								#if debug_switch_return
								#end

								// The switch itself is the body - no need for additional wrapping
								switchAST;
							case _:
								#if debug_switch_return
								#end
								// Normal return handling
								reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);
						}
					case _:
						#if debug_switch_return
						#end
						// Normal expression handling
						#if debug_variable_renaming
						#end
						reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);
				};

				#if debug_ast_builder
				#end

				// Clear function parameter tracking now that the body has been built.
				// This prevents parameter IDs from leaking into subsequent function compilations.
				for (idKey in functionParameterIdKeys) {
					context.functionParameterIds.remove(idKey);
				}

				// Get function parameters from tfunc
				var params:Array<EPattern> = [];

				// For instance methods, add struct as first parameter
				// BUT NOT for ExUnit test methods - they don't get struct parameters
				if (!isStaticMethod && !isExUnitTestMethod && !isConstructor) {
					params.push(PVar("struct"));
				}

				// Add the regular function parameters
				if (funcData.tfunc != null) {
					for (arg in funcData.tfunc.args) {
						// Look up the mapped name from tempVarRenameMap
						// This will have the underscore prefix if the parameter is unused
						var idKey = Std.string(arg.v.id);
						var paramName = if (context.tempVarRenameMap.exists(idKey)) {
							context.tempVarRenameMap.get(idKey);
						} else {
							// Fallback to original logic if not mapped (shouldn't happen)
							var originalName = arg.v.name;
							var strippedName = originalName;

							// Apply same stripping logic as above for consistency
							var renamedPattern = ~/^(.+?)(\d+)$/;
							if (renamedPattern.match(originalName)) {
								var baseWithoutSuffix = renamedPattern.matched(1);
								var suffix = renamedPattern.matched(2);

								var commonFieldNames = ["options", "columns", "name", "value", "type", "data", "fields", "items"];
								if ((suffix == "2" || suffix == "3") && commonFieldNames.indexOf(baseWithoutSuffix) >= 0) {
									strippedName = baseWithoutSuffix;
								}
							}

							// Use toSafeElixirParameterName to handle reserved keywords
							reflaxe.elixir.ast.NameUtils.toSafeElixirParameterName(strippedName);
						};

						params.push(PVar(paramName));
					}
				}

				// Create function definition.
				// Respect explicit method @:native first, then apply framework-aware defaults.
				var elixirName = resolveDefinitionFunctionName(funcData.field, classType);

				// Haxe entrypoints (`static function main()`) are not required to be `public`,
				// but Elixir warnings-as-errors will flag unused private functions in examples.
				// Emit `main/0` as a public `def` so downstream code can call `Module.main()`
				// (and to keep any private helpers it calls from being flagged as unused).
				var isMainEntrypoint = isStaticMethod && funcData.field.name == "main";

				// Constructors compile to a module-level `new/arity` that returns an initialized struct/map.
				// Haxe constructors mutate `this`; in Elixir we build a fresh `struct` map, run the body
				// against it, and return it.
				var receiverConvention = (!isStaticMethod && !isExUnitTestMethod && !isConstructor) ? ReceiverReturnConventions.forClassMethod(classType,
					funcData.field.name) : PureValue;
				funcBody = applyReceiverReturnConvention(funcBody, "struct", receiverConvention);

				if (isConstructor) {
					var isExceptionConstructor = false;
					var exceptionCheck:Null<ClassType> = classType;
					while (exceptionCheck != null) {
						var isHaxeExceptionRoot = (exceptionCheck.pack.length == 1 && exceptionCheck.pack[0] == "haxe" && exceptionCheck.name == "Exception");
						var isReflaxeExceptionRoot = (exceptionCheck.pack.length == 1 && exceptionCheck.pack[0] == "Reflaxe"
							&& exceptionCheck.name == "Exception");
						if (isHaxeExceptionRoot || isReflaxeExceptionRoot) {
							isExceptionConstructor = true;
							break;
						}
						exceptionCheck = if (exceptionCheck.superClass != null) exceptionCheck.superClass.t.get() else null;
					}

					var ctorModuleName = ModuleBuilder.extractModuleName(classType);
					var initStruct = if (isExceptionConstructor) {
						// Exception classes must construct a real exception struct so `is_struct/2` matches
						// and `raise <ExceptionModule>` interops naturally with Elixir/Phoenix.
						reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EStruct(ctorModuleName, []));
					} else {
						// Build initial map with all instance fields present so `%{struct | field: ...}` updates are safe.
						var initPairs:Array<reflaxe.elixir.ast.ElixirAST.EMapPair> = [];
						// Tag instances with their runtime module for virtual dispatch (`apply/3`).
						// Use the extracted module alias so @:native and app prefixing remain correct.
						initPairs.push({
							key: reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EAtom("__reflaxe_class__")),
							value: reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar(ctorModuleName))
						});
						for (snakeFieldName in collectInstanceVarSnakeNames(classType)) {
							initPairs.push({
								key: reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EAtom(snakeFieldName)),
								value: reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ENil)
							});
						}
						reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EMap(initPairs));
					};
					var initAssign = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EMatch(PVar("struct"), initStruct));

					var ctorExprs:Array<reflaxe.elixir.ast.ElixirAST> = [initAssign];
					switch (funcBody.def) {
						case EBlock(exprs):
							for (e in exprs)
								if (e != null)
									ctorExprs.push(e);
						default:
							if (funcBody != null)
								ctorExprs.push(funcBody);
					}
					// Ensure the constructor returns the constructed struct.
					ctorExprs.push(reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("struct")));
					funcBody = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EBlock(ctorExprs));
				}

				// Abstract implementation identity stubs.
				//
				// WHY
				// - For trivial abstracts (e.g., `abstract Atom(String) from String to String`), Haxe may
				//   emit empty bodies for constructor/helpers because the runtime representation is a
				//   no-op conversion.
				// - Elixir warnings-as-errors flags unused parameters in these empty functions.
				//
				// WHAT
				// - When compiling an abstract impl module and we see an empty `_new/1` or `fromString/1`,
				//   treat it as an identity function and return the single argument.
				//
				// HOW
				// - Only applies when the body is empty (`nil` or empty block) and arity is 1.
				var isAbstractImpl = switch (classType.kind) {
					case KAbstractImpl(_): true;
					default: false;
				};
				if (!isAbstractImpl && classType.name != null && classType.name.endsWith("_Impl_"))
					isAbstractImpl = true;

				function isEmptyBody(body:Null<reflaxe.elixir.ast.ElixirAST>):Bool {
					if (body == null || body.def == null)
						return true;
					return switch (body.def) {
						case ENil:
							true;
						case ERaw(code): code == null || code.trim() == "";
						case EBlock(exprs):
							if (exprs == null || exprs.length == 0) {
								true;
							} else {
								var allEmpty = true;
								for (e in exprs) {
									if (!isEmptyBody(e)) {
										allEmpty = false;
										break;
									}
								}
								allEmpty;
							}
						case EDo(exprs):
							if (exprs == null || exprs.length == 0) {
								true;
							} else {
								var allEmpty = true;
								for (e in exprs) {
									if (!isEmptyBody(e)) {
										allEmpty = false;
										break;
									}
								}
								allEmpty;
							}
						default:
							false;
					};
				}

				var isAbstractIdentityStub = (funcData.field.name == "_new"
					|| funcData.field.name == "fromString"
					|| funcData.field.name == "from_string"
					|| elixirName == "_new"
					|| elixirName == "from_string");

				if (isAbstractImpl && funcBody != null && params.length == 1 && isAbstractIdentityStub) {
					var bodyIsEmpty = isEmptyBody(funcBody);

					if (bodyIsEmpty) {
						var argName = switch (params[0]) {
							case PVar(n): n;
							default: null;
						};
						if (argName != null && argName.length > 0) {
							funcBody = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar(argName));
						}
					}
				}

				// Haxe property accessors (`get_*/set_*`) are often implemented as private methods
				// even when the property itself is public. Haxe enforces privacy at compile time,
				// but our generated Elixir will call these accessors across modules (e.g. `obj.message`
				// → `Reflaxe.Exception.get_message(obj)`), so emitting them as `defp` breaks runtime.
				function isPublicPropertyAccessor(fieldName:String):Bool {
					if (fieldName == null)
						return false;
					var propName:Null<String> = null;
					var isGetter = false;
					var isSetter = false;
					if (StringTools.startsWith(fieldName, "get_")) {
						propName = fieldName.substr(4);
						isGetter = true;
					} else if (StringTools.startsWith(fieldName, "set_")) {
						propName = fieldName.substr(4);
						isSetter = true;
					}
					if (propName == null || propName.length == 0)
						return false;

					for (f in classType.fields.get()) {
						if (f == null || f.name != propName)
							continue;
						if (!f.isPublic)
							return false;
						return switch (f.kind) {
							case FVar(read, write): (isGetter && read == AccCall) || (isSetter && write == AccCall);
							default:
								false;
						};
					}
					return false;
				}

				var emitPublic = funcData.field.isPublic || isMainEntrypoint || isPublicPropertyAccessor(funcData.field.name);
				var funcDef = emitPublic ? EDef(elixirName, params, null, funcBody) : EDefp(elixirName, params, null, funcBody);

				if (isMainEntrypoint && currentCompiledModule != null && modulesWithBootstrap.indexOf(currentCompiledModule) < 0) {
					modulesWithBootstrap.push(currentCompiledModule);
				}

				// Check for test-related metadata on the function field
				var funcMetadata:reflaxe.elixir.ast.ElixirAST.ElixirMetadata = {};
				funcMetadata.receiverReturnConvention = ReceiverReturnConventions.toMetadataValue(receiverConvention);

				// Set ExUnit-related metadata flags directly (accept both forms with and without ':')
				inline function hasMeta(name:String):Bool {
					return funcData.field.meta.has(name) || funcData.field.meta.has(":" + name);
				}
				funcMetadata.isTest = hasMeta("test");
				funcMetadata.isSetup = hasMeta("setup");
				funcMetadata.isSetupAll = hasMeta("setupAll");
				funcMetadata.isTeardown = hasMeta("teardown");
				funcMetadata.isTeardownAll = hasMeta("teardownAll");
				funcMetadata.isAsync = hasMeta("async");

				#if debug_exunit
				if (funcMetadata.isTest) {}
				#end

				// Check for test tags (gather both :tag and tag forms)
				var tagMeta = funcData.field.meta.extract("tag");
				var tagMetaAlt = funcData.field.meta.extract(":tag");
				if (tagMetaAlt != null && tagMetaAlt.length > 0) {
					if (tagMeta == null)
						tagMeta = tagMetaAlt;
					else
						tagMeta = tagMeta.concat(tagMetaAlt);
				}
				if (tagMeta != null && tagMeta.length > 0) {
					var tags = [];
					for (entry in tagMeta) {
						if (entry.params != null) {
							for (param in entry.params) {
								switch (param.expr) {
									case EConst(CString(tag)):
										tags.push(tag);
									default:
								}
							}
						}
					}
					if (tags.length > 0) {
						funcMetadata.testTags = tags;
					}
				}

				// Check for describe block (accept both forms)
				var describeMeta = funcData.field.meta.extract("describe");
				var describeMetaAlt = funcData.field.meta.extract(":describe");
				if (describeMetaAlt != null && describeMetaAlt.length > 0) {
					if (describeMeta == null)
						describeMeta = describeMetaAlt;
					else
						describeMeta = describeMeta.concat(describeMetaAlt);
				}
				if (describeMeta != null && describeMeta.length > 0) {
					for (entry in describeMeta) {
						if (entry.params != null && entry.params.length > 0) {
							switch (entry.params[0].expr) {
								case EConst(CString(block)):
									funcMetadata.describeBlock = block;
								default:
							}
						}
					}
				}

				// Create AST node directly (makeAST is an inline function, not a static method)
				fields.push({
					def: funcDef,
					metadata: funcMetadata,
					pos: funcData.field.pos
				});
			} catch (e:Dynamic) {
				// Restore the class-level context map for the next function.
				context.tempVarRenameMap = previousTempVarRenameMap;
				context.infrastructureVarInitValues = previousInfraVarInitValues;
				context.localVarInitValuesById = previousLocalVarInitValuesById;
				context.infraVarSubstitutions = previousInfraVarSubstitutions;
				context.loopControlStateStack = previousLoopControlStateStack;
				context.anonymousTempVarCounter = previousAnonymousTempVarCounter;
				context.currentFunction = previousCurrentFunction;
				throw e;
			}

			// Restore the class-level context map for the next function.
			context.tempVarRenameMap = previousTempVarRenameMap;
			context.infrastructureVarInitValues = previousInfraVarInitValues;
			context.localVarInitValuesById = previousLocalVarInitValuesById;
			context.infraVarSubstitutions = previousInfraVarSubstitutions;
			context.loopControlStateStack = previousLoopControlStateStack;
			context.anonymousTempVarCounter = previousAnonymousTempVarCounter;
			context.currentFunction = previousCurrentFunction;
		}

		// Prepare metadata for special module types BEFORE building the module
		var metadata:ElixirMetadata = {};

		// Detect and store parent class information for inheritance handling
		if (classType.superClass != null) {
			var parentClass = classType.superClass.t.get();
			var parentModuleName = if (parentClass.meta.has(":native")) {
				// Use @:native name if specified
				var nativeMeta = parentClass.meta.extract(":native");
				if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
					switch (nativeMeta[0].params[0].expr) {
						case EConst(CString(s, _)): s;
						default: parentClass.name;
					}
				} else {
					parentClass.name;
				}
			} else {
				parentClass.name;
			};

			metadata.parentModule = parentModuleName;

			// Check if this extends haxe.Exception or any Exception subclass
			var isException = false;
			var currentClass = parentClass;
			while (currentClass != null) {
				// NOTE: For the Elixir target we override `haxe.Exception` to `@:native("Reflaxe.Exception")`.
				// In some macro/type contexts Haxe reports the native module path (`Reflaxe.Exception`) as the
				// effective superclass pack/name, so detect both:
				// - Haxe stdlib root: `haxe.Exception`
				// - Elixir runtime root: `Reflaxe.Exception`
				var isHaxeExceptionRoot = (currentClass.pack.length == 1 && currentClass.pack[0] == "haxe" && currentClass.name == "Exception");
				var isReflaxeExceptionRoot = (currentClass.pack.length == 1 && currentClass.pack[0] == "Reflaxe" && currentClass.name == "Exception");
				if (isHaxeExceptionRoot || isReflaxeExceptionRoot) {
					isException = true;
					break;
				}
				currentClass = if (currentClass.superClass != null) currentClass.superClass.t.get() else null;
			}
			metadata.isException = isException;

			#if debug_inheritance
			#end
		}
		// Exception root detection:
		// - `haxe.Exception` is `extern` in the upstream stdlib; for Elixir builds we provide a concrete
		//   implementation under `src/haxe/Exception.cross.hx` that emits as `Reflaxe.Exception`.
		// - In some contexts Haxe reports the native module path (`Reflaxe.Exception`) as the effective
		//   type pack/name, so treat both as the exception root module.
		if ((classType.pack.length == 1 && classType.pack[0] == "haxe" && classType.name == "Exception")
			|| (classType.pack.length == 1 && classType.pack[0] == "Reflaxe" && classType.name == "Exception")) {
			metadata.isException = true;
		}

		// Enable ExUnit transformation pass for @:exunit modules
		// Meta names in Haxe macros are stored without the leading colon.
		// Be tolerant and check both with and without ':' to avoid fragile assumptions.
		if (classType.meta.has("exunit") || classType.meta.has(":exunit")) {
			metadata.isExunit = true;
		}

		// Enable LiveView transformation pass for @:liveview modules
		if (classType.meta.has(":liveview")) {
			metadata.isLiveView = true;
			#if debug_annotation_transforms
			#end
		}

		// Enable Application transformation pass for @:application modules
		if (classType.meta.has(":application")) {
			metadata.isApplication = true;
			#if debug_annotation_transforms
			#end
		}

		// Enable Repo transformation pass for @:repo modules
		// Note: After prior refactors, some repo metadata fields were lost; restore
		// essential flags here to ensure companion modules (PostgrexTypes) are generated.
		if (classType.meta.has(":repo")) {
			metadata.isRepo = true;

			// Extract repo configuration if provided
			var repoMeta = classType.meta.extract(":repo");
			if (repoMeta.length > 0 && repoMeta[0].params != null && repoMeta[0].params.length > 0) {
				// Parse the configuration object
				// The configuration handling was also lost in the refactoring
				// For now, just set the basic metadata
				metadata.dbAdapter = "Ecto.Adapters.Postgres"; // Default to Postgres
				// Companion module generation for Postgres
				metadata.needsPostgrexTypes = true;
				// Default JSON library (configurable via @:repo json field when parser restored)
				metadata.jsonModule = "Jason";
			}

			#if debug_annotation_transforms
			#end
		}

		// Enable Schema transformation pass for @:schema modules
		if (classType.meta.has(":schema")) {
			metadata.isSchema = true;

			#if debug_annotation_transforms
			// Also check classType.fields directly from Haxe type system
			var typeFields = classType.fields.get();
			for (f in typeFields) {}
			#end

			// Extract table name from @:schema annotation if provided
			var schemaMeta = classType.meta.extract(":schema");
			if (schemaMeta.length > 0 && schemaMeta[0].params != null && schemaMeta[0].params.length > 0) {
				switch (schemaMeta[0].params[0].expr) {
					case EConst(CString(tableName, _)):
						metadata.tableName = tableName;
					default:
				}
			}

			// Check for @:timestamps annotation (class-level), plus legacy field-level placement.
			// WHY: Some early examples placed @:timestamps on a field (e.g. inserted_at) while
			//      the intended ergonomic form is class-level @:timestamps.
			if (classType.meta.has(":timestamps")) {
				metadata.hasTimestamps = true;
			}

			// Extract @:changeset annotation parameters.
			// Supported forms:
			//   1) Legacy positional:
			//      @:changeset(["field1", "field2"], ["required1"])
			//   2) Named config (recommended):
			//      @:changeset(cast(["field1", "field2"]), validate(["required1"]))
			//      (`required` is accepted as a legacy alias for `validate`)
			if (classType.meta.has(":changeset")) {
				var changesetMeta = classType.meta.extract(":changeset");
				if (changesetMeta != null && changesetMeta.length > 0) {
					var params = changesetMeta[0].params;
					if (params != null && params.length >= 1) {
						var firstParam = params[0];
						switch (firstParam.expr) {
							case EObjectDecl(fields):
								metadata.changesetCastFields = extractStringArrayFromNamedField(fields, "cast");
								var validateFields = extractStringArrayFromNamedField(fields, "validate");
								if (validateFields.length == 0) {
									// Backward-compat alias for early drafts.
									validateFields = extractStringArrayFromNamedField(fields, "required");
								}
								metadata.changesetRequiredFields = validateFields;
							default:
								// Preferred named form:
								// @:changeset(cast([...]), validate([...]))
								var namedArgs = extractChangesetNamedArgs(params);
								if (namedArgs != null) {
									metadata.changesetCastFields = namedArgs.castFields;
									metadata.changesetRequiredFields = namedArgs.validateFields;
								} else {
									// Legacy positional form.
									metadata.changesetCastFields = extractStringArrayFromExpr(firstParam);
									if (params.length >= 2) {
										var requiredFieldsExpr = params[1];
										metadata.changesetRequiredFields = extractStringArrayFromExpr(requiredFieldsExpr);
									} else {
										metadata.changesetRequiredFields = [];
									}
								}
						}
					}
				}
			}

			// Collect schema fields from classType.fields directly since varFields
			// may not include all fields from Reflaxe's collection
			var schemaFields = [];
			var typeFields = classType.fields.get();
			for (field in typeFields) {
				// Only collect instance fields (not functions) that have @:field annotation
				var isField = field.meta.has(":field");
				var isVirtual = field.meta.has(":virtual");
				switch (field.kind) {
					case FVar(read, write):
						if (isField && !isVirtual) {
							var fieldName = field.name;
							var fieldType = schemaTypeNameFromType(field.type);
							schemaFields.push({
								name: fieldName,
								type: fieldType
							});
							#if debug_annotation_transforms
							#end
						}
						// Legacy: allow @:timestamps on a field to enable timestamps() emission.
						if (field.meta.has(":timestamps")) {
							metadata.hasTimestamps = true;
						}
					default:
						// Skip functions and other field kinds
				}
			}
			metadata.schemaFields = schemaFields;

			// Collect schema associations (belongs_to/has_many/has_one/many_to_many)
			metadata.schemaAssociations = extractSchemaAssociationsFromTypeFields(typeFields);

			// Store the fully qualified class name for lookups
			metadata.haxeFqcn = classType.pack.length > 0 ? classType.pack.join(".") + "." + classType.name : classType.name;

			// Check if user defined their own changeset function (with implementation, not just extern declaration)
			// WHY: User-defined changesets using __elixir__() generate ERaw nodes that can't be detected
			//      by AST structure alone in transformers. This metadata flag allows clean detection.
			// WHAT: We check funcFields (available here) for a function named "changeset" WITH a body
			// HOW: Check for function name AND that it has an expression (not extern)
			for (funcData in funcFields) {
				if (funcData.field.name == "changeset") {
					// Only count as user-defined if it has a body (not extern)
					switch (funcData.field.kind) {
						case FMethod(_):
							// Check if there's an actual expression
							if (funcData.expr != null) {
								metadata.hasUserChangeset = true;
							}
						default:
					}
					break;
				}
			}

			#if debug_annotation_transforms
			#end
		}

		// Enable Supervisor transformation pass for @:supervisor modules
		if (classType.meta.has(":supervisor")) {
			metadata.isSupervisor = true;
			#if debug_annotation_transforms
			#end
		}

		// Enable Router transformation pass for @:router modules.
		// Module-level fields are compiled by Haxe into KModuleFields classes,
		// with metadata attached to synthetic static fields, so we check both.
		if (hasClassOrStaticMetadata(classType, ":router", "router")) {
			metadata.isRouter = true;
			metadata.routerRoutes = extractRouterRoutesFromMeta(classType);
			metadata.routerDslNodes = extractRouterDslNodesFromMeta(classType);
			#if debug_annotation_transforms
			#end
		}

		// Enable Presence transformation pass for @:presence modules
		if (classType.meta.has(":presence")) {
			metadata.isPresence = true;
			#if debug_annotation_transforms
			#end
		}

		// Enable Socket transformation pass for @:socket modules
		if (classType.meta.has(":socket")) {
			metadata.isSocket = true;
			metadata.socketChannels = extractSocketChannelsFromMeta(classType);
			#if debug_annotation_transforms
			#end
		}

		// Enable Endpoint transformation pass for @:endpoint modules
		// Endpoints are also supervisors and need child_spec/start_link preservation
		if (classType.meta.has(":endpoint")) {
			metadata.isEndpoint = true;
			// Endpoints are supervisors too - they need child_spec/start_link
			metadata.isSupervisor = true;
			metadata.endpointSockets = extractEndpointSocketsFromMeta(classType);
			metadata.endpointLiveLongpoll = extractEndpointLiveLongpollFromMeta(classType);
			#if debug_annotation_transforms
			#end
		}

		// Enable PhoenixWeb transformation pass for @:phoenixWebModule or @:phoenixWeb modules
		if (classType.meta.has(":phoenixWebModule") || classType.meta.has(":phoenixWeb")) {
			metadata.isPhoenixWeb = true;
			#if debug_annotation_transforms
			#end
		}

		// Record snake_case instance fields for downstream struct/map lowering passes.
		// This enables generic, shape-based rewriting of `field = ...` to `%{struct | field: ...}`.
		var instanceFieldList = [for (k in instanceFieldNames.keys()) k];
		instanceFieldList.sort(function(a, b) {
			return a < b ? -1 : (a > b ? 1 : 0);
		});
		metadata.instanceFields = instanceFieldList;

		// --------------------------------------------------------------------
		// Inheritance: generate delegation wrappers for inherited instance methods.
		//
		// WHY
		// - We implement virtual dispatch using `apply/3` on the receiver's runtime module.
		// - Subclasses may not re-emit parent methods, so we generate thin wrappers that
		//   delegate to the parent module for any inherited public method that the subclass
		//   does not override.
		//
		// HOW
		// - For each direct parent instance method (excluding `new`), if it would be emitted
		//   as a public `def` in the parent and the current module does not already define
		//   it, emit:
		//     def name(struct, args...), do: Parent.name(struct, args...)
		// --------------------------------------------------------------------
		if (classType.superClass != null) {
			var parentType = classType.superClass.t.get();
			if (parentType != null) {
				var existingFunctionNames:Map<String, Bool> = new Map();
				for (f in fields) {
					if (f == null || f.def == null)
						continue;
					switch (f.def) {
						case EDef(name, _, _, _) | EDefp(name, _, _, _) | EDefmacro(name, _, _, _) | EDefmacrop(name, _, _, _):
							existingFunctionNames.set(name, true);
						default:
					}
				}

				function isPublicPropertyAccessorForClass(klass:ClassType, fieldName:String):Bool {
					if (klass == null || fieldName == null)
						return false;
					var propName:Null<String> = null;
					var isGetter = false;
					var isSetter = false;
					if (StringTools.startsWith(fieldName, "get_")) {
						propName = fieldName.substr(4);
						isGetter = true;
					} else if (StringTools.startsWith(fieldName, "set_")) {
						propName = fieldName.substr(4);
						isSetter = true;
					}
					if (propName == null || propName.length == 0)
						return false;

					for (f in klass.fields.get()) {
						if (f == null || f.name != propName)
							continue;
						if (!f.isPublic)
							return false;
						return switch (f.kind) {
							case FVar(read, write): (isGetter && read == AccCall) || (isSetter && write == AccCall);
							default:
								false;
						};
					}
					return false;
				}

				var parentModuleName = ModuleBuilder.extractModuleName(parentType);
				for (field in parentType.fields.get()) {
					if (field == null)
						continue;
					if (field.name == "new")
						continue;
					var isMethod = switch (field.kind) {
						case FMethod(_): true;
						default: false;
					};
					if (!isMethod)
						continue;

					var emitPublic = field.isPublic || isPublicPropertyAccessorForClass(parentType, field.name);
					if (!emitPublic)
						continue;

					var elixirName = resolveDefinitionFunctionName(field, parentType);
					if (existingFunctionNames.exists(elixirName))
						continue;

					var argPatterns:Array<reflaxe.elixir.ast.ElixirAST.EPattern> = [PVar("struct")];
					var argVars:Array<reflaxe.elixir.ast.ElixirAST> = [reflaxe.elixir.ast.ElixirAST.makeAST(EVar("struct"))];

					switch (haxe.macro.TypeTools.follow(field.type)) {
						case TFun(fnArgs, _):
							for (fnArg in fnArgs) {
								var paramName = reflaxe.elixir.ast.NameUtils.toSafeElixirParameterName(fnArg.name);
								argPatterns.push(PVar(paramName));
								argVars.push(reflaxe.elixir.ast.ElixirAST.makeAST(EVar(paramName)));
							}
						default:
							// Unexpected non-function field; skip.
							continue;
					}

					var parentCall = reflaxe.elixir.ast.ElixirAST.makeAST(ERemoteCall(reflaxe.elixir.ast.ElixirAST.makeAST(EVar(parentModuleName)),
						elixirName, argVars));

					fields.push(reflaxe.elixir.ast.ElixirAST.makeAST(EDef(elixirName, argPatterns, null, parentCall)));
					existingFunctionNames.set(elixirName, true);
				}
			}
		}

		// Build the module using ModuleBuilder with metadata
		var moduleAST = reflaxe.elixir.ast.builders.ModuleBuilder.buildClassModule(classType, fields, metadata);

		// Additional metadata settings if needed
		if (moduleAST != null && moduleAST.metadata == null) {
			moduleAST.metadata = metadata;
		}

		// ExUnit debug output
		if (moduleAST != null && moduleAST.metadata != null && moduleAST.metadata.isExunit == true) {
			#if debug_exunit
			#end
		}

		// Application debug output
		if (moduleAST != null && moduleAST.metadata != null && moduleAST.metadata.isApplication == true) {
			#if debug_annotation_transforms
			#end
		}

		// PASS 3: Generate companion modules if needed (e.g., PostgrexTypes for Repo)
		if (moduleAST != null && moduleAST.metadata != null) {
			generateCompanionModules(classType, moduleAST.metadata);
		}

		// Restore previous behavior transformer state
		if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
			reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.activeBehavior = previousBehavior;
			#if debug_behavior_transformer
			if (previousBehavior != null) {} else {}
			#end
		}

		return moduleAST;
	}

	/**
	 * Normalize Haxe type to a simple schema type string for Ecto field mapping.
	 * - Unwrap Null<T> to T
	 * - Map Array<T> to "Array<TName>"
	 * - Map core types to their canonical names used by schema mapping
	 */
	static function schemaTypeNameFromType(t:Type):String {
		return switch (t) {
			case TType(td, params):
				// Unwrap type aliases (including Null<T>)
				var underlying = td.get();
				if (underlying.name == "Null" && params != null && params.length == 1) {
					return schemaTypeNameFromType(params[0]);
				} else {
					// Fallback to the aliased name
					underlying.name;
				}
			case TAbstract(ad, params):
				var n = ad.get().name;
				if (n == "Null" && params != null && params.length == 1) {
					return schemaTypeNameFromType(params[0]);
				}
				switch (n) {
					case "Int": return "Int";
					case "Bool": return "Bool";
					case "Single", "Float": return "Float";
					default: return n;
				}
			case TInst(td, params):
				var cls = td.get();
				if (cls.name == "Array" && params != null && params.length == 1) {
					return "Array<" + schemaTypeNameFromType(params[0]) + ">";
				}
				switch (cls.name) {
					case "String": return "String";
					case "Int": return "Int";
					case "Bool": return "Bool";
					case "Date": return "Date";
					default: return cls.name;
				}
			case TAnonymous(_):
				// Treat anonymous objects as Dynamic
				"Dynamic";
			case _: "String"; // Reasonable default
		}
	}

	/**
	 * Collect snake_case instance field names for a class, including inherited fields.
	 *
	 * WHY
	 * - Reflaxe objects are represented as Elixir maps, and we rely on `%{struct | field: ...}`
	 *   updates for idiomatic lowering. Map-update requires the key to exist.
	 * - When calling base-class methods on subclass instances, base fields (e.g. `big_endian`
	 *   from `haxe.io.Input/Output`) must be present on the subclass instance map to avoid
	 *   runtime `KeyError`.
	 *
	 * HOW
	 * - Walk the `superClass` chain starting from `classType`, collecting `FVar` fields.
	 * - De-duplicate by snake_case name, preferring the most-derived definition.
	 */
	private function collectInstanceVarSnakeNames(classType:ClassType):Array<String> {
		var snakeNames:Array<String> = [];
		var seen:Map<String, Bool> = new Map();

		var current:Null<ClassType> = classType;
		while (current != null) {
			for (field in current.fields.get()) {
				switch (field.kind) {
					case FVar(_, _):
						var snakeFieldName = reflaxe.elixir.ast.NameUtils.toSnakeCase(field.name);
						if (!seen.exists(snakeFieldName)) {
							seen.set(snakeFieldName, true);
							snakeNames.push(snakeFieldName);
						}
					default:
				}
			}

			current = if (current.superClass != null) current.superClass.t.get() else null;
		}

		return snakeNames;
	}

	static function extractSchemaAssociationsFromTypeFields(typeFields:Array<ClassField>):Array<SchemaAssociationMeta> {
		var associations:Array<SchemaAssociationMeta> = [];

		for (field in typeFields) {
			var kind:Null<SchemaAssociationKind> = null;

			if (field.meta.has(":belongs_to"))
				kind = SchemaAssociationKind.BelongsTo;
			else if (field.meta.has(":has_many"))
				kind = SchemaAssociationKind.HasMany;
			else if (field.meta.has(":has_one"))
				kind = SchemaAssociationKind.HasOne;
			else if (field.meta.has(":many_to_many"))
				kind = SchemaAssociationKind.ManyToMany;

			if (kind == null)
				continue;

			var metaName = ":" + Std.string(kind);
			var metaEntries = field.meta.extract(metaName);
			if (metaEntries == null || metaEntries.length == 0)
				continue;

			var params = metaEntries[0].params;
			var assocName = field.name;
			var assocModule:Null<String> = null;
			var joinThrough:Null<String> = null;

			if (params != null) {
				// First arg is almost always the association name.
				if (params.length >= 1) {
					switch (params[0].expr) {
						case EConst(CString(name, _)):
							assocName = name;
						default:
					}
				}

				// Remaining args: module name (string) and/or options object.
				for (i in 1...params.length) {
					switch (params[i].expr) {
						case EConst(CString(moduleName, _)):
							if (assocModule == null)
								assocModule = moduleName;
						case EObjectDecl(fields):
							if (kind == SchemaAssociationKind.ManyToMany) {
								for (f in fields) {
									var key = f.field;
									switch (f.expr.expr) {
										case EConst(CString(v, _)):
											if (key == "join_through" || key == "through") joinThrough = v;
										default:
									}
								}
							}
						default:
					}
				}
			}

			if (assocModule == null) {
				assocModule = inferAssociationModuleFromType(field.type);
			}

			if (assocModule == null)
				continue;

			associations.push({
				kind: kind,
				name: assocName,
				module: assocModule,
				joinThrough: joinThrough
			});
		}

		return associations;
	}

	static function inferAssociationModuleFromType(t:Type):Null<String> {
		return switch (t) {
			case TType(td, params):
				var underlying = td.get();
				if (underlying.name == "Null" && params != null && params.length == 1) {
					inferAssociationModuleFromType(params[0]);
				} else {
					null;
				}
			case TAbstract(ad, params):
				var n = ad.get().name;
				if (n == "Null" && params != null && params.length == 1) {
					inferAssociationModuleFromType(params[0]);
				} else {
					null;
				}
			case TInst(td, params):
				var cls = td.get();
				if (cls.name == "Array" && params != null && params.length == 1) {
					inferAssociationModuleFromType(params[0]);
				} else if (cls.name == "Dynamic") {
					null;
				} else {
					cls.name;
				}
			case TAnonymous(_):
				null;
			case _:
				null;
		}
	}

	/**
	 * Generate companion modules based on metadata (e.g., PostgrexTypes for Repo)
	 * 
	 * WHY: Some Elixir modules require companion modules for configuration.
	 *      For example, Ecto.Repo with PostgreSQL needs a PostgrexTypes module
	 *      that defines type encoding/decoding using Postgrex.Types.define.
	 * 
	 * WHAT: Generates additional modules as separate files when needed
	 * 
	 * HOW: Checks metadata flags and generates appropriate companion modules
	 *      using setExtraFile to create additional output files
	 */
	function generateCompanionModules(classType:ClassType, metadata:ElixirMetadata):Void {
		// Check if this Repo needs a PostgrexTypes companion module
		if (metadata.isRepo && metadata.needsPostgrexTypes) {
			generatePostgrexTypesModule(classType, metadata);
		}
	}

	/**
	 * Generate PostgrexTypes companion module for Ecto.Repo with PostgreSQL
	 * 
	 * WHY: PostgreSQL adapter requires a types module for JSON encoding/decoding
	 * 
	 * WHAT: Creates a separate module that calls Postgrex.Types.define
	 * 
	 * HOW: Builds the module AST and writes it as a separate file
	 * 
	 * Example output:
	 * ```elixir
	 * defmodule TodoApp.PostgrexTypes do
	 *   Postgrex.Types.define(TodoApp.PostgrexTypes, [], json: Jason)
	 * end
	 * ```
	 */
	function generatePostgrexTypesModule(classType:ClassType, metadata:ElixirMetadata):Void {
		// Get the base module name (e.g., "TodoApp.Repo" -> "TodoApp")
		var moduleName = reflaxe.elixir.ast.builders.ModuleBuilder.extractModuleName(classType);

		// Extract the base app name (before .Repo)
		var appName = moduleName.split(".")[0];

		// Create the PostgrexTypes module name
		var typesModuleName = appName + ".PostgrexTypes";

		#if debug_repo
		#end

		// Build the module body
		var statements = [];

		// Build extensions array - empty by default
		var extensionsAST = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EList([]));
		if (metadata.extensions != null && metadata.extensions.length > 0) {
			var extElements = metadata.extensions.map(ext -> reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EAtom(ext)));
			extensionsAST = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EList(extElements));
		}

		// Build keyword list for options (json: Jason)
		var options = [];
		if (metadata.jsonModule != null) {
			// Create a keyword list element for json: Jason
			var jsonAtom = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EAtom(ElixirAtom.raw("json")));
			var jsonModule = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar(metadata.jsonModule));
			var keywordElement = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ETuple([jsonAtom, jsonModule]));
			options.push(keywordElement);
		}

		// Build the Postgrex.Types.define call
		var moduleRef = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar(typesModuleName));
		var args = [
			moduleRef, // Module reference
			extensionsAST, // Extensions array
			reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EList(options)) // Options keyword list
		];

		var defineCall = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERemoteCall(reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("Postgrex.Types")),
			"define", args));

		statements.push(defineCall);

		// For PostgrexTypes, we don't need a module wrapper - Postgrex.Types.define creates it
		// Just generate the top-level macro call
		var moduleAST = defineCall;

		// Create a compilation context for transformation
		var context = createCompilationContext();

		// Apply transformations with context
		moduleAST = reflaxe.elixir.ast.ElixirASTTransformer.transform(moduleAST, context);

		// Convert to string with context
		var moduleString = reflaxe.elixir.ast.ElixirASTPrinter.printAST(moduleAST, context);

		// Set the output path for this companion module
		// Use snake_case for the file name
		var fileName = reflaxe.elixir.ast.NameUtils.toSnakeCase("PostgrexTypes");
		var filePackage = [reflaxe.elixir.ast.NameUtils.toSnakeCase(appName)];

		// Create the output path
		var outputPath = filePackage.join("/") + "/" + fileName + ".ex";

		#if debug_repo
		#end

		// Use setExtraFile to generate the companion module
		setExtraFile(outputPath, moduleString);
	}

	/**
	 * Check if this is a built-in abstract type that should NOT generate an Elixir module
	 */
	private function isBuiltinAbstractType(name:String):Bool {
		// Built-in abstracts that shouldn't generate modules
		return switch (name) {
			case "Int" | "Float" | "Bool" | "String" | "Void" | "Dynamic": true;
			case "__Int64" | "Int64": true; // Haxe Int64 types
			case _: false;
		}
	}

	/**
	 * Check if this is a standard library class type that should NOT generate an Elixir module
	 */
	private function isStandardLibraryClass(name:String):Bool {
		// Standard library classes handled elsewhere
		return switch (name) {
			case "String" | "Array" | "Map" | "Date" | "Math" | "List": true;
			case "__Int64" | "Int64" | "Int64_Impl_": true; // Haxe Int64 internal types
			case _: false;
		}
	}

	/**
	 * Build enum AST - creates module with constructor functions
	 */
	function buildEnumAST(enumType:EnumType, options:Array<EnumOptionData>):Null<reflaxe.elixir.ast.ElixirAST> {
		// Suppress std/internal enums that should not become modules in Elixir output
		if (shouldSuppressEnumEmission(enumType)) {
			return null;
		}
		var NameUtils = reflaxe.elixir.ast.NameUtils;

		// Check if this enum has @:elixirIdiomatic metadata
		var isIdiomatic = enumType.meta.has(":elixirIdiomatic");

		// In Elixir, enums become modules with functions that return tagged tuples
		// Extract module name - check for @:native annotation first
		var moduleName = if (enumType.meta.has(":native")) {
			// Use explicit @:native module name if provided
			var nativeMeta = enumType.meta.extract(":native");
			if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
				switch (nativeMeta[0].params[0].expr) {
					case EConst(CString(s, _)):
						s;
					default:
						// Fall back to package-based name if annotation is malformed
						buildEnumModuleName(enumType);
				}
			} else {
				buildEnumModuleName(enumType);
			}
		} else {
			buildEnumModuleName(enumType);
		};
		var functions = [];

		// Build an index map for enum constructors
		var constructorIndexMap = new Map<String, Int>();
		for (name in enumType.constructs.keys()) {
			var constructor = enumType.constructs.get(name);
			constructorIndexMap.set(name, constructor.index);
		}

		for (option in options) {
			// Each enum constructor becomes a function
			// Use safe function name to handle reserved keywords
			var funcName = NameUtils.toSafeElixirFunctionName(option.name);

			// Build parameter patterns from the option data
			var args = [];
			for (i in 0...option.args.length) {
				args.push(EPattern.PVar('arg$i'));
			}

			// Create the tagged tuple return value
			// For non-idiomatic enums, use integer indices; for idiomatic, use atoms
			var tag = if (isIdiomatic) {
				reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EAtom(option.name));
			} else {
				// Use the constructor's index for non-idiomatic enums
				var index = constructorIndexMap.get(option.name);
				if (index == null)
					index = 0; // Fallback, should not happen
				reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EInteger(index));
			};
			var tupleElements = [tag];

			// Add constructor arguments to tuple
			for (i in 0...option.args.length) {
				tupleElements.push(reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EVar('arg$i')));
			}

			var returnValue = reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.ETuple(tupleElements));

			// If idiomatic, mark the return value with metadata
			if (isIdiomatic) {
				returnValue.metadata.requiresIdiomaticTransform = true;
				returnValue.metadata.idiomaticEnumType = enumType.name;
			}

			var funcDef = ElixirASTDef.EDef(funcName, args, null, returnValue);
			functions.push(reflaxe.elixir.ast.ElixirAST.makeAST(funcDef));
		}

		// Create module AST
		var moduleBody = reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EBlock(functions));
		var moduleAST = reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EDefmodule(moduleName, moduleBody));

		// Mark the module itself if idiomatic
		if (isIdiomatic) {
			moduleAST.metadata.requiresIdiomaticTransform = true;
			moduleAST.metadata.idiomaticEnumType = enumType.name;
		}

		return moduleAST;
	}

	/**
	 * Suppression rules for enum emission (std/internal)
	 */
	private function shouldSuppressEnumEmission(enumType:EnumType):Bool {
		if (enumType == null)
			return false;
		var n = enumType.name;
		if (n == null)
			return false;

		// Common Haxe std enums not needed as modules in Elixir
		if (n == "ValueType" || n == "StackItem")
			return true;

		if (enumType.pack != null && enumType.pack.length > 0) {
			var top = enumType.pack[0];
			if (top == "haxe")
				return true;
			if (StringTools.startsWith(top, "_"))
				return true;
		}

		return false;
	}

	/**
	 * Build the full module name for an enum including package
	 * Ensures proper capitalization for Elixir module names
	 */
	function buildEnumModuleName(enumType:EnumType):String {
		var parts = enumType.pack.copy();
		parts.push(enumType.name);

		// Handle nested module paths with underscores
		// ecto._migration.ConstraintType -> Ecto.Migration.ConstraintType
		var processedParts = [];
		for (part in parts) {
			if (part.length > 0) {
				// Remove leading underscores and capitalize
				var cleanPart = part;
				while (cleanPart.charAt(0) == "_") {
					cleanPart = cleanPart.substr(1);
				}
				if (cleanPart.length > 0) {
					// Capitalize the first letter
					cleanPart = cleanPart.charAt(0).toUpperCase() + cleanPart.substr(1);
					processedParts.push(cleanPart);
				}
			}
		}

		return processedParts.join(".");
	}

	public function generateFunctionReference(functionName:String):String {
		// Convert function name to snake_case for Elixir
		var elixirFunctionName = reflaxe.elixir.ast.NameUtils.toSnakeCase(functionName);

		// Get the current module name for the function reference
		var currentModuleName = getCurrentModuleName();

		// Determine the arity by looking up the function
		var arity = getFunctionArity(functionName);

		// Generate Elixir function reference syntax
		return '&${currentModuleName}.${elixirFunctionName}/${arity}';
	}

	/**
	 * Get the current module name for function references
	 */
	public function getCurrentModuleName():String {
		if (currentClassType != null) {
			// Use the current class name as the module name
			return currentClassType.name;
		}
		return "UnknownModule";
	}

	/**
	 * Get module name for a specific ClassType
	 */
	public function getModuleName(classType:ClassType):String {
		return classType.name;
	}

	/**
	 * Check if a TypedExpr is being immediately called (part of a TCall expression)
	 * This is used to determine if a field access should be compiled as a function reference
	 * 
	 * @param expr The expression to check
	 * @return True if the expression is the function part of a TCall, false otherwise
	 */
	private function isBeingCalled(expr:TypedExpr):Bool {
		// This is a simplified check - in a real implementation, we'd need to
		// traverse the parent AST to see if this expression is the function part of a TCall
		// For now, we'll return false to always generate function references when appropriate
		return false;
	}

	/**
	 * Get the arity (number of parameters) for a function by name
	 * 
	 * @param functionName The function name to look up
	 * @return The arity of the function, or 1 as a reasonable default
	 */
	private function getFunctionArity(functionName:String):Int {
		if (currentClassType != null) {
			// Look for static methods in the current class
			var classFields = currentClassType.statics.get();
			for (field in classFields) {
				if (field.name == functionName) {
					switch (field.type) {
						case TFun(args, _):
							return args.length;
						case _:
					}
				}
			}

			// Look for instance methods
			var instanceFields = currentClassType.fields.get();
			for (field in instanceFields) {
				if (field.name == functionName) {
					switch (field.type) {
						case TFun(args, _):
							return args.length;
						case _:
					}
				}
			}
		}

		// Default to arity 1 for unknown functions
		return 1;
	}

	/**
	 * Compile a block of expressions while preserving inline context across all expressions.
	 * This is crucial for handling Haxe's inline function expansion correctly.
	 */
	/**
	 * Set case arm compilation context
	 */
	public function setCaseArmContext(inCaseArm:Bool):Void {
		isCompilingCaseArm = inCaseArm;
	}

	/**
	 * Clear parameter mapping after function compilation
	 */
	public function clearFunctionParameterMapping():Void {
		currentFunctionParameterMap.clear();
		// Reset array desugaring tracking after function compilation
		isCompilingAbstractMethod = false;
	}

	/**
	 * Extract the lambda parameter variable from a loop body that contains a TFunction
	 * 
	 * This is used for array method transformations (map, filter) where we need to 
	 * identify the lambda parameter to substitute it with the target variable name.
	 */
	private function getLambdaParameterFromBody(expr:TypedExpr):Null<TVar> {
		switch (expr.expr) {
			case TFunction(func):
				// Found the lambda function - return its first parameter
				if (func.args.length > 0) {
					return func.args[0].v;
				}
			case TBlock(exprs):
				// Look through block for lambda function
				for (e in exprs) {
					var result = getLambdaParameterFromBody(e);
					if (result != null)
						return result;
				}
			case TBinop(_, e1, e2):
				// Check both operands
				var result = getLambdaParameterFromBody(e1);
				if (result != null)
					return result;
				return getLambdaParameterFromBody(e2);
			case TCall(e, args):
				// Check function and arguments
				var result = getLambdaParameterFromBody(e);
				if (result != null)
					return result;
				for (arg in args) {
					result = getLambdaParameterFromBody(arg);
					if (result != null)
						return result;
				}
			case TIf(econd, eif, eelse):
				// Check condition and branches
				var result = getLambdaParameterFromBody(econd);
				if (result != null)
					return result;
				result = getLambdaParameterFromBody(eif);
				if (result != null)
					return result;
				if (eelse != null) {
					result = getLambdaParameterFromBody(eelse);
					if (result != null)
						return result;
				}
			case _:
				// Other expression types don't contain lambda functions
		}
		return null;
	}

	/**
	 * Helper function to determine if a variable should be substituted in loop contexts
	 * @param varName The variable name to check
	 * @param sourceVar The specific source variable we're looking for (null for aggressive mode)
	 * @param isAggressiveMode Whether to substitute any non-system variable
	 */
	public function shouldSubstituteVariable(varName:String, sourceVar:String = null, isAggressiveMode:Bool = false):Bool {
		// Don't substitute system variables (starting with g_ or temp_)
		if (varName.indexOf("g_") == 0 || varName.indexOf("temp_") == 0) {
			return false;
		}

		if (sourceVar != null) {
			// Exact match mode - only substitute the specific variable
			return varName == sourceVar;
		}

		if (isAggressiveMode) {
			// Aggressive mode - only substitute when we're actually in a loop context
			// This prevents function parameters like "transform" from being substituted
			return isInLoopContext;
		}

		// Default: don't substitute
		return false;
	}

	/**
	 * Compile expression with variable substitution using TVar object comparison
	 */
	// Loop compilation is handled through AST transformation to Elixir's functional constructs.
	// Loops are transformed into recursive functions or Enum operations as appropriate.

	/**
	 * Get field name from field access
	 * Handles @:native annotations on extern methods
	 */
	/**
	 * Get field name with proper @:native annotation support
	 * 
	 * WHY: @:native annotations allow library authors to specify exact Elixir names
	 * WHAT: Uses Reflaxe's standardized NameMetaHelper for consistent metadata handling
	 * HOW: Delegates to getFieldAccessNameMeta() and getNameOrNative() for proper extraction
	 * 
	 * ARCHITECTURE: This replaces manual metadata extraction with Reflaxe's standardized
	 * infrastructure, ensuring consistent handling of @:native across all field access types.
	 */
	public function getFieldName(fa:FieldAccess):String {
		// Use Reflaxe's standardized helper instead of manual extraction
		var nameMeta = NameMetaHelper.getFieldAccessNameMeta(fa);
		var name = nameMeta.getNameOrNative();

		// Convert to snake_case for Elixir if not already specified by @:native
		return if (nameMeta.hasMeta(":native")) {
			name; // Use exact name from @:native annotation
		} else {
			reflaxe.elixir.ast.NameUtils.toSnakeCase(name); // Convert to snake_case for idiomatic Elixir
		}
	}

	/**
	 * Check if a string can be a valid Elixir atom name
	 * Elixir atom rules: start with lowercase/underscore, contain alphanumeric/underscore
	 */
	private function isValidAtomName(name:String):Bool {
		if (name == null || name.length == 0)
			return false;

		// Check first character: must be lowercase letter or underscore
		var firstChar = name.charAt(0);
		if (!((firstChar >= 'a' && firstChar <= 'z') || firstChar == '_')) {
			return false;
		}

		// Check remaining characters: alphanumeric or underscore
		for (i in 1...name.length) {
			var char = name.charAt(i);
			if (!((char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || (char >= '0' && char <= '9') || char == '_')) {
				return false;
			}
		}

		return true;
	}

	/**
	 * Extract an array of strings from a macro expression
	 * Used for extracting annotation parameters like @:changeset(["field1", "field2"], ["required"])
	 * WHY: Annotations store their parameters as Expr values that need to be parsed
	 * WHAT: Extracts string values from array expressions at compile time
	 * HOW: Pattern matches on EArrayDecl and extracts CString constants
	 */
	private function extractStringArrayFromExpr(expr:Expr):Array<String> {
		if (expr == null)
			return [];

		switch (expr.expr) {
			case EArrayDecl(values):
				var result = [];
				for (value in values) {
					switch (value.expr) {
						case EConst(CString(s, _)):
							result.push(s);
						default:
							// Skip non-string values
					}
				}
				return result;
			default:
				return [];
		}
	}

	private function extractStringArrayFromNamedField(fields:Array<ObjectField>, fieldName:String):Array<String> {
		for (field in fields) {
			if (field.field == fieldName) {
				return extractStringArrayFromExpr(field.expr);
			}
		}
		return [];
	}

	private function extractChangesetNamedArgs(params:Array<Expr>):Null<{castFields:Array<String>, validateFields:Array<String>}> {
		var castFields:Null<Array<String>> = null;
		var validateFields:Null<Array<String>> = null;
		var matchedAny = false;

		for (param in params) {
			switch (param.expr) {
				case ECall(callee, args):
					switch (callee.expr) {
						case EConst(CIdent(name)):
							if (args != null && args.length > 0) {
								switch (name) {
									case "cast":
										castFields = extractStringArrayFromExpr(args[0]);
										matchedAny = true;
									case "validate", "required":
										validateFields = extractStringArrayFromExpr(args[0]);
										matchedAny = true;
									default:
								}
							}
						default:
					}
				default:
			}
		}

		if (!matchedAny || castFields == null) {
			return null;
		}

		return {
			castFields: castFields,
			validateFields: validateFields != null ? validateFields : []
		};
	}

	/**
	 * Extract router route definitions for @:router modules.
	 *
	 * Preferred source: module-level `final routes = [...]`
	 * Compatibility source: `@:routes([...])`
	 */
	private function collectClassAndStaticMetadata(classType:ClassType, primaryName:String, alternateName:String):Array<MetadataEntry> {
		var entries:Array<MetadataEntry> = [];

		var classPrimary = classType.meta.extract(primaryName);
		if (classPrimary != null && classPrimary.length > 0) {
			entries = entries.concat(classPrimary);
		}

		var classAlternate = classType.meta.extract(alternateName);
		if (classAlternate != null && classAlternate.length > 0) {
			entries = entries.concat(classAlternate);
		}

		switch (classType.kind) {
			case KModuleFields(_):
				for (staticField in classType.statics.get()) {
					var staticPrimary = staticField.meta.extract(primaryName);
					if (staticPrimary != null && staticPrimary.length > 0) {
						entries = entries.concat(staticPrimary);
					}

					var staticAlternate = staticField.meta.extract(alternateName);
					if (staticAlternate != null && staticAlternate.length > 0) {
						entries = entries.concat(staticAlternate);
					}
				}
			default:
		}

		var moduleFieldMeta = ModuleFieldMetadataRegistry.extractMetadata(classType, primaryName, alternateName);
		if (moduleFieldMeta != null && moduleFieldMeta.length > 0) {
			entries = entries.concat(moduleFieldMeta);
		}

		return entries;
	}

	private function hasClassOrStaticMetadata(classType:ClassType, primaryName:String, alternateName:String):Bool {
		return collectClassAndStaticMetadata(classType, primaryName, alternateName).length > 0;
	}

	private function canResolveTypePath(typePath:String):Bool {
		if (typePath == null || typePath.length == 0)
			return false;
		try {
			Context.getType(typePath);
			return true;
		} catch (_:Dynamic) {
			return false;
		}
	}

	private function applyImportLookup(typePath:String, directImports:Map<String, String>, wildcardImports:Array<String>):Null<String> {
		if (typePath == null || typePath.length == 0 || directImports == null)
			return null;

		var directMatch = directImports.get(typePath);
		if (directMatch != null && directMatch.length > 0)
			return directMatch;

		var dotIndex = typePath.indexOf(".");
		if (dotIndex > 0) {
			var alias = typePath.substr(0, dotIndex);
			if (directImports.exists(alias)) {
				var aliasTarget = directImports.get(alias);
				var remainder = typePath.substr(dotIndex + 1);
				if (aliasTarget != null && aliasTarget.length > 0 && remainder != null && remainder.length > 0)
					return aliasTarget + "." + remainder;
			}
		}

		if (typePath.indexOf(".") == -1 && wildcardImports != null) {
			for (wildcardImport in wildcardImports) {
				var candidate = wildcardImport + "." + typePath;
				if (canResolveTypePath(candidate))
					return candidate;
			}
		}

		return null;
	}

	private function getSourceImportLookup(filePath:String):{directImports:Map<String, String>, wildcardImports:Array<String>} {
		if (filePath == null || filePath.length == 0) {
			return {
				directImports: new Map<String, String>(),
				wildcardImports: []
			};
		}

		if (sourceImportResolutionCache.exists(filePath)) {
			return sourceImportResolutionCache.get(filePath);
		}

		var directImports = new Map<String, String>();
		var wildcardImports:Array<String> = [];
		var aliasPattern = ~/^import\s+([A-Za-z0-9_.]+)\s+as\s+([A-Za-z0-9_]+)\s*;$/;
		var wildcardPattern = ~/^import\s+([A-Za-z0-9_.]+)\.\*\s*;$/;
		var importPattern = ~/^import\s+([A-Za-z0-9_.]+)\s*;$/;

		try {
			if (sys.FileSystem.exists(filePath)) {
				var content = sys.io.File.getContent(filePath);
				for (line in content.split("\n")) {
					var trimmed = StringTools.trim(line);
					if (trimmed.length == 0
						|| StringTools.startsWith(trimmed, "//")
						|| StringTools.startsWith(trimmed, "/*")
						|| StringTools.startsWith(trimmed, "*")) {
						continue;
					}

					if (aliasPattern.match(trimmed)) {
						var importPath = aliasPattern.matched(1);
						var alias = aliasPattern.matched(2);
						if (alias != null && alias.length > 0 && importPath != null && importPath.length > 0)
							directImports.set(alias, importPath);
						continue;
					}

					if (wildcardPattern.match(trimmed)) {
						var wildcardPath = wildcardPattern.matched(1);
						if (wildcardPath != null && wildcardPath.length > 0 && wildcardImports.indexOf(wildcardPath) == -1)
							wildcardImports.push(wildcardPath);
						continue;
					}

					if (importPattern.match(trimmed)) {
						var importPath = importPattern.matched(1);
						if (importPath != null && importPath.length > 0) {
							var importParts = importPath.split(".");
							var shortName = importParts[importParts.length - 1];
							if (shortName != null && shortName.length > 0)
								directImports.set(shortName, importPath);
						}
					}
				}
			}
		} catch (_:Dynamic) {}

		var lookup = {
			directImports: directImports,
			wildcardImports: wildcardImports
		};
		sourceImportResolutionCache.set(filePath, lookup);
		return lookup;
	}

	private function resolveTypePathFromLocalImports(classType:ClassType, typePath:String, ?sourcePos:haxe.macro.Expr.Position):String {
		if (typePath == null || typePath.length == 0)
			return typePath;

		var imports = Context.getLocalImports();
		if (imports != null) {
			var directImports = new Map<String, String>();
			var wildcardImports:Array<String> = [];

			for (importExpr in imports) {
				if (importExpr == null || importExpr.path == null || importExpr.path.length == 0)
					continue;

				var importParts = [for (segment in importExpr.path) segment.name];
				var importPath = importParts.join(".");
				if (importPath == null || importPath.length == 0)
					continue;

				switch (importExpr.mode) {
					case IAsName(alias):
						if (alias != null && alias.length > 0)
							directImports.set(alias, importPath);
					case IAll:
						if (wildcardImports.indexOf(importPath) == -1)
							wildcardImports.push(importPath);
					case INormal:
						var importedName = importExpr.path[importExpr.path.length - 1].name;
						if (importedName != null && importedName.length > 0)
							directImports.set(importedName, importPath);
				}
			}

			var localImportMatch = applyImportLookup(typePath, directImports, wildcardImports);
			if (localImportMatch != null)
				return localImportMatch;
		}

		if (sourcePos != null) {
			try {
				var posInfo = Context.getPosInfos(sourcePos);
				if (posInfo != null && posInfo.file != null && posInfo.file.length > 0) {
					var lookup = getSourceImportLookup(posInfo.file);
					var sourceImportMatch = applyImportLookup(typePath, lookup.directImports, lookup.wildcardImports);
					if (sourceImportMatch != null)
						return sourceImportMatch;
				}
			} catch (_:Dynamic) {
				// Fall through to package/default resolution.
			}
		}

		if (typePath.indexOf(".") == -1 && classType != null && classType.module != null && classType.module.length > 0) {
			var moduleCandidate = classType.module + "." + typePath;
			if (canResolveTypePath(moduleCandidate))
				return moduleCandidate;
			if (classType.pack != null && classType.pack.length > 0 && classType.module.indexOf(".") == -1) {
				var qualifiedModuleCandidate = classType.pack.join(".") + "." + classType.module + "." + typePath;
				if (canResolveTypePath(qualifiedModuleCandidate))
					return qualifiedModuleCandidate;
			}
		}

		if (typePath.indexOf(".") == -1 && classType != null && classType.pack != null && classType.pack.length > 0) {
			var packageCandidate = classType.pack.join(".") + "." + typePath;
			if (canResolveTypePath(packageCandidate))
				return packageCandidate;
		}

		return typePath;
	}

	private function extractRoutesFieldExpr(classType:ClassType):Null<Expr> {
		if (classType == null)
			return null;
		return ModuleFieldMetadataRegistry.extractFieldInitializer(classType, "routes");
	}

	private function extractRoutesMetaExpr(classType:ClassType):Null<Expr> {
		var routesMeta = collectClassAndStaticMetadata(classType, ":routes", "routes");
		if (routesMeta == null || routesMeta.length == 0)
			return null;

		var entry = routesMeta[0];
		if (entry.params == null || entry.params.length == 0) {
			Context.error("@:routes annotation requires an array parameter: @:routes([...])", entry.pos);
			return null;
		}

		return entry.params[0];
	}

	private function resolveRouterRoutesSource(classType:ClassType):Null<RouterRoutesSource> {
		var routesFieldExpr = extractRoutesFieldExpr(classType);
		var routesMetaExpr = extractRoutesMetaExpr(classType);

		if (routesFieldExpr != null && routesMetaExpr != null) {
			Context.warning('Both module-level `final routes = [...]` and `@:routes([...])` were found for router declaration. '
				+ 'Using module-level `routes` and ignoring `@:routes`.',
				routesFieldExpr.pos);
		}

		if (routesFieldExpr != null) {
			return {
				expr: routesFieldExpr,
				source: "module-level routes field"
			};
		}

		if (routesMetaExpr != null) {
			return {
				expr: routesMetaExpr,
				source: "@:routes annotation"
			};
		}

		return null;
	}

	private function extractRouterRoutesFromMeta(classType:ClassType):Null<Array<RouterRouteMeta>> {
		var routesSource = resolveRouterRoutesSource(classType);
		if (routesSource == null)
			return null;
		var routesExpr = routesSource.expr;

		var strictTypedRouteControllerRefs = Context.defined("router_strict_typed_refs");

		function extractDotPath(expr:Expr):Null<String> {
			return switch (expr.expr) {
				case EConst(CIdent(ident)):
					ident;
				case EField(e, field):
					var base = extractDotPath(e);
					base != null ? (base + "." + field) : field;
				default:
					null;
			};
		}

		function extractStringValue(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position):Null<String> {
			return switch (expr.expr) {
				case EConst(CString(s, _)): s;
				case EConst(CIdent(ident)): ident;
				default:
					Context.error('${fieldName} must be a string literal or identifier', pos);
					null;
			};
		}

		function extractMethodValue(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position):Null<String> {
			return switch (expr.expr) {
				case EConst(CString(s, _)): s;
				case EConst(CIdent(ident)): ident;
				case EField(e, field):
					var base = extractDotPath(e);
					if (base != null && (base == "HttpMethod" || StringTools.endsWith(base, ".HttpMethod"))) {
						field;
					} else {
						Context.error('${fieldName} must be a string literal or HttpMethod value', pos);
						null;
					}
				default:
					Context.error('${fieldName} must be a string literal or HttpMethod value', pos);
					null;
			};
		}

		function extractControllerValue(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position):Null<String> {
			return switch (expr.expr) {
				case EConst(CString(s, _)): s;
				default:
					var path = extractDotPath(expr);
					if (path == null) {
						Context.error('${fieldName} must be a string literal or type reference (e.g. controllers.UserController)', pos);
						null;
					} else {
						path;
					}
			};
		}

		function extractActionValue(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position):Null<String> {
			return switch (expr.expr) {
				case EConst(CString(s, _)): s;
				case EConst(CIdent(ident)): ident;
				case EField(_, field): field; // Type.method references (e.g. TodoLive.index)
				default:
					Context.error('${fieldName} must be a string literal, identifier, or method reference (e.g. TodoLive.index)', pos);
					null;
			};
		}

		function isStringLiteral(expr:Expr):Bool {
			return switch (expr.expr) {
				case EConst(CString(_, _)): true;
				default: false;
			};
		}

		function emitLegacyControllerLiteralDiagnostic(routeName:Null<String>, pos:haxe.macro.Expr.Position):Void {
			var resolvedRouteName = (routeName != null && routeName != "") ? routeName : "<unnamed>";
			var recommendation = 'Route "${resolvedRouteName}" uses a legacy string literal for controller. Prefer a typed controller reference (for example controllers.UserController).';
			if (strictTypedRouteControllerRefs) {
				Context.error(recommendation + " Use @:route for intentionally legacy/manual string routing.", pos);
			} else {
				Context.warning(recommendation + " Pass -D router_strict_typed_refs to enforce this as an error.", pos);
			}
		}

		function parseRoute(routeExpr:Expr):Null<RouterRouteMeta> {
			return switch (routeExpr.expr) {
				case EObjectDecl(fields):
					var name:Null<String> = null;
					var method:Null<String> = null;
					var path:Null<String> = null;
					var controller:Null<String> = null;
					var action:Null<String> = null;
					var pipeline:Null<String> = null;
					var controllerWasStringLiteral = false;
					var controllerPos = routeExpr.pos;

					for (f in fields) {
						switch (f.field) {
							case "name":
								name = extractStringValue(f.expr, "name", f.expr.pos);
							case "method":
								method = extractMethodValue(f.expr, "method", f.expr.pos);
							case "path":
								path = extractStringValue(f.expr, "path", f.expr.pos);
							case "controller":
								controllerWasStringLiteral = isStringLiteral(f.expr);
								controllerPos = f.expr.pos;
								controller = extractControllerValue(f.expr, "controller", f.expr.pos);
							case "action":
								action = extractActionValue(f.expr, "action", f.expr.pos);
							case "pipeline":
								pipeline = extractStringValue(f.expr, "pipeline", f.expr.pos);
							default:
								Context.warning('Unknown route field: ${f.field}', f.expr.pos);
						}
					}

					if (name == null || method == null || path == null) {
						Context.error("Route definition requires name/method/path", routeExpr.pos);
						return null;
					}

					// Validate required fields for method kinds we support.
					// LIVE_DASHBOARD and MAILBOX are special: controller/action are optional.
					var methodUpper = method.toUpperCase();
					if (methodUpper != "LIVE_DASHBOARD" && methodUpper != "MAILBOX") {
						if (controller == null)
							Context.error('Route "${name}" is missing controller', routeExpr.pos);
						if (action == null)
							Context.error('Route "${name}" is missing action', routeExpr.pos);
					}

					if (controllerWasStringLiteral && controller != null && controller != "") {
						emitLegacyControllerLiteralDiagnostic(name, controllerPos);
					}

					return {
						name: name,
						method: methodUpper,
						path: path,
						controller: controller,
						action: action,
						pipeline: pipeline
					};

				default:
					switch (routeExpr.expr) {
						case ECall(_, _):
							// Typed RouterDsl nodes are handled by extractRouterDslNodesFromMeta().
							null;
						default:
							Context.error("Each route entry must be an object: {name: ..., method: ..., path: ...}", routeExpr.pos);
							null;
					}
			}
		}

		return switch (routesExpr.expr) {
			case EArrayDecl(values):
				var routes:Array<RouterRouteMeta> = [];
				for (r in values) {
					var parsed = parseRoute(r);
					if (parsed != null)
						routes.push(parsed);
				}
				routes.length > 0 ? routes : null;
			default:
				Context.error('Router routes from ${routesSource.source} must be an array: final routes = [...]', routesExpr.pos);
				null;
		};
	}

	/**
	 * Extract typed/nested router DSL nodes from router route declarations.
	 *
	 * Supports:
	 * - legacy flat object routes (`{name, method, path, ...}`)
	 * - typed builder nodes (`RouterDsl.scope(...)`, `RouterDsl.get(...)`, ...)
	 */
	private function extractRouterDslNodesFromMeta(classType:ClassType):Null<Array<RouterNodeMeta>> {
		var routesSource = resolveRouterRoutesSource(classType);
		if (routesSource == null)
			return null;

		var routesExpr = routesSource.expr;
		var routeValues:Array<Expr> = switch (routesExpr.expr) {
			case EArrayDecl(values):
				values;
			default:
				Context.error('Router routes from ${routesSource.source} must be an array: final routes = [...]', routesExpr.pos);
				return null;
		};
		var containsTypedDslCalls = false;
		for (value in routeValues) {
			switch (value.expr) {
				case ECall(_, _):
					containsTypedDslCalls = true;
				default:
			}
			if (containsTypedDslCalls) {
				break;
			}
		}
		if (!containsTypedDslCalls) {
			// Legacy object routes are handled by extractRouterRoutesFromMeta.
			return null;
		}

		var strictTypedRouteControllerRefs = Context.defined("router_strict_typed_refs");

		function extractDotPath(expr:Expr):Null<String> {
			return switch (expr.expr) {
				case EConst(CIdent(ident)):
					ident;
				case EField(e, field):
					var base = extractDotPath(e);
					base != null ? (base + "." + field) : field;
				default:
					null;
			};
		}

		function normalizeOptionKey(key:String):String {
			return switch (key) {
				case "asName", "as":
					"as";
				case "privateData", "private":
					"private";
				case "aliasModule", "alias":
					"alias";
				case "paramsContract", "params":
					"params_contract";
				case "initArgs", "init_args":
					"init_args";
				case "rootLayout", "root_layout":
					"root_layout";
				case "onMount", "on_mount":
					"on_mount";
				case "mailboxModule", "mailbox_module":
					"mailbox_module";
				case "metricsModule", "metrics_module":
					"metrics_module";
				default:
					NameUtils.toSnakeCase(key);
			}
		}

		function extractStringValue(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position):Null<String> {
			return switch (expr.expr) {
				case EConst(CString(s, _)): s;
				case EConst(CIdent(ident)): ident;
				default:
					Context.error('${fieldName} must be a string literal or identifier', pos);
					null;
			};
		}

		function extractMethodValue(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position):Null<String> {
			return switch (expr.expr) {
				case EConst(CString(s, _)): s.toUpperCase();
				case EConst(CIdent(ident)): ident.toUpperCase();
				case EField(e, field):
					var base = extractDotPath(e);
					if (base != null && (base == "HttpMethod" || StringTools.endsWith(base, ".HttpMethod"))) {
						field.toUpperCase();
					} else {
						Context.error('${fieldName} must be a string literal or HttpMethod value', pos);
						null;
					}
				default:
					Context.error('${fieldName} must be a string literal or HttpMethod value', pos);
					null;
			};
		}

		function normalizeImportedTypePath(path:String, sourcePos:haxe.macro.Expr.Position):String {
			var fromModuleFieldRegistry = ModuleFieldMetadataRegistry.resolveImportedTypePath(classType, path);
			if (fromModuleFieldRegistry != null && fromModuleFieldRegistry != path)
				return fromModuleFieldRegistry;
			return resolveTypePathFromLocalImports(classType, path, sourcePos);
		}

		function normalizeClassLiteralTypePath(path:String, sourcePos:haxe.macro.Expr.Position):String {
			if (path == null || path.length == 0) {
				return path;
			}

			var normalized = StringTools.trim(path);
			if (StringTools.startsWith(normalized, "Class<") && StringTools.endsWith(normalized, ">")) {
				normalized = normalized.substr(6, normalized.length - 7);
			}

			return normalizeImportedTypePath(normalized, sourcePos);
		}

		function resolveClassTypePath(resolvedClass:ClassType):String {
			var classPath = resolvedClass.pack.length > 0 ? resolvedClass.pack.join(".") + "." + resolvedClass.name : resolvedClass.name;
			var modulePath = resolvedClass.module;

			if (modulePath == null || modulePath.length == 0 || modulePath == resolvedClass.name) {
				return classPath;
			}

			if (resolvedClass.pack != null && resolvedClass.pack.length > 0 && modulePath.indexOf(".") == -1) {
				return resolvedClass.pack.join(".") + "." + modulePath + "." + resolvedClass.name;
			}

			return modulePath + "." + resolvedClass.name;
		}

		function resolveTypePathFromType(resolvedType:Type):Null<String> {
			return switch (resolvedType) {
				case TMono(monoRef):
					var resolvedMono = monoRef.get();
					resolvedMono != null ? resolveTypePathFromType(resolvedMono) : null;
				case TLazy(loader):
					resolveTypePathFromType(loader());
				case TInst(classRef, params):
					var resolvedClass = classRef.get();
					if (resolvedClass.name == "Class" && params != null && params.length == 1) {
						resolveTypePathFromType(params[0]);
					} else {
						resolveClassTypePath(resolvedClass);
					}
				case TType(typeRef, params):
					var resolvedTypedef = typeRef.get();
					if (resolvedTypedef.name == "Class" && params != null && params.length == 1) {
						resolveTypePathFromType(params[0]);
					} else {
						resolvedTypedef.pack.length > 0 ? resolvedTypedef.pack.join(".") + "." + resolvedTypedef.name : resolvedTypedef.name;
					}
				case TAbstract(abstractRef, params):
					var resolvedAbstract = abstractRef.get();
					if (resolvedAbstract.name == "Class" && params != null && params.length == 1) {
						resolveTypePathFromType(params[0]);
					} else {
						resolvedAbstract.pack.length > 0 ? resolvedAbstract.pack.join(".") + "." + resolvedAbstract.name : resolvedAbstract.name;
					}
				default:
					null;
			};
		}

		function resolveTypePathFromExpr(expr:Expr, fallbackPath:String):String {
			var normalizedFallback = normalizeClassLiteralTypePath(fallbackPath, expr != null ? expr.pos : null);
			try {
				var resolvedPath = resolveTypePathFromType(Context.typeof(expr));
				var normalizedResolved = resolvedPath != null ? normalizeClassLiteralTypePath(resolvedPath, expr != null ? expr.pos : null) : null;
				if (normalizedResolved != null && normalizedResolved.length > 0) {
					if (normalizedFallback != null && normalizedFallback.indexOf(".") != -1 && normalizedResolved.indexOf(".") == -1) {
						return normalizedFallback;
					}
					return normalizedResolved;
				}
				return normalizedFallback;
			} catch (_:Dynamic) {
				return normalizedFallback;
			}
		}

		function stripLocalModulePrefix(path:String):String {
			if (path == null || path.length == 0)
				return path;

			var modulePath = classType.module;
			if (modulePath != null && modulePath.length > 0 && StringTools.startsWith(path, modulePath + ".")) {
				return path.substr(modulePath.length + 1);
			}

			if (classType.pack != null && classType.pack.length > 0 && modulePath != null && modulePath.length > 0 && modulePath.indexOf(".") == -1) {
				var qualifiedModulePath = classType.pack.join(".") + "." + modulePath;
				if (StringTools.startsWith(path, qualifiedModulePath + ".")) {
					return path.substr(qualifiedModulePath.length + 1);
				}
			}

			return path;
		}

		function extractTypeRef(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position, allowStringLiteral:Bool,
				normalizeForRouterOutput:Bool):Null<String> {
			return switch (expr.expr) {
				case EConst(CString(s, _)):
					if (allowStringLiteral) {
						s;
					} else {
						Context.error('${fieldName} must be a type reference (string literals are not allowed in typed RouterDsl)', pos);
						null;
					}
				default:
					var path = extractDotPath(expr);
					if (path == null) {
						Context.error('${fieldName} must be a type/module reference', pos);
						null;
					} else {
						var resolvedPath = resolveTypePathFromExpr(expr, path);
						try {
							Context.getType(resolvedPath);
						} catch (_:Dynamic) {
							Context.error('Could not resolve ${fieldName} type: ${resolvedPath}', pos);
						}
						normalizeForRouterOutput ? stripLocalModulePrefix(resolvedPath) : resolvedPath;
					}
			};
		}

		function extractActionRef(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position, allowStringLiteral:Bool):Null<String> {
			return switch (expr.expr) {
				case EField(_, field):
					field;
				case EConst(CIdent(ident)):
					ident;
				case EConst(CString(s, _)):
					if (allowStringLiteral) {
						s;
					} else {
						Context.error('${fieldName} must be a method reference (e.g. controllers.UserController.index)', pos);
						null;
					}
				default:
					Context.error('${fieldName} must be a method reference', pos);
					null;
			};
		}

		function parseOptionValue(expr:Expr):RouterMetaValue {
			return switch (expr.expr) {
				case EConst(CString(s, _)):
					ROString(s);
				case EConst(CInt(i, _)):
					ROInt(Std.parseInt(i));
				case EConst(CIdent(id)):
					switch (id) {
						case "true":
							ROBool(true);
						case "false":
							ROBool(false);
						default:
							ROAtom(id);
					}
				case EField(_, _):
					var path = extractDotPath(expr);
					path != null ? ROVar(path) : ROString(ExprTools.toString(expr));
				case EArrayDecl(items):
					ROList([for (item in items) parseOptionValue(item)]);
				case EObjectDecl(fields):
					var pairs:Array<RouterOptionMeta> = [];
					for (field in fields) {
						pairs.push({
							key: normalizeOptionKey(field.field),
							value: parseOptionValue(field.expr)
						});
					}
					ROMap(pairs);
				default:
					var pathFallback = extractDotPath(expr);
					pathFallback != null ? ROVar(pathFallback) : ROString(ExprTools.toString(expr));
			};
		}

		function resourceActionNameFromIdentifier(identifier:String):Null<String> {
			return switch (identifier) {
				case "resourceIndex":
					"index";
				case "resourceShow":
					"show";
				case "resourceNew":
					"new";
				case "resourceCreate":
					"create";
				case "resourceEdit":
					"edit";
				case "resourceUpdate":
					"update";
				case "resourceDelete":
					"delete";
				default:
					null;
			};
		}

		function resourceActionNameFromString(value:String, pos:haxe.macro.Expr.Position):String {
			return switch (value) {
				case "index" | "show" | "new" | "create" | "edit" | "update" | "delete":
					value;
				default:
					Context.error('Resource actions must be one of: "index", "show", "new", "create", "edit", "update", "delete".', pos);
					value;
			};
		}

		function parseResourceActionOptionValue(expr:Expr):RouterMetaValue {
			return switch (expr.expr) {
				case EArrayDecl(items):
					ROList([
						for (item in items)
							switch (item.expr) {
								case EConst(CString(value, _)):
									ROString(resourceActionNameFromString(value, item.pos));
								case EConst(CIdent(identifier)):
									var actionName = resourceActionNameFromIdentifier(identifier);
									actionName != null ? ROString(actionName) : parseOptionValue(item);
								case EField(_, field):
									var actionName = resourceActionNameFromIdentifier(field);
									actionName != null ? ROString(actionName) : parseOptionValue(item);
								default:
									parseOptionValue(item);
							}
					]);
				default:
					parseOptionValue(expr);
			};
		}

		function parseOptionsExpr(expr:Null<Expr>):Array<RouterOptionMeta> {
			if (expr == null) {
				return [];
			}
			return switch (expr.expr) {
				case EObjectDecl(fields):
					var pairs:Array<RouterOptionMeta> = [];
					for (field in fields) {
						var normalizedKey = normalizeOptionKey(field.field);
						var parsedValue = switch (normalizedKey) {
							case "params_contract", "alias", "mailbox_module", "metrics_module":
								var normalizeForRouterOutput = normalizedKey != "params_contract";
								var path = extractTypeRef(field.expr, field.field, field.expr.pos, false, normalizeForRouterOutput);
								path != null ? ROVar(path) : parseOptionValue(field.expr);
							case "only", "except":
								parseResourceActionOptionValue(field.expr);
							default:
								parseOptionValue(field.expr);
						}
						pairs.push({
							key: normalizedKey,
							value: parsedValue
						});
					}
					pairs;
				default:
					Context.error("Options argument must be an object literal", expr.pos);
					[];
			};
		}

		function getOption(options:Array<RouterOptionMeta>, key:String):Null<RouterMetaValue> {
			for (option in options) {
				if (option.key == key) {
					return option.value;
				}
			}
			return null;
		}

		function parsePathParams(path:String):Array<String> {
			var params:Array<String> = [];
			if (path == null || path == "") {
				return params;
			}
			var segments = path.split("/");
			for (segment in segments) {
				if (segment == null || segment == "") {
					continue;
				}
				if (StringTools.startsWith(segment, ":")) {
					params.push(segment.substr(1));
				} else if (StringTools.startsWith(segment, "*")) {
					params.push(segment.substr(1));
				}
			}
			return params;
		}

		function collectTypeFieldNames(t:Type, result:Array<String>):Void {
			switch (t) {
				case TAnonymous(a):
					for (field in a.get().fields) {
						result.push(field.name);
					}
				case TType(td, _):
					collectTypeFieldNames(td.get().type, result);
				case TInst(c, _):
					for (field in c.get().fields.get()) {
						result.push(field.name);
					}
				default:
			}
		}

		function singularizePathSegment(segment:String):String {
			if (StringTools.endsWith(segment, "ies") && segment.length > 3) {
				return segment.substr(0, segment.length - 3) + "y";
			}
			if (StringTools.endsWith(segment, "s") && segment.length > 1) {
				return segment.substr(0, segment.length - 1);
			}
			return segment;
		}

		function toPascalCaseName(value:String):String {
			var normalized = ~/[^A-Za-z0-9_]+/g.replace(value, "_");
			var parts = normalized.split("_");
			var result = "";
			for (part in parts) {
				if (part == null || part == "") {
					continue;
				}
				result += part.substr(0, 1).toUpperCase() + part.substr(1).toLowerCase();
			}
			return result == "" ? "Route" : result;
		}

		function suggestParamsContractName(path:String):String {
			var staticSegments:Array<String> = [];
			for (segment in path.split("/")) {
				if (segment == null || segment == "" || StringTools.startsWith(segment, ":") || StringTools.startsWith(segment, "*")) {
					continue;
				}
				staticSegments.push(segment);
			}
			if (staticSegments.length == 0) {
				return "RoutePathParams";
			}

			var lastStaticSegment = staticSegments[staticSegments.length - 1];
			return toPascalCaseName(singularizePathSegment(lastStaticSegment)) + "PathParams";
		}

		function suggestedParamFieldType(paramName:String):String {
			var normalizedParamName = NameUtils.toSnakeCase(paramName);
			return (normalizedParamName == "id" || StringTools.endsWith(normalizedParamName, "_id")) ? "Int" : "String";
		}

		function buildParamsContractSuggestion(path:String, pathParams:Array<String>):String {
			var contractName = suggestParamsContractName(path);
			var fields = [
				for (param in pathParams)
					'  var ${NameUtils.toSnakeCase(param)}:${suggestedParamFieldType(param)};'
			].join("\n");
			return 'Add a paramsContract typedef and pass it in the route options:\n\n'
				+ 'typedef ${contractName} = {\n${fields}\n}\n\n'
				+ 'get("${path}", Controller, Controller.action, {paramsContract: ${contractName}})';
		}

		function validatePathParamsContract(path:String, options:Array<RouterOptionMeta>, pos:haxe.macro.Expr.Position):Void {
			var pathParams = parsePathParams(path);
			if (pathParams.length == 0) {
				return;
			}

			var contract = getOption(options, "params_contract");
			if (contract == null) {
				Context.error('Route path "${path}" contains path params (${pathParams.join(", ")}) but no paramsContract was provided in options.\n\n'
					+ buildParamsContractSuggestion(path, pathParams),
					pos);
				return;
			}

			var contractPath:Null<String> = switch (contract) {
				case ROVar(path):
					path;
				default:
					null;
			};

			if (contractPath == null) {
				Context.error("paramsContract must be a type reference", pos);
				return;
			}

			var contractType:Type = null;
			try {
				contractType = Context.getType(contractPath);
			} catch (e) {
				Context.error('Could not resolve paramsContract type: ${contractPath}', pos);
				return;
			}

			var fieldNames:Array<String> = [];
			collectTypeFieldNames(contractType, fieldNames);

			var normalizedFields = new Map<String, Bool>();
			for (fieldName in fieldNames) {
				normalizedFields.set(NameUtils.toSnakeCase(fieldName), true);
			}

			for (param in pathParams) {
				var normalizedParam = NameUtils.toSnakeCase(param);
				if (!normalizedFields.exists(normalizedParam)) {
					Context.error('paramsContract "${contractPath}" is missing field for path param "${param}"', pos);
				}
			}
		}

		function validateActionExists(controllerPath:String, actionName:String, pos:haxe.macro.Expr.Position):Void {
			if (controllerPath == null || actionName == null || controllerPath == "" || actionName == "") {
				return;
			}

			try {
				var controllerType = Context.getType(controllerPath);
				switch (controllerType) {
					case TInst(c, _):
						var classType = c.get();
						var found = false;
						for (field in classType.statics.get()) {
							if (field.name == actionName) {
								found = true;
								break;
							}
						}
						if (!found) {
							Context.error('Action "${actionName}" not found on controller/live module "${controllerPath}"', pos);
						}
					default:
						Context.error('Expected class type for controller/live module: ${controllerPath}', pos);
				}
			} catch (e) {
				Context.error('Could not resolve controller/live module "${controllerPath}"', pos);
			}
		}

		function extractCallName(expr:Expr):Null<String> {
			return switch (expr.expr) {
				case EConst(CIdent(name)):
					name;
				case EField(_, field):
					field;
				default:
					null;
			};
		}

		function unwrapExpr(expr:Expr):Expr {
			return switch (expr.expr) {
				case EParenthesis(inner):
					unwrapExpr(inner);
				case ECheckType(inner, _):
					unwrapExpr(inner);
				case EMeta(_, inner):
					unwrapExpr(inner);
				case ECast(inner, _):
					unwrapExpr(inner);
				default:
					expr;
			};
		}

		function isLikelyModulePath(path:String):Bool {
			if (path == null || path.length == 0) {
				return false;
			}
			if (StringTools.startsWith(path, "Elixir.")) {
				return true;
			}
			var firstDot = path.indexOf(".");
			var firstSegment = firstDot == -1 ? path : path.substr(0, firstDot);
			if (firstSegment == null || firstSegment.length == 0) {
				return false;
			}
			var firstChar = firstSegment.charAt(0);
			return firstChar >= "A" && firstChar <= "Z";
		}

		function extractTypedAtomToken(expr:Expr, fieldName:String, allowStringLiteral:Bool, factoryCall:String):Null<String> {
			var normalizedExpr = unwrapExpr(expr);
			return switch (normalizedExpr.expr) {
				case EConst(CIdent(identifier)):
					identifier;
				case EField(owner, field):
					var ownerPath = extractDotPath(owner);
					if (ownerPath == "RouterDsl" || (ownerPath != null && StringTools.endsWith(ownerPath, ".RouterDsl"))) {
						field;
					} else {
						var dotted = extractDotPath(normalizedExpr);
						if (dotted != null && !isLikelyModulePath(dotted)) {
							field;
						} else {
							Context.error('${fieldName} must be a typed token (use RouterDsl.${factoryCall} for custom names).', expr.pos);
							null;
						}
					}
				case EConst(CString(value, _)):
					if (allowStringLiteral) {
						value;
					} else {
						Context.error('${fieldName} must use typed tokens in RouterDsl.* APIs. Use ${factoryCall}("name") or the Unsafe variant for raw strings.',
							expr.pos);
						null;
					}
				case ECall(callee, args):
					var callName = extractCallName(callee);
					if (callName == factoryCall) {
						if (args.length != 1) {
							Context.error('RouterDsl.${factoryCall}(name) requires a single string literal argument.', expr.pos);
						}
						extractStringValue(args[0], fieldName, args[0].pos);
					} else {
						Context.error('${fieldName} must be a typed token (identifier or RouterDsl.${factoryCall}("name")).', expr.pos);
						null;
					}
				default:
					Context.error('${fieldName} must be a typed token.', expr.pos);
					null;
			};
		}

		function extractPipelineNameValue(expr:Expr, allowStringLiteral:Bool):Null<String> {
			return extractTypedAtomToken(expr, "pipeline", allowStringLiteral, "pipelineName");
		}

		function extractPlugTargetValue(expr:Expr, allowStringLiteral:Bool):Null<String> {
			var normalizedExpr = unwrapExpr(expr);
			return switch (normalizedExpr.expr) {
				case EConst(CString(targetValue, _)):
					if (allowStringLiteral) {
						targetValue;
					} else {
						Context.error('RouterDsl.plug(...) is typed. Use plug(accepts), plug(fetch_session), plug(MyPlugModule), or plugUnsafe("...").',
							expr.pos);
						null;
					}
				case ECall(callee, args):
					var callName = extractCallName(callee);
					if (callName == "plugName") {
						if (args.length != 1) {
							Context.error('RouterDsl.plugName(name) requires a single string literal argument.', expr.pos);
						}
						extractStringValue(args[0], "plug target", args[0].pos);
					} else {
						Context.error('plug target must be a typed plug token or module reference.', expr.pos);
						null;
					}
				default:
					var dottedPath = extractDotPath(normalizedExpr);
					if (dottedPath == null) {
						Context.error('plug target must be a typed plug token or module reference.', expr.pos);
						null;
					} else if (isLikelyModulePath(dottedPath)) {
						var resolvedModulePath = extractTypeRef(normalizedExpr, "plug module", expr.pos, false, false);
						resolvedModulePath != null ? stripLocalModulePrefix(resolvedModulePath) : null;
					} else {
						var lastDot = dottedPath.lastIndexOf(".");
						lastDot == -1 ? dottedPath : dottedPath.substr(lastDot + 1);
					}
			};
		}

		var parseNodeRef:Expr->Null<RouterNodeMeta> = null;

		function parseChildren(expr:Expr):Array<RouterNodeMeta> {
			return switch (expr.expr) {
				case EArrayDecl(items):
					var nodes:Array<RouterNodeMeta> = [];
					for (item in items) {
						var parsed = parseNodeRef(item);
						if (parsed != null) {
							nodes.push(parsed);
						}
					}
					nodes;
				default:
					Context.error("Children argument must be an array of RouterDsl nodes", expr.pos);
					[];
			};
		}

		var declaredPipelines = new Map<String, Bool>();

		function collectDeclaredPipelines(expr:Expr):Void {
			var normalizedExpr = unwrapExpr(expr);
			switch (normalizedExpr.expr) {
				case ECall(callee, args):
					var callName = extractCallName(callee);
					if ((callName == "pipeline" || callName == "pipelineUnsafe") && args.length > 0) {
						var pipelineName = extractPipelineNameValue(args[0], callName == "pipelineUnsafe");
						if (pipelineName != null) {
							if (declaredPipelines.exists(pipelineName)) {
								Context.error('Duplicate pipeline declaration "${pipelineName}".', expr.pos);
							}
							declaredPipelines.set(pipelineName, true);
						}
					}
					for (arg in args) {
						collectDeclaredPipelines(arg);
					}
				case EArrayDecl(items):
					for (item in items) {
						collectDeclaredPipelines(item);
					}
				case EObjectDecl(fields):
					for (field in fields) {
						collectDeclaredPipelines(field.expr);
					}
				default:
			}
		}

		for (routeValue in routeValues) {
			collectDeclaredPipelines(routeValue);
		}

		function parsePipeThroughPipelines(expr:Expr, allowStringLiteral:Bool):Array<String> {
			var pipelines:Array<String> = [];
			switch (unwrapExpr(expr).expr) {
				case EArrayDecl(values):
					for (value in values) {
						var pipelineName = extractPipelineNameValue(value, allowStringLiteral);
						if (pipelineName != null) {
							pipelines.push(pipelineName);
						}
					}
				default:
					var singlePipeline = extractPipelineNameValue(expr, allowStringLiteral);
					if (singlePipeline != null) {
						pipelines.push(singlePipeline);
					}
			}
			return pipelines;
		}

		function validatePipeThroughReferences(pipelines:Array<String>, pos:haxe.macro.Expr.Position):Void {
			for (pipelineName in pipelines) {
				if (!declaredPipelines.exists(pipelineName)) {
					Context.error('pipeThrough references unknown pipeline "${pipelineName}". Declare it with pipeline(...) first.', pos);
				}
			}
		}

		function parseCompatRouteObject(routeExpr:Expr):Null<RouterNodeMeta> {
			return switch (routeExpr.expr) {
				case EObjectDecl(fields):
					var name:Null<String> = null;
					var method:Null<String> = null;
					var path:Null<String> = null;
					var controller:Null<String> = null;
					var action:Null<String> = null;
					var pipeline:Null<String> = null;
					var controllerWasStringLiteral = false;
					var controllerPos = routeExpr.pos;

					for (field in fields) {
						switch (field.field) {
							case "name":
								name = extractStringValue(field.expr, "name", field.expr.pos);
							case "method":
								method = extractMethodValue(field.expr, "method", field.expr.pos);
							case "path":
								path = extractStringValue(field.expr, "path", field.expr.pos);
							case "controller":
								controllerWasStringLiteral = switch (field.expr.expr) {
									case EConst(CString(_, _)): true;
									default: false;
								};
								controllerPos = field.expr.pos;
								controller = switch (field.expr.expr) {
									case EConst(CString(s, _)):
										s;
									default:
										var path = extractDotPath(field.expr);
										if (path == null) {
											Context.error('controller must be a string literal or type reference (e.g. controllers.UserController)',
												field.expr.pos);
											null;
										} else {
											path;
										}
								};
							case "action":
								action = extractActionRef(field.expr, "action", field.expr.pos, true);
							case "pipeline":
								pipeline = extractStringValue(field.expr, "pipeline", field.expr.pos);
							default:
								Context.warning('Unknown route field: ${field.field}', field.expr.pos);
						}
					}

					if (name == null || method == null || path == null) {
						Context.error("Route definition requires name/method/path", routeExpr.pos);
						return null;
					}

					var methodUpper = method.toUpperCase();
					if (methodUpper != "LIVE_DASHBOARD" && methodUpper != "MAILBOX") {
						if (controller == null) {
							Context.error('Route "${name}" is missing controller', routeExpr.pos);
						}
						if (action == null) {
							Context.error('Route "${name}" is missing action', routeExpr.pos);
						}
					}

					if (controllerWasStringLiteral && controller != null && controller != "") {
						var recommendation = 'Route "${name}" uses a legacy string literal for controller. Prefer a typed controller reference (for example controllers.UserController).';
						if (strictTypedRouteControllerRefs) {
							Context.error(recommendation + " Use @:route for intentionally legacy/manual string routing.", controllerPos);
						} else {
							Context.warning(recommendation + " Pass -D router_strict_typed_refs to enforce this as an error.", controllerPos);
						}
					}

					var options:Array<RouterOptionMeta> = [];
					if (pipeline != null) {
						options.push({key: "pipeline", value: ROString(pipeline)});
					}
					options.push({key: "name", value: ROString(name)});

					switch (methodUpper) {
						case "LIVE_DASHBOARD":
							{
								kind: "live_dashboard",
								path: path,
								options: options
							};
						case "MAILBOX":
							{
								kind: "mailbox",
								path: path,
								options: options
							};
						default:
							{
								kind: "compat_route",
								name: name,
								method: methodUpper,
								path: path,
								controller: controller,
								action: action,
								options: options
							};
					}
				default:
					null;
			};
		}

		function parseNode(nodeExpr:Expr):Null<RouterNodeMeta> {
			var compat = parseCompatRouteObject(nodeExpr);
			if (compat != null) {
				return compat;
			}

			return switch (nodeExpr.expr) {
				case ECall(callee, args):
					var name = extractCallName(callee);
					if (name == null) {
						Context.error("RouterDsl node call is malformed", nodeExpr.pos);
						return null;
					}

					switch (name) {
						case "pipeline", "pipelineUnsafe":
							if (args.length < 2) {
								var ctor = name == "pipelineUnsafe" ? "pipelineUnsafe" : "pipeline";
								Context.error('RouterDsl.${ctor}(name, children) requires two arguments', nodeExpr.pos);
							}
							var pipelineName = extractPipelineNameValue(args[0], name == "pipelineUnsafe");
							var children = parseChildren(args[1]);
							{
								kind: "pipeline",
								name: pipelineName,
								children: children
							};

						case "plug", "plugUnsafe":
							if (args.length < 1) {
								var ctor = name == "plugUnsafe" ? "plugUnsafe" : "plug";
								Context.error('RouterDsl.${ctor}(target, ?opts) requires at least one argument', nodeExpr.pos);
							}
							var target = extractPlugTargetValue(args[0], name == "plugUnsafe");
							var opts = args.length > 1 ? parseOptionsExpr(args[1]) : [];
							{
								kind: "plug",
								moduleRef: target,
								options: opts
							};

						case "scope":
							if (args.length < 2) {
								Context.error('RouterDsl.scope(path, children, ?opts) requires at least two arguments', nodeExpr.pos);
							}
							var scopePath = extractStringValue(args[0], "scope path", nodeExpr.pos);
							var scopeChildren = parseChildren(args[1]);
							var scopeOpts = args.length > 2 ? parseOptionsExpr(args[2]) : [];
							{
								kind: "scope",
								path: scopePath,
								children: scopeChildren,
								options: scopeOpts
							};

						case "pipeThrough", "pipeThroughUnsafe":
							if (args.length < 1) {
								var ctor = name == "pipeThroughUnsafe" ? "pipeThroughUnsafe" : "pipeThrough";
								Context.error('RouterDsl.${ctor}(pipelines, ?opts) requires at least one argument', nodeExpr.pos);
							}
							var pipelines = parsePipeThroughPipelines(args[0], name == "pipeThroughUnsafe");
							validatePipeThroughReferences(pipelines, nodeExpr.pos);
							{
								kind: "pipe_through",
								pipelines: pipelines
							};

						case "liveSession":
							if (args.length < 2) {
								Context.error('RouterDsl.liveSession(name, children, ?opts) requires at least two arguments', nodeExpr.pos);
							}
							var sessionName = extractStringValue(args[0], "live_session name", nodeExpr.pos);
							var sessionChildren = parseChildren(args[1]);
							var sessionOpts = args.length > 2 ? parseOptionsExpr(args[2]) : [];
							{
								kind: "live_session",
								name: sessionName,
								children: sessionChildren,
								options: sessionOpts
							};

						case "get", "post", "put", "patch", "delete", "options", "head", "connect", "trace":
							if (args.length < 3) {
								Context.error('RouterDsl.${name}(path, controller, action, ?opts) requires at least three arguments', nodeExpr.pos);
							}
							var routePath = extractStringValue(args[0], "route path", nodeExpr.pos);
							var controllerTypePath = extractTypeRef(args[1], "controller/live module", nodeExpr.pos, false, false);
							var controllerPath = controllerTypePath != null ? stripLocalModulePrefix(controllerTypePath) : null;
							var actionName = extractActionRef(args[2], "action", nodeExpr.pos, false);
							var routeOpts = args.length > 3 ? parseOptionsExpr(args[3]) : [];

							validatePathParamsContract(routePath, routeOpts, nodeExpr.pos);
							if (controllerTypePath != null && actionName != null) {
								validateActionExists(controllerTypePath, actionName, nodeExpr.pos);
							}

							{
								kind: "route",
								method: name.toUpperCase(),
								path: routePath,
								controller: controllerPath,
								action: actionName,
								options: routeOpts
							};

						case "live":
							if (args.length < 2) {
								Context.error('RouterDsl.live(path, liveModule, ?action, ?opts) requires at least two arguments', nodeExpr.pos);
							}
							var livePath = extractStringValue(args[0], "route path", nodeExpr.pos);
							var liveControllerTypePath = extractTypeRef(args[1], "controller/live module", nodeExpr.pos, false, false);
							var liveControllerPath = liveControllerTypePath != null ? stripLocalModulePrefix(liveControllerTypePath) : null;
							var liveActionName:Null<String> = null;
							var liveRouteOpts:Array<RouterOptionMeta> = [];

							if (args.length > 2) {
								switch (args[2].expr) {
									case EObjectDecl(_):
										liveRouteOpts = parseOptionsExpr(args[2]);
									case EConst(CIdent("null")):
										liveRouteOpts = args.length > 3 ? parseOptionsExpr(args[3]) : [];
									default:
										liveActionName = extractActionRef(args[2], "action", nodeExpr.pos, false);
										liveRouteOpts = args.length > 3 ? parseOptionsExpr(args[3]) : [];
								}
							}

							validatePathParamsContract(livePath, liveRouteOpts, nodeExpr.pos);
							if (liveControllerTypePath != null && liveActionName != null) {
								validateActionExists(liveControllerTypePath, liveActionName, nodeExpr.pos);
							}

							{
								kind: "route",
								method: "LIVE",
								path: livePath,
								controller: liveControllerPath,
								action: liveActionName,
								options: liveRouteOpts
							};

						case "match":
							if (args.length < 4) {
								Context.error('RouterDsl.match(verb, path, controller, action, ?opts) requires at least four arguments', nodeExpr.pos);
							}
							var verb = extractMethodValue(args[0], "verb", nodeExpr.pos);
							var matchPath = extractStringValue(args[1], "route path", nodeExpr.pos);
							var matchControllerTypePath = extractTypeRef(args[2], "controller", nodeExpr.pos, false, false);
							var matchController = matchControllerTypePath != null ? stripLocalModulePrefix(matchControllerTypePath) : null;
							var matchAction = extractActionRef(args[3], "action", nodeExpr.pos, false);
							var matchOpts = args.length > 4 ? parseOptionsExpr(args[4]) : [];
							validatePathParamsContract(matchPath, matchOpts, nodeExpr.pos);
							if (matchControllerTypePath != null && matchAction != null) {
								validateActionExists(matchControllerTypePath, matchAction, nodeExpr.pos);
							}
							{
								kind: "match",
								verb: verb,
								path: matchPath,
								controller: matchController,
								action: matchAction,
								options: matchOpts
							};

						case "forward":
							if (args.length < 2) {
								Context.error('RouterDsl.forward(path, moduleRef, ?opts) requires at least two arguments', nodeExpr.pos);
							}
							var forwardPath = extractStringValue(args[0], "forward path", nodeExpr.pos);
							var forwardModuleTypePath = extractTypeRef(args[1], "forward module", nodeExpr.pos, false, false);
							var moduleRef = forwardModuleTypePath != null ? stripLocalModulePrefix(forwardModuleTypePath) : null;
							var forwardOpts = args.length > 2 ? parseOptionsExpr(args[2]) : [];
							{
								kind: "forward",
								path: forwardPath,
								moduleRef: moduleRef,
								options: forwardOpts
							};

						case "resources", "resource":
							if (args.length < 2) {
								Context.error('RouterDsl.${name}(path, controller, ?opts) requires at least two arguments', nodeExpr.pos);
							}
							var resourcePath = extractStringValue(args[0], "resource path", nodeExpr.pos);
							var resourceControllerTypePath = extractTypeRef(args[1], "resource controller", nodeExpr.pos, false, false);
							var resourceController = resourceControllerTypePath != null ? stripLocalModulePrefix(resourceControllerTypePath) : null;
							var resourceOpts = args.length > 2 ? parseOptionsExpr(args[2]) : [];
							{
								kind: name == "resource" ? "resource" : "resources",
								path: resourcePath,
								controller: resourceController,
								options: resourceOpts
							};

						case "liveDashboard":
							if (args.length < 1) {
								Context.error('RouterDsl.liveDashboard(path, ?opts) requires at least one argument', nodeExpr.pos);
							}
							var dashboardPath = extractStringValue(args[0], "dashboard path", nodeExpr.pos);
							var dashboardOpts = args.length > 1 ? parseOptionsExpr(args[1]) : [];
							{
								kind: "live_dashboard",
								path: dashboardPath,
								options: dashboardOpts
							};

						case "mailbox":
							if (args.length < 1) {
								Context.error('RouterDsl.mailbox(path, ?opts) requires at least one argument', nodeExpr.pos);
							}
							var mailboxPath = extractStringValue(args[0], "mailbox path", nodeExpr.pos);
							var mailboxOpts = args.length > 1 ? parseOptionsExpr(args[1]) : [];
							{
								kind: "mailbox",
								path: mailboxPath,
								options: mailboxOpts
							};

						default:
							Context.error('Unsupported RouterDsl node constructor: ${name}', nodeExpr.pos);
							null;
					}
				default:
					Context.error("Each route entry must be a legacy route object or RouterDsl.* node call", nodeExpr.pos);
					null;
			};
		}

		parseNodeRef = parseNode;
		return switch (routesExpr.expr) {
			case EArrayDecl(values):
				var nodes:Array<RouterNodeMeta> = [];
				for (value in values) {
					var parsed = parseNode(value);
					if (parsed != null) {
						nodes.push(parsed);
					}
				}
				nodes.length > 0 ? nodes : null;
			default:
				Context.error('Router routes from ${routesSource.source} must be an array: final routes = [...]', routesExpr.pos);
				null;
		};
	}

	private function extractSocketChannelsFromMeta(classType:ClassType):Null<Array<SocketChannelMeta>> {
		var meta = classType.meta.extract(":socketChannels");
		var metaAlt = classType.meta.extract("socketChannels");
		if (metaAlt != null && metaAlt.length > 0) {
			meta = meta != null && meta.length > 0 ? meta.concat(metaAlt) : metaAlt;
		}
		if (meta == null || meta.length == 0)
			return null;

		var entry = meta[0];
		if (entry.params == null || entry.params.length == 0) {
			Context.error("@:socketChannels requires an array parameter: @:socketChannels([{topic: \"...\", channel: SomeChannel}])", entry.pos);
			return null;
		}

		function extractDotPath(expr:Expr):Null<String> {
			return switch (expr.expr) {
				case EConst(CIdent(ident)):
					ident;
				case EField(e, field):
					var base = extractDotPath(e);
					base != null ? (base + "." + field) : field;
				default:
					null;
			};
		}

		function extractStringValue(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position):Null<String> {
			return switch (expr.expr) {
				case EConst(CString(s, _)): s;
				case EConst(CIdent(ident)): ident;
				default:
					Context.error('${fieldName} must be a string literal or identifier', pos);
					null;
			};
		}

		function resolveElixirModuleName(typePath:String, pos:haxe.macro.Expr.Position):Null<String> {
			if (typePath == null || typePath.length == 0)
				return null;
			try {
				var t = Context.getType(typePath);
				return switch (t) {
					case TInst(c, _):
						ModuleBuilder.extractModuleName(c.get());
					default:
						Context.error('Expected class type for ${typePath}', pos);
						null;
				};
			} catch (e) {
				Context.error('Could not resolve type: ${typePath}', pos);
				return null;
			}
		}

		function extractElixirModule(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position):Null<String> {
			return switch (expr.expr) {
				case EConst(CString(s, _)):
					StringTools.startsWith(s, "Elixir.") ? s.substr("Elixir.".length) : s;
				default:
					var path = extractDotPath(expr);
					if (path == null) {
						Context.error('${fieldName} must be a string literal or type reference (e.g. server.channels.PingChannel)', pos);
						null;
					} else {
						resolveElixirModuleName(path, pos);
					}
			};
		}

		function parseOne(expr:Expr):Null<SocketChannelMeta> {
			return switch (expr.expr) {
				case EObjectDecl(fields):
					var topic:Null<String> = null;
					var channel:Null<String> = null;
					for (f in fields) {
						switch (f.field) {
							case "topic":
								topic = extractStringValue(f.expr, "topic", f.expr.pos);
							case "channel":
								channel = extractElixirModule(f.expr, "channel", f.expr.pos);
							default:
								Context.warning('Unknown socket channel field: ${f.field}', f.expr.pos);
						}
					}
					if (topic == null || channel == null) {
						Context.error("socketChannels entry requires topic/channel", expr.pos);
						null;
					} else {
						{topic: topic, channel: channel};
					}
				default:
					Context.error("socketChannels entries must be object literals", expr.pos);
					null;
			};
		}

		return switch (entry.params[0].expr) {
			case EArrayDecl(items):
				var out:Array<SocketChannelMeta> = [];
				for (it in items) {
					var parsed = parseOne(it);
					if (parsed != null)
						out.push(parsed);
				}
				out.length > 0 ? out : null;
			default:
				Context.error("@:socketChannels must be an array literal", entry.params[0].pos);
				null;
		}
	}

	private function extractEndpointSocketsFromMeta(classType:ClassType):Null<Array<EndpointSocketMeta>> {
		var meta = classType.meta.extract(":endpointSockets");
		var metaAlt = classType.meta.extract("endpointSockets");
		if (metaAlt != null && metaAlt.length > 0) {
			meta = meta != null && meta.length > 0 ? meta.concat(metaAlt) : metaAlt;
		}
		if (meta == null || meta.length == 0)
			return null;

		var entry = meta[0];
		if (entry.params == null || entry.params.length == 0) {
			Context.error("@:endpointSockets requires an array parameter: @:endpointSockets([{path: \"/socket\", socket: SomeSocket}])", entry.pos);
			return null;
		}

		function extractDotPath(expr:Expr):Null<String> {
			return switch (expr.expr) {
				case EConst(CIdent(ident)):
					ident;
				case EField(e, field):
					var base = extractDotPath(e);
					base != null ? (base + "." + field) : field;
				default:
					null;
			};
		}

		function extractStringValue(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position):Null<String> {
			return switch (expr.expr) {
				case EConst(CString(s, _)): s;
				case EConst(CIdent(ident)): ident;
				default:
					Context.error('${fieldName} must be a string literal or identifier', pos);
					null;
			};
		}

		function extractBoolValue(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position):Null<Bool> {
			return switch (expr.expr) {
				case EConst(CIdent("true")): true;
				case EConst(CIdent("false")): false;
				default:
					Context.error('${fieldName} must be a boolean literal', pos);
					null;
			};
		}

		function resolveElixirModuleName(typePath:String, pos:haxe.macro.Expr.Position):Null<String> {
			if (typePath == null || typePath.length == 0)
				return null;
			try {
				var t = Context.getType(typePath);
				return switch (t) {
					case TInst(c, _):
						ModuleBuilder.extractModuleName(c.get());
					default:
						Context.error('Expected class type for ${typePath}', pos);
						null;
				};
			} catch (e) {
				Context.error('Could not resolve type: ${typePath}', pos);
				return null;
			}
		}

		function extractElixirModule(expr:Expr, fieldName:String, pos:haxe.macro.Expr.Position):Null<String> {
			return switch (expr.expr) {
				case EConst(CString(s, _)):
					StringTools.startsWith(s, "Elixir.") ? s.substr("Elixir.".length) : s;
				default:
					var path = extractDotPath(expr);
					if (path == null) {
						Context.error('${fieldName} must be a string literal or type reference (e.g. server.infrastructure.UserSocket)', pos);
						null;
					} else {
						resolveElixirModuleName(path, pos);
					}
			};
		}

		function parseOne(expr:Expr):Null<EndpointSocketMeta> {
			return switch (expr.expr) {
				case EObjectDecl(fields):
					var path:Null<String> = null;
					var socket:Null<String> = null;
					var session:Null<Bool> = null;
					for (f in fields) {
						switch (f.field) {
							case "path":
								path = extractStringValue(f.expr, "path", f.expr.pos);
							case "socket":
								socket = extractElixirModule(f.expr, "socket", f.expr.pos);
							case "session":
								session = extractBoolValue(f.expr, "session", f.expr.pos);
							default:
								Context.warning('Unknown endpoint socket field: ${f.field}', f.expr.pos);
						}
					}
					if (path == null || socket == null) {
						Context.error("endpointSockets entry requires path/socket", expr.pos);
						null;
					} else {
						var out:EndpointSocketMeta = {path: path, socket: socket};
						if (session != null)
							Reflect.setField(out, "session", session);
						out;
					}
				default:
					Context.error("endpointSockets entries must be object literals", expr.pos);
					null;
			};
		}

		return switch (entry.params[0].expr) {
			case EArrayDecl(items):
				var out:Array<EndpointSocketMeta> = [];
				for (it in items) {
					var parsed = parseOne(it);
					if (parsed != null)
						out.push(parsed);
				}
				out.length > 0 ? out : null;
			default:
				Context.error("@:endpointSockets must be an array literal", entry.params[0].pos);
				null;
		}
	}

	private function extractEndpointLiveLongpollFromMeta(classType:ClassType):Null<Bool> {
		function extractOne(metaName:String):Array<MetadataEntry> {
			var entries = classType.meta.extract(metaName);
			return entries == null ? [] : entries;
		}

		// Removed API: legacy standalone endpoint longpoll metadata is no longer supported.
		// Users must configure this via @:endpoint({liveLongpoll: ...}).
		var legacyEntries = [].concat(extractOne(":endpointLiveLongpoll"))
			.concat(extractOne("endpointLiveLongpoll"))
			.concat(extractOne(":endpointLongpoll"))
			.concat(extractOne("endpointLongpoll"));
		if (legacyEntries.length > 0) {
			Context.error("@:endpointLiveLongpoll/@:endpointLongpoll was removed. Use @:endpoint({liveLongpoll: true|false}) instead.", legacyEntries[0].pos);
		}

		var endpointEntries = [].concat(extractOne(":endpoint")).concat(extractOne("endpoint"));
		if (endpointEntries.length == 0) {
			return null;
		}

		var liveLongpoll:Null<Bool> = null;
		for (entry in endpointEntries) {
			if (entry.params == null || entry.params.length == 0) {
				continue;
			}
			if (entry.params.length > 1) {
				Context.error("@:endpoint accepts a single options object, e.g. @:endpoint({liveLongpoll: true})", entry.params[1].pos);
				continue;
			}

			switch (entry.params[0].expr) {
				case EObjectDecl(fields):
					for (f in fields) {
						var fieldName = f.field;
						if (fieldName == "liveLongpoll" || fieldName == "live_longpoll") {
							if (liveLongpoll != null) {
								Context.error("Duplicate liveLongpoll configuration in @:endpoint metadata", f.expr.pos);
							}
							liveLongpoll = switch (f.expr.expr) {
								case EConst(CIdent("true")): true;
								case EConst(CIdent("false")): false;
								default:
									Context.error("@:endpoint({liveLongpoll: ...}) expects a boolean literal", f.expr.pos);
									null;
							};
						}
					}
				default:
					Context.error("@:endpoint options must be an object literal, e.g. @:endpoint({liveLongpoll: true})", entry.params[0].pos);
			}
		}

		return liveLongpoll;
	}

	/**
	 * Determine if an object should use atom keys based on field patterns
	 * Takes a conservative approach - defaults to string keys unless we're certain
	 * Only uses atoms for very specific OTP patterns to avoid breaking user code
	 */
	private function shouldUseAtomKeys(fields:Array<{name:String, expr:TypedExpr}>):Bool {
		// First check if this matches known OTP patterns
		if (false) { // OTP compilation now handled by AST pipeline
			return true;
		}

		// Check for Phoenix.PubSub configuration pattern
		// Objects with just a "name" field are typically PubSub configs
		if (fields != null && fields.length == 1 && fields[0].name == "name") {
			return isValidAtomName("name");
		}

		// Default to string keys for all other cases
		// This is safer and more predictable than trying to guess patterns
		return false;
	}

	/**
	 * Check if an object declaration represents a Supervisor child spec
	 * Child specs have "id" and "start" fields
	 */
	private function isChildSpecObject(fields:Array<{name:String, expr:TypedExpr}>):Bool {
		if (fields == null || fields.length == 0)
			return false;

		var fieldNames = fields.map(f -> f.name);
		return fieldNames.indexOf("id") != -1 && fieldNames.indexOf("start") != -1;
	}

	/**
	 * Child spec format types for structure-based detection
	 */
	private static inline var MODERN_TUPLE = "ModernTuple"; // {Module, args} - for modules with child_spec/1

	private static inline var SIMPLE_MODULE = "SimpleModule"; // ModuleName - simple module reference
	private static inline var TRADITIONAL_MAP = "TraditionalMap"; // %{id: ..., start: ...} - explicit map format

	/**
	 * Generate modern tuple format for child specs
	 * Examples: {Phoenix.PubSub, name: MyApp.PubSub}, MyApp.Repo
	 */
	private function generateModernTupleFormat(idField:String, startField:String, appName:String):String {
		var cleanId = idField.split('"').join('');

		// Special handling for Phoenix.PubSub with name parameter
		if (cleanId == "Phoenix.PubSub") {
			var pubsubName = '${appName}.PubSub';
			// Extract name from start args if available
			if (startField.indexOf('[%{name: ') > -1) {
				var namePattern = ~/\[%\{name: ([^}]+)\}\]/;
				if (namePattern.match(startField)) {
					pubsubName = namePattern.matched(1);
				}
			}
			// Convert to atom format for Phoenix compatibility
			// Phoenix expects name to be an atom, not a string
			var atomName = pubsubName.split('"').join(''); // Remove any quotes
			return '{Phoenix.PubSub, name: ${atomName}}';
		}

		// For other modules, check if they have simple args
		if (startField.indexOf(", []") > -1) {
			// No args - use simple module reference
			return cleanId;
		} else if (startField.indexOf("[%{") > -1) {
			// Has configuration args - extract and use tuple format
			var argsPattern = ~/\[(%\{[^}]+\})\]/;
			if (argsPattern.match(startField)) {
				var args = argsPattern.matched(1);
				return '{${cleanId}, ${args}}';
			}
		}

		// Fallback to simple module reference
		return cleanId;
	}

	/**
	 * Generate simple module reference format
	 * Examples: MyApp.Repo, MyAppWeb.Endpoint
	 */
	private function generateSimpleModuleFormat(idField:String, appName:String):String {
		var cleanId = idField.split('"').join('');

		// Apply common Phoenix naming conventions if not already prefixed
		if (cleanId.indexOf("Telemetry") > -1 && cleanId.indexOf(appName) == -1) {
			return '${appName}Web.Telemetry';
		}
		if (cleanId.indexOf("Endpoint") > -1 && cleanId.indexOf(appName) == -1) {
			return '${appName}Web.Endpoint';
		}
		if (cleanId.indexOf("Repo") > -1 && cleanId.indexOf(appName) == -1) {
			return '${appName}.Repo';
		}

		return cleanId;
	}

	/**


		/**
		* Check if an object declaration represents Supervisor options
		* Supervisor options have "strategy" and usually "name" fields
	 */
	private function isSupervisorOptionsObject(fields:Array<{name:String, expr:TypedExpr}>):Bool {
		if (fields == null || fields.length == 0)
			return false;

		var fieldNames = fields.map(f -> f.name);
		return fieldNames.indexOf("strategy") != -1;
	}

	/**
	 * Check if this is a call to elixir.Syntax static methods
	 * 
	 * @param obj The object expression (should be TTypeExpr for elixir.Syntax)
	 * @param fieldName The method name being called
	 * @return true if this is an elixir.Syntax call
	 */
	/**
	 * Compile elixir.Syntax method calls to __elixir__ injection calls
	 * 
	 * This transforms type-safe elixir.Syntax calls into the underlying __elixir__
	 * injection mechanism that Reflaxe processes via targetCodeInjectionName.
	 * 
	 * @param methodName The elixir.Syntax method being called (code, atom, tuple, etc.)
	 * @param args The arguments to the method call
	 * @return Compiled Elixir code
	 */
	/**
	 * Check if a TypedExpr represents a field assignment (this.field = value)
	 */
	private function isFieldAssignment(expr:TypedExpr):Bool {
		return switch (expr.expr) {
			case TBinop(OpAssign, e1, e2):
				switch (e1.expr) {
					case TField(e, fa):
						// Check if the field access is on 'this'
						switch (e.expr) {
							case TConst(TThis): true;
							case TLocal(v): v.name == "this" || v.name == "_this";
							case _: false;
						}
					case _: false;
				}
			case _: false;
		};
	}

	// All temp variable optimization and assignment extraction functions
	// have been removed - now handled by the AST pipeline

	/**
	 * Check if expression is nil
	 */
	private function isNilExpression(expr:TypedExpr):Bool {
		return switch (expr.expr) {
			case TConst(TNull): true;
			case TIdent("nil"): true;
			case _: false;
		};
	}

	/**
	 * Check if this is a TypeSafeChildSpec enum constructor call
	 */
	/**
	 * Compile TypeSafeChildSpec enum constructor calls directly to ChildSpec format
	 */
	/**
	 * Detect if an AST expression will generate a Y combinator pattern.
	 * 
	 * This function analyzes the AST structure BEFORE string compilation
	 * to identify patterns that will result in Y combinator generation,
	 * preventing the inline syntax bug where ", else: nil" gets misplaced.
	 * 
	 * @param expr The TypedExpr to analyze
	 * @return True if this expression will generate a Y combinator
	 */
	private function detectYCombinatorInAST(expr:TypedExpr):Bool {
		// Y combinators are no longer used - we use idiomatic Elixir patterns
		return false;
	}

	/**
	 * Check if a block of expressions contains Reflect.fields iteration.
	 * 
	 * @param expressions Array of expressions to check
	 * @return True if contains Reflect.fields iteration pattern
	 */
	/**
	 * Enhanced Reflect.fields detection with comprehensive debugging.
	 * 
	 * WHY: The original detection was missing Reflect.fields patterns, causing
	 * Y combinator syntax errors. This enhanced version traces the AST structure
	 * to understand why patterns aren't being detected.
	 * 
	 * HOW: Iterates through expressions in a TBlock, specifically looking for:
	 * 1. TVar assignments that call Reflect.fields
	 * 2. TFor loops that iterate over Reflect.fields results
	 * 3. Any nested expressions that contain these patterns
	 * 
	 * DEBUGGING: Uses XRay debugging to trace AST structure when debug_compiler flag is enabled,
	 * allowing us to understand exactly what AST patterns we're encountering.
	 * 
	 * @param expressions Array of expressions from a TBlock to analyze
	 * @return True if any expression uses Reflect.fields (indicating Y combinator generation)
	 */
	/**
	 * Check if a TypedExpr contains an ~H sigil (Phoenix component template)
	 * 
	 * WHY: Phoenix components using ~H sigil require 'assigns' parameter without underscore
	 * WHAT: Recursively searches expression tree for HXX.hxx calls (which compile to ~H sigil)
	 * HOW: Pattern matches on TCall to find HXX.hxx, recursively checks child expressions
	 * 
	 * @param expr The expression to check for ~H sigil usage
	 * @return True if expression contains ~H sigil
	 */
	private function containsHSigil(expr:TypedExpr):Bool {
		if (expr == null)
			return false;

		switch (expr.expr) {
			case TCall(e, _):
				// Check if this is an HXX.hxx call (compiles to ~H sigil)
				switch (e.expr) {
					case TField(_, FStatic(_, cf)):
						if (cf.get().name == "hxx") {
							return true;
						}
					default:
				}
				// Continue checking in the call target and arguments
				return containsHSigil(e);

			case TBlock(exprs):
				for (e in exprs) {
					if (containsHSigil(e))
						return true;
				}

			case TReturn(e):
				return containsHSigil(e);

			case TIf(econd, eif, eelse):
				return containsHSigil(econd) || containsHSigil(eif) || (eelse != null && containsHSigil(eelse));

			case TSwitch(e, cases, edef):
				if (containsHSigil(e))
					return true;
				for (c in cases) {
					if (containsHSigil(c.expr))
						return true;
				}
				if (edef != null && containsHSigil(edef))
					return true;

			case TFunction(tfunc):
				return containsHSigil(tfunc.expr);

			case TVar(_, expr):
				return expr != null && containsHSigil(expr);

			default:
				// For other expression types, we don't need to check deeper
		}
		return false;
	}

	/**
	 * Override called after all files have been generated by Reflaxe's OutputManager.
	 *
	 * WHY
	 * - `onCompileEnd()` runs **before** file output (see ReflectCompiler), so any post-processing
	 *   that relies on the final output set must happen here instead.
	 */
	public override function onOutputComplete() {
		if (!sourceMapOutputEnabled)
			return;

		// Generate all pending source maps after output files are written.
		for (writer in pendingSourceMapWriters) {
			if (writer != null)
				writer.generateSourceMap();
		}
		pendingSourceMapWriters = [];
	}

	static function applyReceiverReturnConvention(body:Null<reflaxe.elixir.ast.ElixirAST>, receiverName:String,
			convention:ReceiverReturnConvention):Null<reflaxe.elixir.ast.ElixirAST> {
		if (body == null)
			return body;

		return switch (convention) {
			case PureValue:
				body;
			case UpdatedReceiver:
				body;
			case UpdatedReceiverAndValue:
				replaceFinalExpressionWithTuple(body, receiverName);
		}
	}

	static function replaceFinalExpressionWithTuple(body:reflaxe.elixir.ast.ElixirAST, receiverName:String):reflaxe.elixir.ast.ElixirAST {
		return switch (body.def) {
			case EParen(inner):
				replaceFinalExpressionWithTuple(inner, receiverName);
			case EBlock(expressions):
				reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EBlock(replaceFinalInListWithTuple(expressions, receiverName)));
			case EDo(expressions):
				reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EDo(replaceFinalInListWithTuple(expressions, receiverName)));
			default:
				reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.ETuple([reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EVar(receiverName)), body]));
		}
	}

	static function replaceFinalInListWithTuple(expressions:Array<reflaxe.elixir.ast.ElixirAST>, receiverName:String):Array<reflaxe.elixir.ast.ElixirAST> {
		var rewritten:Array<reflaxe.elixir.ast.ElixirAST> = [];
		if (expressions == null || expressions.length == 0) {
			rewritten.push(reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.ETuple([
				reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EVar(receiverName)),
				reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.ENil)
			])));
			return rewritten;
		}
		for (index in 0...expressions.length) {
			var expression = expressions[index];
			if (index == expressions.length - 1) {
				rewritten.push(reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.ETuple([
					reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EVar(receiverName)),
					expression
				])));
			} else {
				rewritten.push(expression);
			}
		}
		return rewritten;
	}

	/**
	 * Convert a Haxe Type to string representation
	 * 
	 * WHY: SubstitutionCompiler needs type information for variable tracking
	 * WHAT: Provides basic type-to-string conversion for debugging and analysis
	 * HOW: Simple pattern matching on Type enum with fallback to "Dynamic"
	 * 
	 * @param type The Haxe Type to convert
	 * @return String representation of the type
	 */
	public function typeToString(type:Type):String {
		return switch (type) {
			case TInst(t, _): t.get().name;
			case TAbstract(t, _): t.get().name;
			case TEnum(t, _): t.get().name;
			case TFun(_, ret): "Function";
			case TMono(_): "Mono";
			case TDynamic(_): "Dynamic";
			case TAnonymous(_): "Anonymous";
			case TType(t, _): t.get().name;
			case TLazy(_): "Lazy";
		}
	}
}
#end
