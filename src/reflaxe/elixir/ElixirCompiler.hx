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
import reflaxe.elixir.ast.ElixirAST.RouterRouteMeta;
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.CompilationContext;

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
    var moduleName: String;
    var modulePack: Array<String>;
    var outputPath: Null<String>;
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
class ElixirCompiler extends GenericCompiler<
    reflaxe.elixir.ast.ElixirAST,  // CompiledClassType
    reflaxe.elixir.ast.ElixirAST,  // CompiledEnumType
    reflaxe.elixir.ast.ElixirAST,  // CompiledExpressionType
    reflaxe.elixir.ast.ElixirAST,  // CompiledTypedefType
    reflaxe.elixir.ast.ElixirAST   // CompiledAbstractType
> {

    // Global module registry for cross-file qualification decisions
    static var globalModuleRegistry: Map<String, Bool> = new Map();
    public static function registerModule(name: String): Void {
        if (name != null && name.length > 0) globalModuleRegistry.set(name, true);
    }
    public static function isModuleKnown(name: String): Bool {
        return name != null && globalModuleRegistry.exists(name);
    }

    // Static instance reference for helpers to access the compiler
    public static var instance: ElixirCompiler;
    
    // File extension for generated Elixir files
    public var fileExtension: String = ".ex";
    
    // Output directory for generated files (dynamically set by Reflaxe)
    public var outputDirectory: String = "lib/";
    
    // Type mapping system for enhanced enum compilation
    private var typer: reflaxe.elixir.ElixirTyper;
    
    // Context tracking for variable substitution
    public var isInLoopContext: Bool = false;
    
    // Source mapping support for debugging and LLM workflows
    public var currentSourceMapWriter: Null<SourceMapWriter> = null;
    public var sourceMapOutputEnabled: Bool = false;
    public var pendingSourceMapWriters: Array<SourceMapWriter> = [];
    
    // Parameter mapping system for abstract type implementation methods
    public var currentFunctionParameterMap: Map<String, String> = new Map();
    
    // Context-aware pattern usage tracking for enum parameter optimization
    // Tracks which pattern variables are actually used in switch case bodies
    // to prevent generating orphaned enum parameter extractions
    public var patternUsageContext: Null<Map<String, Bool>> = null;
    
    // Return context tracking for case expression assignment
    // When true, indicates we're compiling a return expression and case results
    // need to be assigned to temp_result for proper value capture in Elixir
    public var returnContext: Bool = false;

    
    // Map for tracking variable renames to ensure consistency between declaration and usage
    
    // Track whether we're compiling in a statement context (for mutable operations)
    // When true, array.push(item) generates reassignment: array = array ++ [item]
    public var isStatementContext: Bool = false;
    // Critical for resolving _g variable collisions in desugared loops
    public var variableRenameMap: Null<Map<String, String>> = null;
    
    // Track inline function context across multiple expressions in a block
    // Maps inline variable names (like "struct") to their assigned values (like "struct.buf")
    public var inlineContextMap: Map<String, String> = new Map<String, String>();
    private var isCompilingAbstractMethod: Bool = false;
    public var isCompilingCaseArm: Bool = false;
    
    // Track when we're inside enum parameter extraction to prevent incorrect variable mappings
    public var isInEnumExtraction: Bool = false;
    
    // Track enum extraction variables with their indices to handle multiple parameters correctly
    
    // Track loop variable context to distinguish between counter and limit variables
    public var loopCounterVar: String = null;  // Current loop counter variable name
    public var loopLimitVar: String = null;    // Current loop limit variable name
    public var isInLoopCondition: Bool = false; // Flag when compiling loop conditions
    public var enumExtractionVars: Null<Array<{index: Int, varName: String}>> = null;
    public var currentEnumExtractionIndex: Int = 0;
    
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
    public var currentSwitchCaseBody: Null<TypedExpr> = null;
    
    // Current class context for app name resolution and other class-specific operations
    public var currentClassType: Null<ClassType> = null;
    
    // Track instance variable names for LiveView classes to generate socket.assigns references
    
    /**
     * STATE THREADING MODE
     * 
     * WHY: Transform mutable field assignments in Haxe to immutable struct updates in Elixir
     * WHAT: Track when we're compiling a mutating method that needs state threading
     * HOW: When enabled, field assignments generate struct updates that are threaded through
     */
    public var stateThreadingEnabled: Bool = false;
    // State threading info removed - handled by AST transformer
    
    /**
     * GLOBAL STRUCT METHOD COMPILATION
     * 
     * WHY: Fix JsonPrinter _this issue - parameter mapping gets lost in nested contexts
     * WHAT: Track if we're compiling ANY struct method globally
     * HOW: Set flag when compiling struct methods, use global mapping that persists through all nested compilation
     */
    public var isCompilingStructMethod: Bool = false;
    public var globalStructParameterMap: Map<String, String> = new Map();
    
    // Track temporary variables consumed by array ternary optimization
    // Maps temp_array names to their replacement direct assignments
    public var consumedTempVariables: Null<Map<String, String>> = null;
    
    /**
     * PRESENCE MODULE CONTEXT
     * 
     * WHY: Phoenix.Presence modules have injected functions that require self() as first argument
     * WHAT: Track when we're compiling inside a @:presence module
     * HOW: Set flag when compiling classes with @:presence metadata, use in AST builder for method calls
     */
    public var isInPresenceModule: Bool = false;
    
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
    public var moduleDependencies: Map<String, Map<String, Bool>> = new Map();
    
    /**
     * Current module being compiled
     * Used to track dependencies for the current compilation unit
     */
    public var currentCompiledModule: String = null;
    
    /**
     * Track modules that have bootstrap code (static main())
     * These modules need special handling for script execution
     */
    public var modulesWithBootstrap: Array<String> = [];
    
    /**
     * Track module output file paths for require generation
     * Maps module name -> relative file path from output directory
     */
    public var moduleOutputPaths: Map<String, String> = new Map();
    
    /**
     * Track module packages for proper path resolution
     * Maps module name -> package array (e.g., "Log" -> ["haxe"])
     */
    public var modulePackages: Map<String, Array<String>> = new Map();

    /**
     * Map module name -> BaseType for synthetic outputs (e.g., bootstrap files)
     * WHY: OutputManager requires a BaseType for each DataAndFileInfo; we use the module's
     *      BaseType combined with overrideFileName to write custom files.
     */
    public var moduleBaseTypes: Map<String, BaseType> = new Map();
    
    /**
     * Constructor - Initialize the compiler with type mapping and pattern matching systems
     */
    public function new() {
        super();
        instance = this;  // Set static instance reference
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
    public override function filterTypes(moduleTypes: Array<haxe.macro.Type.ModuleType>): Array<haxe.macro.Type.ModuleType> {
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
                        if (cls.meta != null && cls.meta.has(":migration")) migrations.push(mt);
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
    public override function shouldGenerateClass(classType: ClassType): Bool {
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
            // DISABLED: trace('[shouldGenerateClass] Forcing compilation of @:presence class: ${classType.name} (isExtern: ${classType.isExtern})');
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
            // DISABLED: trace('[shouldGenerateClass] Forcing compilation of @:application class: ${classType.name}');
            #end
            return true;
        }

        // Force generation for @:endpoint classes (Phoenix Endpoint modules)
        if (classType.meta.has(":endpoint")) {
            #if debug_annotation_transforms
            // DISABLED: trace('[shouldGenerateClass] Forcing compilation of @:endpoint class: ${classType.name}');
            #end
            return true;
        }

        // Force generation for @:router classes (Phoenix Router modules)
        if (classType.meta.has(":router")) {
            #if debug_annotation_transforms
            // DISABLED: trace('[shouldGenerateClass] Forcing compilation of @:router class: ${classType.name}');
            #end
            return true;
        }

        // Force generation for @:phoenixWebModule classes (Phoenix Web modules)
        if (classType.meta.has(":phoenixWebModule") || classType.meta.has(":phoenixWeb")) {
            #if debug_annotation_transforms
            // DISABLED: trace('[shouldGenerateClass] Forcing compilation of @:phoenixWebModule class: ${classType.name}');
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
    private function shouldSuppressStdEmission(classType: ClassType): Bool {
        // Fast checks by name
        var n = classType.name;
        if (n == null) return false;

        // NOTE: Do not suppress `_Impl_` modules globally.
        // Haxe abstracts compile to `<Abstract>_Impl_` modules which contain required
        // runtime functions (e.g. PositiveInt_Impl_.parse/1). We only suppress
        // truly-internal implementations via package-level rules (e.g. haxe._*).

        // Skip packages that are compiler/macro-only or Haxe-internal
        if (classType.pack != null && classType.pack.length > 0) {
            var top = classType.pack[0];
            if (top == null) top = "";

            // Compiler/macro-only libs (never emit as modules)
            if (top == "reflaxe" || top == "js" || top == "genes") return true;

            // Haxe std: allow by default, but filter internal subpackages starting with underscore
            if (top == "haxe") {
                if (classType.pack.length > 1) {
                    var sub = classType.pack[1];
                    if (sub != null && StringTools.startsWith(sub, "_")) return true; // _call_stack, _constraints, _int32, etc.
                }
            }

            // Underscored pseudo-packages (e.g., _Any, _EnumValue)
            if (StringTools.startsWith(top, "_")) return true;

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
    public function getOriginalVarName(v: TVar): String {
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
    public function toElixirName(haxeName: String): String {
        return reflaxe.elixir.ast.NameUtils.toElixirName(haxeName);
    }
    
    /**
     * Convert package.ClassName to package/class_name.ex path
     * Examples: 
     * - haxe.CallStack → haxe/call_stack  
     * - TestDocClass → test_doc_class
     * - my.nested.Module → my/nested/module
     */
    private function convertPackageToDirectoryPath(classType: ClassType): String {
        if (classType.pack.length == 0) return "";
        
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
    public function getModuleOutputPath(moduleName: String, pack: Array<String> = null): String {
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
    private function setUniversalOutputPath(moduleName: String, pack: Array<String> = null): Void {
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
    private function setFrameworkAwareOutputPath(
        classType: ClassType,
        moduleName: String,
        modulePack: Array<String>
    ): FrameworkNamingResult {
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
                Context.error(
                    'Missing migration timestamp for ${classType.name}. Add one via @:migration({timestamp: "20240101120000"}) (or generate with `mix haxe.gen.migration`).',
                    classType.pos
                );
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
            var finalPack: Array<String> = [appSnake];
            
            // File placement: lib/todo_app/application.ex
            setOutputFileName("application");
            setOutputFileDir(appSnake);
            
            var outputPath = appSnake + "/application.ex";
            #if debug_annotation_transforms
            // DISABLED: Sys.println('[setFrameworkAwareOutputPath] @:application ${classType.name} -> module=${finalModuleName}, path=${outputPath}');
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
            var finalPack: Array<String> = [webSnake];

            // File placement: lib/todo_app_web/endpoint.ex
            setOutputFileName("endpoint");
            setOutputFileDir(webSnake);

            var outputPath = webSnake + "/endpoint.ex";
            #if debug_annotation_transforms
            // DISABLED: Sys.println('[setFrameworkAwareOutputPath] @:endpoint ${classType.name} -> module=${finalModuleName}, path=${outputPath}');
            #end
            return {
                moduleName: finalModuleName,
                modulePack: finalPack,
                outputPath: outputPath
            };
        }

        // Router modules: map to lib/<app_snake>_web/router.ex
        if (classType.meta.has(":router")) {
            var appModuleName = reflaxe.elixir.PhoenixMapper.getAppModuleName();
            var appSnake = reflaxe.elixir.ast.NameUtils.toSnakeCase(appModuleName);
            var webSnake = appSnake + "_web";

            // Final Elixir module name (TodoAppWeb.Router)
            var finalModuleName = appModuleName + "Web.Router";
            var finalPack: Array<String> = [webSnake];

            // File placement: lib/todo_app_web/router.ex
            setOutputFileName("router");
            setOutputFileDir(webSnake);

            var outputPath = webSnake + "/router.ex";
            #if debug_annotation_transforms
            // DISABLED: Sys.println('[setFrameworkAwareOutputPath] @:router ${classType.name} -> module=${finalModuleName}, path=${outputPath}');
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
            var finalPack: Array<String> = [];

            // File placement: lib/todo_app_web.ex (at lib root)
            setOutputFileName(appSnake + "_web");
            setOutputFileDir("");

            var outputPath = appSnake + "_web.ex";
            #if debug_annotation_transforms
            // DISABLED: Sys.println('[setFrameworkAwareOutputPath] @:phoenixWebModule ${classType.name} -> module=${finalModuleName}, path=${outputPath}');
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

    static inline function extractStringMeta(classType: ClassType, metaName: String): Null<String> {
        if (classType.meta == null || !classType.meta.has(metaName)) return null;
        var entries = classType.meta.extract(metaName);
        if (entries == null || entries.length == 0) return null;
        var first = entries[0];
        if (first.params == null || first.params.length == 0) return null;
        return switch (first.params[0].expr) {
            case EConst(CString(value, _)): value;
            case EConst(CInt(value, _)): value;
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
    public function compileClassImpl(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<reflaxe.elixir.ast.ElixirAST> {
        #if debug_compilation_flow
        // DISABLED: trace('[ElixirCompiler.compileClassImpl] START compiling class: ${classType.name}');
        // DISABLED: trace('[ElixirCompiler.compileClassImpl] varFields: ${varFields.length}, funcFields: ${funcFields.length}');
        #end

        if (classType == null) return null;

        // Skip standard library/internal classes that shouldn't generate Elixir modules
        if (isStandardLibraryClass(classType.name) || shouldSuppressStdEmission(classType)) {
            #if debug_compilation_flow
            // DISABLED: trace('[ElixirCompiler.compileClassImpl] Skipping std/internal class: ${classType.name}');
            #end
            return null;
        }

        // Check for @:native annotation to determine base module name/pack
        var moduleName = classType.name;
        var modulePack = classType.pack;
        
        if (classType.meta.has(":native")) {
            var nativeMeta = classType.meta.extract(":native");
            if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                switch(nativeMeta[0].params[0].expr) {
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
        var outputPath = frameworkNaming.outputPath != null
            ? frameworkNaming.outputPath
            : getModuleOutputPath(moduleName, modulePack);
        moduleOutputPaths.set(moduleName, outputPath);
        // Track BaseType for synthetic outputs
        moduleBaseTypes.set(moduleName, classType);
        
        // Store current class context for use in expression compilation
        this.currentClassType = classType;
        
        // Activate behavior transformer based on class metadata
        // This replaces the old isInPresenceModule flag with a more generic system
        #if debug_behavior_transformer
        // DISABLED: trace('[ElixirCompiler] Compiling class: ${classType.name}');
        #end
        
        if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
            var behaviorName = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.checkAndActivateBehavior(classType);
            #if debug_behavior_transformer
            if (behaviorName != null) {
                // DISABLED: trace('[BehaviorTransformer] Activated behavior "${behaviorName}" for class ${classType.name}');
            } else {
                // DISABLED: trace('[BehaviorTransformer] No behavior found for class ${classType.name}');
            }
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
                if (moduleAST.metadata == null) moduleAST.metadata = {};
                Reflect.setField(moduleAST.metadata, "forceEmit", true);
            }
        }

        #if debug_compilation_flow
        // DISABLED: trace('[ElixirCompiler.compileClassImpl] END compiling class: ${classType.name}');
        #end

        // Return AST directly - transformation and printing handled by ElixirOutputIterator
        return moduleAST;
    }
    
    
    /**
     * Required implementation for GenericCompiler - implements enum compilation
     */
    public function compileEnumImpl(enumType: EnumType, options: Array<EnumOptionData>): Null<reflaxe.elixir.ast.ElixirAST> {
        if (enumType == null) return null;
        
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
    public override function compileExpression(expr: TypedExpr, topLevel: Bool = false): Null<reflaxe.elixir.ast.ElixirAST> {
        // Check for target code injection using Reflaxe's built-in system
        switch(expr.expr) {
            case TCall(e, args):
                // Use Reflaxe's TargetCodeInjection system like C# compiler does
                if (options.targetCodeInjectionName != null) {
                    #if debug_injection
                    // DISABLED: trace('[ElixirCompiler] Checking injection for: ${options.targetCodeInjectionName}');
                    // DISABLED: trace('[ElixirCompiler] Expression type: ${expr.expr}');
                    // DISABLED: trace('[ElixirCompiler] Call target: ${e.expr}');
                    #end

                    final result = TargetCodeInjection.checkTargetCodeInjectionGeneric(
                        options.targetCodeInjectionName,
                        expr,
                        this
                    );

                    #if debug_injection
                    if (result == null) {
                        // DISABLED: trace('[ElixirCompiler] ❌ checkTargetCodeInjectionGeneric returned NULL');
                        // DISABLED: trace('[ElixirCompiler] Trying manual TField detection...');
                    } else {
                        // DISABLED: trace('[ElixirCompiler] ✓ checkTargetCodeInjectionGeneric returned result with ${result.length} entries');
                    }
                    #end

                    if (result != null) {
                        // Special-case: Build AST for known patterns instead of ERaw strings
                        var ectoAst = tryBuildEctoWhereAST(result, expr.pos);
                        if (ectoAst != null) {
                            return ectoAst;
                        }
                        // Process the injection result as string fallback
                        var finalCode = "";
                        var insideString = false;  // Track if we're currently inside a string literal

                        #if debug_injection
                        // DISABLED: trace('[ElixirCompiler] Processing ${result.length} injection entries');
                        #end

                        for (i in 0...result.length) {
                            var entry = result[i];
                            switch(entry) {
                                case Left(code):
                                    // Direct string code - check for string delimiters
                                    #if debug_injection
                                    // DISABLED: trace('[ElixirCompiler] Entry $i - Left: "$code"');
                                    // DISABLED: trace('[ElixirCompiler] insideString BEFORE: $insideString');
                                    #end

                                    finalCode += code;

                                    // Update insideString state by counting unescaped quotes
                                    var j = 0;
                                    while (j < code.length) {
                                        if (code.charAt(j) == '"' && (j == 0 || code.charAt(j-1) != '\\')) {
                                            insideString = !insideString;
                                            #if debug_injection
                                            // DISABLED: trace('[ElixirCompiler] Quote at position $j, insideString now: $insideString');
                                            #end
                                        }
                                        j++;
                                    }

                                    #if debug_injection
                                    // DISABLED: trace('[ElixirCompiler] insideString AFTER: $insideString');
                                    #end

	                                case Right(ast):
	                                    // Compiled AST - convert to string
	                                    var astStr = reflaxe.elixir.ast.ElixirASTPrinter.printAST(ast);
	                                    var astSubstitution = reflaxe.elixir.ast.ElixirASTPrinter.printASTForInjectionSubstitution(ast);

                                    #if debug_injection
                                    // DISABLED: trace('[ElixirCompiler] Entry $i - Right: AST → "$astStr"');
                                    // DISABLED: trace('[ElixirCompiler] insideString: $insideString');
                                    #end

	                                    if (insideString) {
	                                        // Inside string literal: ensure the interpolated expression is a single valid expression
	                                        // Wrap multi-statement or assignment-heavy outputs in an IIFE inside #{...}
	                                        var needsIife = (astStr.indexOf("\n") != -1) || (astStr.indexOf("=") != -1 && astStr.indexOf("==") == -1);
	                                        var wrapped = needsIife ? '(fn -> ' + astStr + ' end).()' : astStr;
	                                        finalCode += '#{' + wrapped + '}';
	                                    } else {
	                                        // Outside string: direct substitution
	                                        #if debug_injection
	                                        // DISABLED: trace('[ElixirCompiler] Direct substitution (not in string)');
	                                        #end
	                                        finalCode += astSubstitution;
	                                    }
	                            }
	                        }

                        #if debug_injection
                        // DISABLED: trace('[ElixirCompiler] Final injection code: "$finalCode"');
                        #end

                        // Return as raw Elixir code
                        return reflaxe.elixir.ast.ElixirAST.makeAST(
                            reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERaw(finalCode)
                        );
                    }

                    // WORKAROUND: Reflaxe's checkTargetCodeInjectionGeneric only detects TIdent,
                    // but Haxe sometimes types untyped __elixir__() as TField or other patterns.
                    // Manually check for __elixir__ in TField, TLocal, etc.
                    var isInjectionCall = switch(e.expr) {
                        case TIdent(id): id == options.targetCodeInjectionName;
                        case TField(_, fa):
                            switch(fa) {
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
                    if (isInjectionCall) {
                        // DISABLED: trace('[ElixirCompiler] ✓ Manual detection: Found ${options.targetCodeInjectionName} call');
                    }
                    #end

                    if (isInjectionCall && args.length > 0) {
                        // Manual injection processing (same as Reflaxe's algorithm)
                        final injectionString: String = switch(args[0].expr) {
                            case TConst(TString(s)): s;
                            case _: "";
                        };

                        if (injectionString != "") {
                            #if debug_injection
                            // DISABLED: trace('[ElixirCompiler] Manual injection processing: "${injectionString.substr(0, 50)}..."');
                            // DISABLED: trace('[ElixirCompiler] Number of parameter arguments: ${args.length - 1}');
                            #end

                            // Try Ecto where AST build from manual path
                            if (injectionString.indexOf("Ecto.Query.where") != -1 && injectionString.indexOf("[t]") != -1 && args.length >= 3) {
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
                                        var condition = reflaxe.elixir.ast.ElixirAST.makeAST(
                                            reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERaw('t.' + fieldName + ' ' + opStr + ' ^(' + rhsStr + ')')
                                        );
                                        var whereCall = reflaxe.elixir.ast.ElixirAST.makeAST(
                                            reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERemoteCall(
                                                reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("Ecto.Query")),
                                                "where",
                                                [queryAst, binding, condition]
                                            )
                                        );
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
                                if (char == '"' && (i == 0 || injectionString.charAt(i-1) != '\\')) {
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
                                                // DISABLED: trace('[ElixirCompiler] Substituting {$num} with "$argStr" (insideString: $insideString)');
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
                            // DISABLED: trace('[ElixirCompiler] Manual injection final code: "$finalCode"');
                            #end

                            return reflaxe.elixir.ast.ElixirAST.makeAST(
                                reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERaw(finalCode)
                            );
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
    private function tryBuildEctoWhereAST(result:Array<haxe.ds.Either<String, reflaxe.elixir.ast.ElixirAST>>, ?pos:haxe.macro.Expr.Position): Null<reflaxe.elixir.ast.ElixirAST> {
        if (result == null) return null;
        // Concatenate string parts and capture first two AST args ({0} and {1})
        var code = new StringBuf();
        var queryAst: Null<reflaxe.elixir.ast.ElixirAST> = null;
        var rhsAst: Null<reflaxe.elixir.ast.ElixirAST> = null;
        for (entry in result) switch (entry) {
            case Left(s): code.add(s);
            case Right(ast):
                if (queryAst == null) queryAst = ast; else if (rhsAst == null) rhsAst = ast;
        }
        var s = code.toString();
        #if debug_injection
        // DISABLED: trace('[ElixirCompiler] tryBuildEctoWhereAST code="$s"');
        // DISABLED: trace('[ElixirCompiler] tryBuildEctoWhereAST queryAst=' + (queryAst != null));
        // DISABLED: trace('[ElixirCompiler] tryBuildEctoWhereAST rhsAst=' + (rhsAst != null));
        #end
        // Fast check: contains Ecto.Query.where and [t]
        if (s.indexOf("Ecto.Query.where") == -1 || s.indexOf("[t]") == -1) return null;
        // Extract field and operator in pattern: [t], t.<field> <op> ^(
        var fieldName:String = null;
        var opStr:String = null;
        var rx = ~/\[t\]\s*,\s*t\.([a-zA-Z0-9_]+)\s*(==|!=|<=|>=|<|>)\s*\^\(/;
        if (rx.match(s)) {
            fieldName = rx.matched(1);
            opStr = rx.matched(2);
        } else {
            #if debug_injection
            // DISABLED: trace('[ElixirCompiler] tryBuildEctoWhereAST regex did not match');
            #end
            return null;
        }
        if (queryAst == null || rhsAst == null) return null;
        // Build AST: Ecto.Query.where(queryAst, [t], t.field <op> ^(rhs))
        var mod = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERemoteCall(
            reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("Kernel")),
            "require",
            [reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("Ecto.Query"))]
        ));
        // We do not emit explicit require; compiler can add imports elsewhere.
        var binding = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EList([
            reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("t"))
        ]));
        // Build condition as structured AST to enable downstream analysis (no ERaw)
        var lhsField = reflaxe.elixir.ast.ElixirAST.makeAST(
            reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EField(
                reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("t")),
                fieldName
            )
        );
        inline function toOp(op:String): reflaxe.elixir.ast.ElixirAST.EBinaryOp {
            return switch (op) {
                case "==": reflaxe.elixir.ast.ElixirAST.EBinaryOp.Equal;
                case "!=": reflaxe.elixir.ast.ElixirAST.EBinaryOp.NotEqual;
                case "<":  reflaxe.elixir.ast.ElixirAST.EBinaryOp.Less;
                case "<=": reflaxe.elixir.ast.ElixirAST.EBinaryOp.LessEqual;
                case ">":  reflaxe.elixir.ast.ElixirAST.EBinaryOp.Greater;
                case ">=": reflaxe.elixir.ast.ElixirAST.EBinaryOp.GreaterEqual;
                default: reflaxe.elixir.ast.ElixirAST.EBinaryOp.Equal; // conservative fallback
            };
        }
        var pinnedRhs = reflaxe.elixir.ast.ElixirAST.makeAST(
            reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EPin(rhsAst)
        );
        var condition = reflaxe.elixir.ast.ElixirAST.makeAST(
            reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EBinary(toOp(opStr), lhsField, pinnedRhs)
        );
        var whereCall = reflaxe.elixir.ast.ElixirAST.makeAST(
            reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERemoteCall(
                reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("Ecto.Query")),
                "where",
                [queryAst, binding, condition]
            )
        );
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
    private function createCompilationContext(): CompilationContext {
        var context = new CompilationContext();
        context.compiler = this;

        // Check if we're compiling within an ExUnit test class
        // This enables proper handling of instance variables in test methods
        if (currentClassType != null && currentClassType.meta.has(":exunit")) {
            context.isInExUnitTest = true;
            #if debug_exunit
            // DISABLED: trace('[ElixirCompiler] Setting isInExUnitTest=true for context (class: ${currentClassType.name})');
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
    private function initializeFeatureFlags(context: CompilationContext): Void {
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
        // DISABLED: trace("Feature flags initialized:");
        for (key in context.astContext.featureFlags.keys()) {
            // DISABLED: trace('  $key: ${context.astContext.featureFlags.get(key)}');
        }
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
    public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<reflaxe.elixir.ast.ElixirAST> {
        // CRITICAL: Function boundary detection for persistent context
        // WHY: Functions need persistent nameMapping across all statements in their body
        // WHAT: TFunction indicates function definition with parameters and body
        // HOW: Delegate to specialized method that maintains context across statements
        switch(expr.expr) {
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

        // DISABLED: trace('[AST Pipeline] After Builder - AST type: ${ast != null ? reflaxe.elixir.util.EnumReflection.enumConstructor(ast.def) : "null"}');

        // Apply transformations to all expressions, not just function bodies
        // Pass context to transformer as well
        if (ast != null) {
            var originalAstId = Std.string(ast);
            var transformedAst = reflaxe.elixir.ast.ElixirASTTransformer.transform(ast, context);
            var transformedAstId = Std.string(transformedAst);

            // DISABLED: trace('[AST Pipeline] After Transformer - Same object: ${originalAstId == transformedAstId}');
            // DISABLED: trace('[AST Pipeline]   Original AST ID: $originalAstId');
            // DISABLED: trace('[AST Pipeline]   Transformed AST ID: $transformedAstId');

            ast = transformedAst;

            #if debug_loop_builder
            // Check if this is a reduce_while call to inspect lambda integrity
            if (ast != null) {
                switch(ast.def) {
                    case ERemoteCall(module, funcName, args):
                        switch(module.def) {
                            case EVar("Enum"):
                                if (funcName == "reduce_while" && args != null && args.length >= 3) {
                                    // DISABLED: trace('[XRay Pipeline] After transformation - Enum.reduce_while detected');
                                    var reducerArg = args[2];
                                    // DISABLED: trace('[XRay Pipeline]   Reducer arg type: ${reflaxe.elixir.util.EnumReflection.enumConstructor(reducerArg.def)}');
                                    switch(reducerArg.def) {
                                        case EFn(clauses):
                                            if (clauses.length > 0) {
                                                var clause = clauses[0];
                                                // DISABLED: trace('[XRay Pipeline]   Lambda body type: ${reflaxe.elixir.util.EnumReflection.enumConstructor(clause.body.def)}');
                                                switch(clause.body.def) {
                                                    case EBlock(exprs):
                                                        // DISABLED: trace('[XRay Pipeline]   Lambda body is EBlock with ${exprs.length} expressions');
                                                    case EIf(_, _, _):
                                                        // DISABLED: trace('[XRay Pipeline]   Lambda body is EIf (correct structure)');
                                                    default:
                                                        // DISABLED: trace('[XRay Pipeline]   Lambda body is: ${reflaxe.elixir.util.EnumReflection.enumConstructor(clause.body.def)}');
                                                }
                                            }
                                        default:
                                            // DISABLED: trace('[XRay Pipeline]   Reducer is not EFn: ${reflaxe.elixir.util.EnumReflection.enumConstructor(reducerArg.def)}');
                                    }
                                }
                            default:
                        }
                    default:
                }
            }
            #end
        }

        // DISABLED: trace('[AST Pipeline] Returning AST to caller');
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
    function compileFunctionWithPersistentContext(expr: TypedExpr, f: haxe.macro.Type.TFunc, topLevel: Bool): Null<reflaxe.elixir.ast.ElixirAST> {
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
    public function generateOutputIterator(): Iterator<DataAndFileInfo<StringOrBytes>> {
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
    public function getSortedModules(): Array<String> {
        var sorted: Array<String> = [];
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
                // DISABLED: trace('[ElixirCompiler] Breaking circular dependency, remaining: ' + [for (k in remaining.keys()) k].join(', '));
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
    function hasSpecialAnnotations(classType: ClassType): Bool {
        return classType.meta.has(":endpoint") ||
               classType.meta.has(":liveview") ||
               classType.meta.has(":schema") ||
               classType.meta.has(":repo") ||
               classType.meta.has(":dbTypes") ||
               classType.meta.has(":postgrexTypes") ||
               classType.meta.has(":gettext") ||
               classType.meta.has(":application") ||
               classType.meta.has(":genserver") ||
               classType.meta.has(":router") ||
               classType.meta.has(":controller") ||
               classType.meta.has(":presence") ||
               classType.meta.has(":phoenixWeb") ||
               classType.meta.has(":phoenixWebModule") ||
               classType.meta.has(":exunit") ||
               classType.meta.has(":coreApi");  // Include @:coreApi classes like Date
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
    function discoverDependencies(classType: ClassType, funcFields: Array<ClassField>): Void {
        #if debug_compilation_flow
        // DISABLED: trace('[ElixirCompiler.discoverDependencies] START for class: ${classType.name} with ${funcFields.length} functions');
        #end

        // Activate behavior transformer for dependency discovery
        // This replaces the old isInPresenceModule flag with a generic system
        var previousBehavior: Null<String> = null;
        if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
            previousBehavior = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.activeBehavior;
            var behaviorName = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.checkAndActivateBehavior(classType);
            #if debug_behavior_transformer
            if (behaviorName != null) {
                // DISABLED: trace('[BehaviorTransformer] Activated behavior "${behaviorName}" for dependency discovery of ${classType.name}');
            }
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
                switch(funcExpr.expr) {
                    case TFunction(tfunc):
                        if (tfunc.expr != null) {
                            // Create context for dependency tracking
                            var context = createCompilationContext();

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
        if (deps != null) {
            // DISABLED: trace('[ElixirCompiler] After dependency discovery for ${currentCompiledModule}: ${[for (k in deps.keys()) k].join(", ")}');
        }
        #end
        
        // Restore previous behavior state
        if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
            reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.activeBehavior = previousBehavior;
        }

        #if debug_compilation_flow
        // DISABLED: trace('[ElixirCompiler.discoverDependencies] END for class: ${classType.name}');
        #end
    }
    
    /**
     * Build AST for a class (generates Elixir module)
     */
	    function buildClassAST(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<reflaxe.elixir.ast.ElixirAST> {

        #if debug_behavior_transformer
        // DISABLED: trace('[ElixirCompiler.buildClassAST] Building class: ${classType.name}');
        // DISABLED: trace('[ElixirCompiler.buildClassAST] Metadata: ${[for (m in classType.meta.get()) m.name]}');
        #end

	        // Skip built-in types and std/internal classes that shouldn't generate modules
	        if (isBuiltinAbstractType(classType.name) || isStandardLibraryClass(classType.name) || shouldSuppressStdEmission(classType)) {
	            return null;
	        }

	        #if (macro && debug_migration_build)
	        if (Context.defined("ecto_migrations_exs") && classType.meta != null && classType.meta.has(":migration")) {
	            Sys.println('[MigrationBuild] ' + classType.module + '.' + classType.name + ' funcFields=' + (funcFields != null ? Std.string(funcFields.length) : "null"));
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
        var previousBehavior: Null<String> = null;
        if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
            previousBehavior = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.activeBehavior;
            var behaviorName = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.checkAndActivateBehavior(classType);
            #if debug_behavior_transformer
            if (behaviorName != null) {
                // DISABLED: trace('[BehaviorTransformer] Activated behavior "${behaviorName}" for building ${classType.name} module');
            } else {
                // DISABLED: trace('[BehaviorTransformer] No behavior found for ${classType.name}');
            }
            #end
        }
        
        // Special-case: Generate Gettext module skeletons from @:gettext classes
        if (classType.meta.has(":gettext")) {
            var moduleName = reflaxe.elixir.ast.builders.ModuleBuilder.extractModuleName(classType);
            // Determine otp_app from module prefix before "Web" when available (TodoAppWeb.* → :todo_app)
            var appPrefix: Null<String> = null;
            var webIdx = moduleName.indexOf("Web");
            if (webIdx > 0) appPrefix = moduleName.substr(0, webIdx);
            if (appPrefix == null || appPrefix.length == 0) {
                try appPrefix = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e) {}
            }
            if (appPrefix == null || appPrefix.length == 0) appPrefix = classType.name; // conservative fallback
            var appAtom = reflaxe.elixir.ast.NameUtils.toSnakeCase(appPrefix);
            // Build: defmodule <Module> do\n  use Gettext.Backend, otp_app: :app\nend
            var useStmt = reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EUse("Gettext.Backend", [
                reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EKeywordList([
                    { key: "otp_app", value: reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EAtom(appAtom)) }
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
        // DISABLED: trace('[ElixirCompiler] Using provided funcFields parameter: ${funcFields.length} functions');
        // DISABLED: trace('[ElixirCompiler] Using provided varFields parameter: ${varFields.length} variables');
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

        // Collect instance field names (snake_case) for this class.
        // Used to avoid parameter/field naming collisions and to drive instance-field lowering.
        var instanceFieldNames: Map<String, Bool> = new Map();
        for (field in classType.fields.get()) {
            switch (field.kind) {
                case FVar(_, _):
                    instanceFieldNames.set(reflaxe.elixir.ast.NameUtils.toSnakeCase(field.name), true);
                default:
            }
        }

	        // Build fields from the funcFields parameter (which is already ClassFuncData array)
	        var fields: Array<reflaxe.elixir.ast.ElixirAST> = [];

	        inline function ast(def: ElixirASTDef): reflaxe.elixir.ast.ElixirAST {
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
	            var staticVars: Array<{ name: String, init: reflaxe.elixir.ast.ElixirAST }> = [];

	            for (varData in varFields) {
	                if (!varData.isStatic) continue;

	                var elixirName = reflaxe.elixir.ast.NameUtils.toSnakeCase(varData.field.name);
	                var initExpr: Null<TypedExpr> = null;

	                try initExpr = varData.field.expr() catch (e) {}
	                if (initExpr == null) {
	                    var untypedDefault = varData.getDefaultUntypedExpr();
	                    if (untypedDefault != null) {
	                        try initExpr = Context.typeExpr(untypedDefault) catch (e) {}
	                    }
	                }

	                var initAst = if (initExpr != null) {
	                    initExpr = reflaxe.elixir.preprocessor.TypedExprPreprocessor.preprocess(initExpr);
	                    reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(initExpr, context);
	                } else {
	                    ast(ENil);
	                };

	                staticVars.push({ name: elixirName, init: initAst });
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

	                function buildStaticKeyExpr(keyAtom: reflaxe.elixir.ast.ElixirAST): reflaxe.elixir.ast.ElixirAST {
	                    return ast(ETuple([staticNs, selfModule, keyAtom]));
	                }

	                // __haxe_static_get__(key, init)
	                var getKeyPat: EPattern = PVar("key");
	                var getInitPat: EPattern = PVar("init");
	                var getKeyVar = ast(EVar("key"));
	                var getInitVar = ast(EVar("init"));
	                var getStaticKeyVar = ast(EVar("static_key"));
	                var getValueVar = ast(EVar("value"));

	                var getBody = ast(EBlock([
	                    ast(EMatch(PVar("static_key"), buildStaticKeyExpr(getKeyVar))),
	                    ast(ECase(
	                        ast(ERemoteCall(ast(EVar("Process")), "get", [getStaticKeyVar])),
	                        [
	                            {
	                                pattern: PTuple([PLiteral(setTag), PVar("value")]),
	                                body: getValueVar
	                            },
	                            {
	                                pattern: PLiteral(ast(ENil)),
	                                body: ast(EBlock([
	                                    ast(EMatch(PVar("value"), getInitVar)),
	                                    ast(ERemoteCall(ast(EVar("Process")), "put", [
	                                        getStaticKeyVar,
	                                        ast(ETuple([setTag, getValueVar]))
	                                    ])),
	                                    getValueVar
	                                ]))
	                            }
	                        ]
	                    ))
	                ]));

	                fields.push(ast(EDefp("__haxe_static_get__", [getKeyPat, getInitPat], null, getBody)));

	                // __haxe_static_put__(key, value)
	                var putKeyPat: EPattern = PVar("key");
	                var putValuePat: EPattern = PVar("value");
	                var putKeyVar = ast(EVar("key"));
	                var putValueVar = ast(EVar("value"));
	                var putStaticKeyVar = ast(EVar("static_key"));
	                var putBody = ast(EBlock([
	                    ast(EMatch(PVar("static_key"), buildStaticKeyExpr(putKeyVar))),
	                    ast(ERemoteCall(ast(EVar("Process")), "put", [
	                        putStaticKeyVar,
	                        ast(ETuple([setTag, putValueVar]))
	                    ])),
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
		            if (expr == null) continue;

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
		            // Preprocessor substitutions are TVar.id-keyed but IDs are not guaranteed globally
		            // unique across independent TypedExpr trees. Keep substitutions scoped per function.
		            var previousInfraVarSubstitutions = context.infraVarSubstitutions;
		            context.infraVarSubstitutions = new Map();
		            // Loop control state must not leak across functions (break/continue context).
		            var previousLoopControlStateStack = context.loopControlStateStack;
		            context.loopControlStateStack = [];

		            try {
		            
		            // Preprocess the function body to eliminate infrastructure variables
		            expr = reflaxe.elixir.preprocessor.TypedExprPreprocessor.preprocess(expr);
		            // Capture infrastructure-variable substitutions produced by the preprocessor for
		            // any builder paths that recompile sub-expressions by TVar.id.
		            context.infraVarSubstitutions = reflaxe.elixir.preprocessor.TypedExprPreprocessor.getLastSubstitutions();

		            #if debug_ast_builder
		            // DISABLED: trace('[ElixirCompiler] Compiling function: ${funcData.field.name}');
		            if (expr != null) {
                // DISABLED: trace('[ElixirCompiler]   Body type: ${reflaxe.elixir.util.EnumReflection.enumConstructor(expr.expr)}');
                switch(expr.expr) {
                    case TReturn(e) if (e != null):
                        // DISABLED: trace('[ElixirCompiler]   TReturn contains: ${reflaxe.elixir.util.EnumReflection.enumConstructor(e.expr)}');
                        switch(e.expr) {
                            case TSwitch(_, cases, _):
                                // DISABLED: trace('[ElixirCompiler]     Direct return of TSwitch with ${cases.length} cases');
                            case TLocal(v):
                                // DISABLED: trace('[ElixirCompiler]     Return of TLocal: ${v.name}');
                            default:
                                // DISABLED: trace('[ElixirCompiler]     Return of: ${reflaxe.elixir.util.EnumReflection.enumConstructor(e.expr)}');
                        }
                    case TBlock(exprs):
                        // DISABLED: trace('[ElixirCompiler]   TBlock with ${exprs.length} expressions');
                        if (exprs.length > 0) {
                            var last = exprs[exprs.length - 1];
                            // DISABLED: trace('[ElixirCompiler]     Last expr: ${reflaxe.elixir.util.EnumReflection.enumConstructor(last.expr)}');
                        }
                    default:
                        // DISABLED: trace('[ElixirCompiler]   Other: ${reflaxe.elixir.util.EnumReflection.enumConstructor(expr.expr)}');
                }
            }
            #end

            // Check if this is an ExUnit test method FIRST
            // ExUnit test methods are special - they're NOT instance methods
            // even if they appear to be in the Haxe class structure
            // Note: In some cases, metadata is stored with the colon prefix (":test")
            // Check both with and without colon to be safe
            var isExUnitTestMethod = funcData.field.meta.has("test") || 
                                     funcData.field.meta.has("setup") ||
                                     funcData.field.meta.has("setupAll") ||
                                     funcData.field.meta.has("teardown") ||
                                     funcData.field.meta.has("teardownAll") ||
                                     funcData.field.meta.has(":test") ||
                                     funcData.field.meta.has(":setup") ||
                                     funcData.field.meta.has(":setupAll") ||
                                     funcData.field.meta.has(":teardown") ||
                                     funcData.field.meta.has(":teardownAll");
            
            #if debug_exunit
            // DISABLED: trace('[ElixirCompiler] Checking ${funcData.field.name}: has("test")=${funcData.field.meta.has("test")}, isExUnitTestMethod=$isExUnitTestMethod');
            // Let's see what metadata IS present
            if (funcData.field.name.indexOf("test") == 0) {
                var metaList = [];
                for (m in funcData.field.meta.get()) {
                    metaList.push(m.name);
                }
                // DISABLED: trace('[ElixirCompiler]   Metadata present on ${funcData.field.name}: [${metaList.join(", ")}]');
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
                // DISABLED: trace('[ElixirCompiler] Set isInExUnitTest=true for function ${funcData.field.name}');
                // DISABLED: trace('[ElixirCompiler] Context check immediately after setting: isInExUnitTest=${context.isInExUnitTest}');
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
                // DISABLED: trace('[ElixirCompiler] Processing ${funcData.field.name} - funcData.tfunc is NOT null, registering ${funcData.tfunc.args.length} parameters');
                // DISABLED: trace('[ElixirCompiler] Context tempVarRenameMap BEFORE registration: ${Lambda.count(context.tempVarRenameMap)} entries');
                #end

                for (arg in funcData.tfunc.args) {
                    var originalName = arg.v.name;
                    var idKey = Std.string(arg.v.id);
                    functionParameterIdKeys.push(idKey);
                    context.functionParameterIds.set(idKey, true);

                    #if debug_variable_renaming
                    // DISABLED: trace('[ElixirCompiler] Processing parameter for ${funcData.field.name}: "$originalName" (id: $idKey)');
                    #end

                    // Check if parameter has numeric suffix that indicates shadowing
                    var strippedName = originalName;
                    var renamedPattern = ~/^(.+?)(\d+)$/;
                    if (renamedPattern.match(originalName)) {
                        var baseWithoutSuffix = renamedPattern.matched(1);
                        var suffix = renamedPattern.matched(2);

                        // Only strip suffix for common field names
                        var commonFieldNames = ["options", "columns", "name", "value", "type", "data", "fields", "items", "priority"];
                        if ((suffix == "2" || suffix == "3") && commonFieldNames.indexOf(baseWithoutSuffix) >= 0) {
                            strippedName = baseWithoutSuffix;

                            #if debug_variable_renaming
                            // DISABLED: trace('[ElixirCompiler] Registering renamed parameter mapping: $originalName (id: ${arg.v.id}) -> $strippedName');
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
                    // DISABLED: trace('[ElixirCompiler] About to register for ${funcData.field.name}: idKey="$idKey" originalName="$originalName" finalName="$finalName" unused=$isUnused');
                    // DISABLED: trace('[ElixirCompiler] Map exists check: ${context.tempVarRenameMap.exists(idKey)}');
                    #end

                    if (!context.tempVarRenameMap.exists(idKey)) {
                        #if debug_variable_renaming
                        // DISABLED: trace('[ElixirCompiler] ENTERED if block - about to set mappings');
                        #end

                        // Dual-key storage: ID for pattern positions, name for EVar references
                        context.tempVarRenameMap.set(idKey, finalName);           // ID-based (pattern matching)
                        context.tempVarRenameMap.set(originalName, finalName);    // NAME-based (EVar renaming)

                        #if debug_variable_renaming
                        // DISABLED: trace('[ElixirCompiler] COMPLETED setting mappings for idKey=$idKey');
                        // DISABLED: trace('[ElixirCompiler] Context hashcode: ${untyped context.__id}');
                        // DISABLED: trace('[ElixirCompiler] Map hashcode: ${untyped context.tempVarRenameMap.__id}');
                        #end

                        #if debug_variable_renaming
                        // DISABLED: trace('[ElixirCompiler] ✓ Registered dual-key: id=$idKey name=$originalName -> $finalName');
                        // DISABLED: trace('[ElixirCompiler] Map size after registration: ${Lambda.count(context.tempVarRenameMap)}');
                        #end

                        #if debug_hygiene
                        // DISABLED: trace('[Hygiene] Dual-key registered: id=$idKey name=$originalName -> $finalName');
                        #end
                    } else {
                        #if debug_variable_renaming
                        // DISABLED: trace('[ElixirCompiler] ✗ Skipped registration (idKey already exists): $idKey');
                        #end
                    }
                }

                #if debug_variable_renaming
                // DISABLED: trace('[ElixirCompiler] AFTER registration loop for ${funcData.field.name} - map has ${Lambda.count(context.tempVarRenameMap)} entries');
                #end
            }

            // Build the function body with proper context
            // Special handling for direct switch returns that may have lost context
            #if debug_switch_return
            // DISABLED: trace("[SwitchReturnDebug] Building function body for: " + funcData.field.name);
            if (expr != null) {
                // DISABLED: trace("[SwitchReturnDebug] expr.expr type: " + reflaxe.elixir.util.EnumReflection.enumConstructor(expr.expr));
            } else {
                // DISABLED: trace("[SwitchReturnDebug] expr is null (no body)");
            }
            #end

            #if debug_exunit
            // DISABLED: trace('[ElixirCompiler] About to build funcBody for ${funcData.field.name}, context.isInExUnitTest=${context.isInExUnitTest}');
            #end
            
            var funcBody = switch(expr.expr) {
                case TReturn(e) if (e != null):
                    #if debug_switch_return
                    // DISABLED: trace("[SwitchReturnDebug] Found TReturn with non-null expression");
                    // DISABLED: trace("[SwitchReturnDebug] Return expr type: " + (e != null ? reflaxe.elixir.util.EnumReflection.enumConstructor(e.expr) : "null"));
                    #end

                    // Check if it's a return of a switch (potentially wrapped in metadata)
                    var innerExpr = e;
                    switch(e.expr) {
                        case TMeta(_, inner):
                            #if debug_switch_return
                            // DISABLED: trace("[SwitchReturnDebug] Found TMeta wrapper, unwrapping");
                            #end
                            innerExpr = inner;
                        case _:
                    }

                    #if debug_switch_return
                    // DISABLED: trace("[SwitchReturnDebug] Inner expr type: " + reflaxe.elixir.util.EnumReflection.enumConstructor(innerExpr.expr));
                    #end

                    switch(innerExpr.expr) {
                        case TSwitch(_, _, _):
                            #if debug_switch_return
                            // DISABLED: trace("[SwitchReturnDebug] *** Direct switch return detected! Building switch AST directly ***");
                            #end
                            // For direct switch returns, build the switch expression and wrap in parentheses
                            // This ensures the full case structure is preserved
                            var switchAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e, context);

                            #if debug_switch_return
                            // DISABLED: trace("[SwitchReturnDebug] Built switch AST def: " + switchAST.def);
                            #end

                            // The switch itself is the body - no need for additional wrapping
                            switchAST;
                        case _:
                            #if debug_switch_return
                            // DISABLED: trace("[SwitchReturnDebug] Not a switch, building normal return");
                            #end
                            // Normal return handling
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);
                    }
                case _:
                    #if debug_switch_return
                    // DISABLED: trace("[SwitchReturnDebug] Not a direct return, building normally");
                    #end
                    // Normal expression handling
                    #if debug_variable_renaming
                    // DISABLED: trace('[ElixirCompiler] About to call buildFromTypedExpr for ${funcData.field.name} - context.tempVarRenameMap has ${Lambda.count(context.tempVarRenameMap)} entries');
                    #end
                    reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);
            };

            #if debug_ast_builder
            // DISABLED: trace('[ElixirCompiler] Function ${funcData.field.name} body AST: ${funcBody.def}');
            #end

            // Clear function parameter tracking now that the body has been built.
            // This prevents parameter IDs from leaking into subsequent function compilations.
            for (idKey in functionParameterIdKeys) {
                context.functionParameterIds.remove(idKey);
            }

            // Get function parameters from tfunc
            var params: Array<EPattern> = [];

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

            // Create function definition
            // Use toSafeElixirFunctionName to handle reserved keywords
            var elixirName = reflaxe.elixir.ast.NameUtils.toSafeElixirFunctionName(funcData.field.name);

            // Haxe entrypoints (`static function main()`) are not required to be `public`,
            // but Elixir warnings-as-errors will flag unused private functions in examples.
            // Emit `main/0` as a public `def` so downstream code can call `Module.main()`
            // (and to keep any private helpers it calls from being flagged as unused).
            var isMainEntrypoint = isStaticMethod && funcData.field.name == "main";

            // Constructors compile to a module-level `new/arity` that returns an initialized struct/map.
            // Haxe constructors mutate `this`; in Elixir we build a fresh `struct` map, run the body
            // against it, and return it.
            if (isConstructor) {
                // Build initial map with all instance fields present so `%{struct | field: ...}` updates are safe.
                var initPairs: Array<reflaxe.elixir.ast.ElixirAST.EMapPair> = [];
                for (field in classType.fields.get()) {
                    switch (field.kind) {
                        case FVar(_, _):
                            var snakeFieldName = reflaxe.elixir.ast.NameUtils.toSnakeCase(field.name);
                            initPairs.push({
                                key: reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EAtom(snakeFieldName)),
                                value: reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ENil)
                            });
                        default:
                    }
                }

                var initStruct = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EMap(initPairs));
                var initAssign = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EMatch(PVar("struct"), initStruct));

                var ctorExprs: Array<reflaxe.elixir.ast.ElixirAST> = [initAssign];
                switch (funcBody.def) {
                    case EBlock(exprs):
                        for (e in exprs) if (e != null) ctorExprs.push(e);
                    default:
                        if (funcBody != null) ctorExprs.push(funcBody);
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
            var isAbstractImpl = switch (classType.kind) { case KAbstractImpl(_): true; default: false; };
            if (!isAbstractImpl && classType.name != null && classType.name.endsWith("_Impl_")) isAbstractImpl = true;

            function isEmptyBody(body: Null<reflaxe.elixir.ast.ElixirAST>): Bool {
                if (body == null || body.def == null) return true;
                return switch (body.def) {
                    case ENil:
                        true;
                    case ERaw(code):
                        code == null || code.trim() == "";
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

            var isAbstractIdentityStub = (funcData.field.name == "_new" || funcData.field.name == "fromString" || funcData.field.name == "from_string"
                || elixirName == "_new" || elixirName == "from_string");

            if (isAbstractImpl && funcBody != null && params.length == 1 && isAbstractIdentityStub) {
                var bodyIsEmpty = isEmptyBody(funcBody);

                if (bodyIsEmpty) {
                    var argName = switch (params[0]) { case PVar(n): n; default: null; };
                    if (argName != null && argName.length > 0) {
                        funcBody = reflaxe.elixir.ast.ElixirAST.makeAST(reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar(argName));
                    }
                }
            }

            var funcDef = (funcData.field.isPublic || isMainEntrypoint) ?
                EDef(elixirName, params, null, funcBody) :
                EDefp(elixirName, params, null, funcBody);

            if (isMainEntrypoint && currentCompiledModule != null && modulesWithBootstrap.indexOf(currentCompiledModule) < 0) {
                modulesWithBootstrap.push(currentCompiledModule);
            }

            // Check for test-related metadata on the function field
            var funcMetadata: reflaxe.elixir.ast.ElixirAST.ElixirMetadata = {};

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
            if (funcMetadata.isTest) {
                // DISABLED: trace('[ElixirCompiler] Set isTest=true for function ${funcData.field.name}');
            }
            #end

            // Check for test tags (gather both :tag and tag forms)
            var tagMeta = funcData.field.meta.extract("tag");
            var tagMetaAlt = funcData.field.meta.extract(":tag");
            if (tagMetaAlt != null && tagMetaAlt.length > 0) {
                if (tagMeta == null) tagMeta = tagMetaAlt; else tagMeta = tagMeta.concat(tagMetaAlt);
            }
            if (tagMeta != null && tagMeta.length > 0) {
                var tags = [];
                for (entry in tagMeta) {
                    if (entry.params != null) {
                        for (param in entry.params) {
                            switch(param.expr) {
                                case EConst(CString(tag)): tags.push(tag);
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
                if (describeMeta == null) describeMeta = describeMetaAlt; else describeMeta = describeMeta.concat(describeMetaAlt);
            }
            if (describeMeta != null && describeMeta.length > 0) {
                for (entry in describeMeta) {
                    if (entry.params != null && entry.params.length > 0) {
                        switch(entry.params[0].expr) {
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
			            } catch (e: Dynamic) {
			                // Restore the class-level context map for the next function.
			                context.tempVarRenameMap = previousTempVarRenameMap;
			                context.infrastructureVarInitValues = previousInfraVarInitValues;
			                context.infraVarSubstitutions = previousInfraVarSubstitutions;
			                context.loopControlStateStack = previousLoopControlStateStack;
			                throw e;
			            }

			            // Restore the class-level context map for the next function.
			            context.tempVarRenameMap = previousTempVarRenameMap;
			            context.infrastructureVarInitValues = previousInfraVarInitValues;
			            context.infraVarSubstitutions = previousInfraVarSubstitutions;
			            context.loopControlStateStack = previousLoopControlStateStack;
			        }

        // Prepare metadata for special module types BEFORE building the module
        var metadata: ElixirMetadata = {};
        
        // Detect and store parent class information for inheritance handling
        if (classType.superClass != null) {
            var parentClass = classType.superClass.t.get();
            var parentModuleName = if (parentClass.meta.has(":native")) {
                // Use @:native name if specified
                var nativeMeta = parentClass.meta.extract(":native");
                if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                    switch(nativeMeta[0].params[0].expr) {
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
                if (currentClass.pack.length == 1 && currentClass.pack[0] == "haxe" && currentClass.name == "Exception") {
                    isException = true;
                    break;
                }
                currentClass = if (currentClass.superClass != null) currentClass.superClass.t.get() else null;
            }
            metadata.isException = isException;
            
            #if debug_inheritance
            // DISABLED: trace('[ElixirCompiler] Class ${classType.name} extends ${parentModuleName}, isException: ${isException}');
            #end
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
            // DISABLED: trace('[ElixirCompiler] Set isLiveView=true metadata for ${classType.name}');
            #end
        }

        // Enable Application transformation pass for @:application modules
        if (classType.meta.has(":application")) {
            metadata.isApplication = true;
            #if debug_annotation_transforms
            // DISABLED: trace('[ElixirCompiler] Set isApplication=true metadata for ${classType.name}');
            // DISABLED: trace('[ElixirCompiler] Passing ${fields.length} fields to ModuleBuilder for ${classType.name}');
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
            // DISABLED: trace('[ElixirCompiler] Set isRepo=true metadata for ${classType.name}');
            #end
        }
        
        // Enable Schema transformation pass for @:schema modules
        if (classType.meta.has(":schema")) {
            metadata.isSchema = true;

            #if debug_annotation_transforms
            // DISABLED: trace('[ElixirCompiler] Schema processing for ${classType.name}');
            // DISABLED: trace('[ElixirCompiler] varFields.length = ${varFields.length}');
            // Also check classType.fields directly from Haxe type system
            var typeFields = classType.fields.get();
            // DISABLED: trace('[ElixirCompiler] classType.fields.get().length = ${typeFields.length}');
            for (f in typeFields) {
                // DISABLED: trace('[ElixirCompiler]   field: ${f.name}, kind: ${f.kind}, meta: [${[for (m in f.meta.get()) m.name].join(", ")}]');
            }
            #end

            // Extract table name from @:schema annotation if provided
            var schemaMeta = classType.meta.extract(":schema");
            if (schemaMeta.length > 0 && schemaMeta[0].params != null && schemaMeta[0].params.length > 0) {
                switch(schemaMeta[0].params[0].expr) {
                    case EConst(CString(tableName, _)):
                        metadata.tableName = tableName;
                    default:
                }
            }

            // Check for @:timestamps annotation
            if (classType.meta.has(":timestamps")) {
                metadata.hasTimestamps = true;
            }

            // Extract @:changeset annotation parameters
            // Format: @:changeset(["field1", "field2"], ["required1"])
            // First param: fields to cast, Second param: required fields
            if (classType.meta.has(":changeset")) {
                var changesetMeta = classType.meta.extract(":changeset");
                if (changesetMeta != null && changesetMeta.length > 0) {
                    var params = changesetMeta[0].params;
                    if (params != null && params.length >= 1) {
                        // First parameter: cast fields
                        var castFieldsExpr = params[0];
                        metadata.changesetCastFields = extractStringArrayFromExpr(castFieldsExpr);

                        // Second parameter (optional): required fields
                        if (params.length >= 2) {
                            var requiredFieldsExpr = params[1];
                            metadata.changesetRequiredFields = extractStringArrayFromExpr(requiredFieldsExpr);
                        } else {
                            metadata.changesetRequiredFields = [];
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
                switch(field.kind) {
                    case FVar(read, write):
                        if (isField && !isVirtual) {
                            var fieldName = field.name;
                            var fieldType = schemaTypeNameFromType(field.type);
                            schemaFields.push({
                                name: fieldName,
                                type: fieldType
                            });
                            #if debug_annotation_transforms
                            // DISABLED: trace('[ElixirCompiler] Added schema field: ${fieldName} (${fieldType})');
                            #end
                        }
                    default:
                        // Skip functions and other field kinds
                }
            }
            metadata.schemaFields = schemaFields;

            // Store the fully qualified class name for lookups
            metadata.haxeFqcn = classType.pack.length > 0
                ? classType.pack.join(".") + "." + classType.name
                : classType.name;

            // Check if user defined their own changeset function (with implementation, not just extern declaration)
            // WHY: User-defined changesets using __elixir__() generate ERaw nodes that can't be detected
            //      by AST structure alone in transformers. This metadata flag allows clean detection.
            // WHAT: We check funcFields (available here) for a function named "changeset" WITH a body
            // HOW: Check for function name AND that it has an expression (not extern)
            for (funcData in funcFields) {
                if (funcData.field.name == "changeset") {
                    // Only count as user-defined if it has a body (not extern)
                    switch(funcData.field.kind) {
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
            // DISABLED: trace('[ElixirCompiler] Set isSchema=true metadata for ${classType.name}');
            // DISABLED: trace('[ElixirCompiler] Table name: ${metadata.tableName}, hasTimestamps: ${metadata.hasTimestamps}');
            // DISABLED: trace('[ElixirCompiler] Schema fields: ${schemaFields.length} fields collected');
            // DISABLED: trace('[ElixirCompiler] hasUserChangeset: ${metadata.hasUserChangeset}');
            #end
        }
        
        // Enable Supervisor transformation pass for @:supervisor modules
        if (classType.meta.has(":supervisor")) {
            metadata.isSupervisor = true;
            #if debug_annotation_transforms
            // DISABLED: trace('[ElixirCompiler] Set isSupervisor=true metadata for ${classType.name}');
            #end
        }

        // Enable Router transformation pass for @:router modules
        if (classType.meta.has(":router")) {
            metadata.isRouter = true;
            metadata.routerRoutes = extractRouterRoutesFromMeta(classType);
            #if debug_annotation_transforms
            // DISABLED: trace('[ElixirCompiler] Set isRouter=true metadata for ${classType.name}');
            #end
        }

        // Enable Presence transformation pass for @:presence modules
        if (classType.meta.has(":presence")) {
            metadata.isPresence = true;
            #if debug_annotation_transforms
            // DISABLED: trace('[ElixirCompiler] Set isPresence=true metadata for ${classType.name}');
            #end
        }

        // Enable Endpoint transformation pass for @:endpoint modules
        // Endpoints are also supervisors and need child_spec/start_link preservation
        if (classType.meta.has(":endpoint")) {
            metadata.isEndpoint = true;
            // Endpoints are supervisors too - they need child_spec/start_link
            metadata.isSupervisor = true;
            #if debug_annotation_transforms
            // DISABLED: trace('[ElixirCompiler] Set isEndpoint=true and isSupervisor=true metadata for ${classType.name}');
            #end
        }

        // Enable PhoenixWeb transformation pass for @:phoenixWebModule or @:phoenixWeb modules
        if (classType.meta.has(":phoenixWebModule") || classType.meta.has(":phoenixWeb")) {
            metadata.isPhoenixWeb = true;
            #if debug_annotation_transforms
            // DISABLED: trace('[ElixirCompiler] Set isPhoenixWeb=true metadata for ${classType.name}');
            #end
        }

        // Record snake_case instance fields for downstream struct/map lowering passes.
        // This enables generic, shape-based rewriting of `field = ...` to `%{struct | field: ...}`.
        var instanceFieldList = [for (k in instanceFieldNames.keys()) k];
        instanceFieldList.sort(function(a, b) {
            return a < b ? -1 : (a > b ? 1 : 0);
        });
        metadata.instanceFields = instanceFieldList;

        // Build the module using ModuleBuilder with metadata
        var moduleAST = reflaxe.elixir.ast.builders.ModuleBuilder.buildClassModule(classType, fields, metadata);

        // Additional metadata settings if needed
        if (moduleAST != null && moduleAST.metadata == null) {
            moduleAST.metadata = metadata;
        }
        
        // ExUnit debug output
        if (moduleAST != null && moduleAST.metadata != null && moduleAST.metadata.isExunit == true) {
            #if debug_exunit
            // DISABLED: trace('[ElixirCompiler] Set isExunit=true metadata for ${classType.name}');
            #end
        }

        // Application debug output
        if (moduleAST != null && moduleAST.metadata != null && moduleAST.metadata.isApplication == true) {
            #if debug_annotation_transforms
            // DISABLED: trace('[ElixirCompiler] Module ${classType.name} has isApplication metadata after building');
            #end
        }

        #if debug_module_builder
        if (classType.name == "Main") {
            // DISABLED: trace('[ElixirCompiler] Received module AST for Main from ModuleBuilder');
            // trace('[ElixirCompiler] Main module metadata: ${moduleAST.metadata}');
            // if (moduleAST != null && moduleAST.metadata != null) {
            //     trace('[ElixirCompiler] Main module metadata.isExunit: ${moduleAST.metadata.isExunit}');
            // }
        }
        #end

        // PASS 3: Generate companion modules if needed (e.g., PostgrexTypes for Repo)
        if (moduleAST != null && moduleAST.metadata != null) {
            generateCompanionModules(classType, moduleAST.metadata);
        }
        
        // Restore previous behavior transformer state
        if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
            reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.activeBehavior = previousBehavior;
            #if debug_behavior_transformer
            if (previousBehavior != null) {
                // DISABLED: trace('[BehaviorTransformer] Restored previous behavior: ${previousBehavior}');
            } else {
                // DISABLED: trace('[BehaviorTransformer] Deactivated behavior after building ${classType.name}');
            }
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
    static function schemaTypeNameFromType(t: Type): String {
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
    function generateCompanionModules(classType: ClassType, metadata: ElixirMetadata): Void {
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
    function generatePostgrexTypesModule(classType: ClassType, metadata: ElixirMetadata): Void {
        // Get the base module name (e.g., "TodoApp.Repo" -> "TodoApp")
        var moduleName = reflaxe.elixir.ast.builders.ModuleBuilder.extractModuleName(classType);
        
        // Extract the base app name (before .Repo)
        var appName = moduleName.split(".")[0];
        
        // Create the PostgrexTypes module name
        var typesModuleName = appName + ".PostgrexTypes";
        
        #if debug_repo
        // DISABLED: trace('[ElixirCompiler] Generating PostgrexTypes companion module: ${typesModuleName}');
        // DISABLED: trace('[ElixirCompiler] JSON module: ${metadata.jsonModule}, Extensions: ${metadata.extensions}');
        #end
        
        // Build the module body
        var statements = [];
        
        // Build extensions array - empty by default
        var extensionsAST = reflaxe.elixir.ast.ElixirAST.makeAST(
            reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EList([])
        );
        if (metadata.extensions != null && metadata.extensions.length > 0) {
            var extElements = metadata.extensions.map(ext -> 
                reflaxe.elixir.ast.ElixirAST.makeAST(
                    reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EAtom(ext)
                )
            );
            extensionsAST = reflaxe.elixir.ast.ElixirAST.makeAST(
                reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EList(extElements)
            );
        }
        
        // Build keyword list for options (json: Jason)
        var options = [];
        if (metadata.jsonModule != null) {
            // Create a keyword list element for json: Jason
            var jsonAtom = reflaxe.elixir.ast.ElixirAST.makeAST(
                reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EAtom(ElixirAtom.raw("json"))
            );
            var jsonModule = reflaxe.elixir.ast.ElixirAST.makeAST(
                reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar(metadata.jsonModule)
            );
            var keywordElement = reflaxe.elixir.ast.ElixirAST.makeAST(
                reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ETuple([jsonAtom, jsonModule])
            );
            options.push(keywordElement);
        }
        
        // Build the Postgrex.Types.define call
        var moduleRef = reflaxe.elixir.ast.ElixirAST.makeAST(
            reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar(typesModuleName)
        );
        var args = [
            moduleRef,          // Module reference
            extensionsAST,      // Extensions array
            reflaxe.elixir.ast.ElixirAST.makeAST(
                reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EList(options)
            )  // Options keyword list
        ];
        
        var defineCall = reflaxe.elixir.ast.ElixirAST.makeAST(
            reflaxe.elixir.ast.ElixirAST.ElixirASTDef.ERemoteCall(
                reflaxe.elixir.ast.ElixirAST.makeAST(
                    reflaxe.elixir.ast.ElixirAST.ElixirASTDef.EVar("Postgrex.Types")
                ),
                "define",
                args
            )
        );
        
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
        // DISABLED: trace('[ElixirCompiler] Writing PostgrexTypes module to: ${outputPath}');
        #end
        
        // Use setExtraFile to generate the companion module
        setExtraFile(outputPath, moduleString);
    }
    
    /**
     * Check if this is a built-in abstract type that should NOT generate an Elixir module
     */
    private function isBuiltinAbstractType(name: String): Bool {
        // Built-in abstracts that shouldn't generate modules
        return switch(name) {
            case "Int" | "Float" | "Bool" | "String" | "Void" | "Dynamic": true;
            case "__Int64" | "Int64": true; // Haxe Int64 types
            case _: false;
        }
    }
    
    /**
     * Check if this is a standard library class type that should NOT generate an Elixir module
     */
    private function isStandardLibraryClass(name: String): Bool {
        // Standard library classes handled elsewhere
        return switch(name) {
            case "String" | "Array" | "Map" | "Date" | "Math" | "List": true;
            case "__Int64" | "Int64" | "Int64_Impl_": true; // Haxe Int64 internal types
            case _: false;
        }
    }
    
    /**
     * Build enum AST - creates module with constructor functions
     */
    function buildEnumAST(enumType: EnumType, options: Array<EnumOptionData>): Null<reflaxe.elixir.ast.ElixirAST> {
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
                switch(nativeMeta[0].params[0].expr) {
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
                if (index == null) index = 0; // Fallback, should not happen
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
    private function shouldSuppressEnumEmission(enumType: EnumType): Bool {
        if (enumType == null) return false;
        var n = enumType.name;
        if (n == null) return false;

        // Common Haxe std enums not needed as modules in Elixir
        if (n == "ValueType" || n == "StackItem") return true;

        if (enumType.pack != null && enumType.pack.length > 0) {
            var top = enumType.pack[0];
            if (top == "haxe") return true;
            if (StringTools.startsWith(top, "_")) return true;
        }

        return false;
    }
    
    /**
     * Build the full module name for an enum including package
     * Ensures proper capitalization for Elixir module names
     */
    function buildEnumModuleName(enumType: EnumType): String {
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
    
    public function generateFunctionReference(functionName: String): String {
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
    public function getCurrentModuleName(): String {
        if (currentClassType != null) {
            // Use the current class name as the module name
            return currentClassType.name;
        }
        return "UnknownModule";
    }
    
    /**
     * Get module name for a specific ClassType
     */
    public function getModuleName(classType: ClassType): String {
        return classType.name;
    }
    
    /**
     * Check if a TypedExpr is being immediately called (part of a TCall expression)
     * This is used to determine if a field access should be compiled as a function reference
     * 
     * @param expr The expression to check
     * @return True if the expression is the function part of a TCall, false otherwise
     */
    private function isBeingCalled(expr: TypedExpr): Bool {
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
    private function getFunctionArity(functionName: String): Int {
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
    public function setCaseArmContext(inCaseArm: Bool): Void {
        isCompilingCaseArm = inCaseArm;
    }
    
    /**
     * Clear parameter mapping after function compilation
     */
    public function clearFunctionParameterMapping(): Void {
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
    private function getLambdaParameterFromBody(expr: TypedExpr): Null<TVar> {
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
                    if (result != null) return result;
                }
            case TBinop(_, e1, e2):
                // Check both operands
                var result = getLambdaParameterFromBody(e1);
                if (result != null) return result;
                return getLambdaParameterFromBody(e2);
            case TCall(e, args):
                // Check function and arguments
                var result = getLambdaParameterFromBody(e);
                if (result != null) return result;
                for (arg in args) {
                    result = getLambdaParameterFromBody(arg);
                    if (result != null) return result;
                }
            case TIf(econd, eif, eelse):
                // Check condition and branches
                var result = getLambdaParameterFromBody(econd);
                if (result != null) return result;
                result = getLambdaParameterFromBody(eif);
                if (result != null) return result;
                if (eelse != null) {
                    result = getLambdaParameterFromBody(eelse);
                    if (result != null) return result;
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
    public function shouldSubstituteVariable(varName: String, sourceVar: String = null, isAggressiveMode: Bool = false): Bool {
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
    public function getFieldName(fa: FieldAccess): String {
        #if debug_method_name_resolution
        // trace('[XRay getFieldName] Processing FieldAccess: ${fa}');
        #end
        
        // Use Reflaxe's standardized helper instead of manual extraction
        var nameMeta = NameMetaHelper.getFieldAccessNameMeta(fa);
        var name = nameMeta.getNameOrNative();
        
        #if debug_method_name_resolution
        // trace('[XRay getFieldName] Field name: ${nameMeta.name}, has @:native: ${nameMeta.hasMeta(":native")}, resolved: ${name}');
        #end
        
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
    private function isValidAtomName(name: String): Bool {
        if (name == null || name.length == 0) return false;
        
        // Check first character: must be lowercase letter or underscore
        var firstChar = name.charAt(0);
        if (!((firstChar >= 'a' && firstChar <= 'z') || firstChar == '_')) {
            return false;
        }
        
        // Check remaining characters: alphanumeric or underscore
        for (i in 1...name.length) {
            var char = name.charAt(i);
            if (!((char >= 'a' && char <= 'z') || 
                  (char >= 'A' && char <= 'Z') || 
                  (char >= '0' && char <= '9') || 
                  char == '_')) {
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
    private function extractStringArrayFromExpr(expr: Expr): Array<String> {
        if (expr == null) return [];

        switch(expr.expr) {
            case EArrayDecl(values):
                var result = [];
                for (value in values) {
                    switch(value.expr) {
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

    /**
     * Extract router route definitions from @:routes metadata for @:router modules.
     */
    private function extractRouterRoutesFromMeta(classType: ClassType): Null<Array<RouterRouteMeta>> {
        var routesMeta = classType.meta.extract(":routes");
        var routesMetaAlt = classType.meta.extract("routes");
        if (routesMetaAlt != null && routesMetaAlt.length > 0) {
            routesMeta = routesMeta != null && routesMeta.length > 0 ? routesMeta.concat(routesMetaAlt) : routesMetaAlt;
        }

        if (routesMeta == null || routesMeta.length == 0) {
            return null;
        }

        var entry = routesMeta[0];
        if (entry.params == null || entry.params.length == 0) {
            Context.error("@:routes annotation requires an array parameter: @:routes([{...}])", entry.pos);
            return null;
        }

        function extractStringValue(expr: Expr, fieldName: String, pos: haxe.macro.Expr.Position): Null<String> {
            return switch (expr.expr) {
                case EConst(CString(s, _)): s;
                case EConst(CIdent(ident)): ident;
                case EField(_, field): field; // Enum values / type references (e.g., HttpMethod.GET)
                default:
                    Context.error('${fieldName} must be a string literal or enum value', pos);
                    null;
            };
        }

        function parseRoute(routeExpr: Expr): Null<RouterRouteMeta> {
            return switch (routeExpr.expr) {
                case EObjectDecl(fields):
                    var name: Null<String> = null;
                    var method: Null<String> = null;
                    var path: Null<String> = null;
                    var controller: Null<String> = null;
                    var action: Null<String> = null;
                    var pipeline: Null<String> = null;

                    for (f in fields) {
                        switch (f.field) {
                            case "name":
                                name = extractStringValue(f.expr, "name", f.expr.pos);
                            case "method":
                                method = extractStringValue(f.expr, "method", f.expr.pos);
                            case "path":
                                path = extractStringValue(f.expr, "path", f.expr.pos);
                            case "controller":
                                controller = extractStringValue(f.expr, "controller", f.expr.pos);
                            case "action":
                                action = extractStringValue(f.expr, "action", f.expr.pos);
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
                    // LIVE_DASHBOARD is special: controller/action are optional.
                    var methodUpper = method.toUpperCase();
                    if (methodUpper != "LIVE_DASHBOARD") {
                        if (controller == null) Context.error('Route "${name}" is missing controller', routeExpr.pos);
                        if (action == null) Context.error('Route "${name}" is missing action', routeExpr.pos);
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
                    Context.error("Each route in @:routes must be an object: {name: ..., method: ..., path: ...}", routeExpr.pos);
                    null;
            }
        }

        var routesExpr = entry.params[0];
        return switch (routesExpr.expr) {
            case EArrayDecl(values):
                var routes: Array<RouterRouteMeta> = [];
                for (r in values) {
                    var parsed = parseRoute(r);
                    if (parsed != null) routes.push(parsed);
                }
                routes.length > 0 ? routes : null;
            default:
                Context.error("@:routes parameter must be an array: @:routes([{...}])", routesExpr.pos);
                null;
        };
    }

    /**
     * Determine if an object should use atom keys based on field patterns
     * Takes a conservative approach - defaults to string keys unless we're certain
     * Only uses atoms for very specific OTP patterns to avoid breaking user code
     */
    private function shouldUseAtomKeys(fields: Array<{name: String, expr: TypedExpr}>): Bool {
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
    private function isChildSpecObject(fields: Array<{name: String, expr: TypedExpr}>): Bool {
        if (fields == null || fields.length == 0) return false;
        
        var fieldNames = fields.map(f -> f.name);
        return fieldNames.indexOf("id") != -1 && fieldNames.indexOf("start") != -1;
    }
    
    /**
     * Child spec format types for structure-based detection
     */
    private static inline var MODERN_TUPLE = "ModernTuple";    // {Module, args} - for modules with child_spec/1
    private static inline var SIMPLE_MODULE = "SimpleModule";   // ModuleName - simple module reference
    private static inline var TRADITIONAL_MAP = "TraditionalMap"; // %{id: ..., start: ...} - explicit map format
    
    
    
    /**
     * Generate modern tuple format for child specs
     * Examples: {Phoenix.PubSub, name: MyApp.PubSub}, MyApp.Repo
     */
    private function generateModernTupleFormat(idField: String, startField: String, appName: String): String {
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
    private function generateSimpleModuleFormat(idField: String, appName: String): String {
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
    private function isSupervisorOptionsObject(fields: Array<{name: String, expr: TypedExpr}>): Bool {
        if (fields == null || fields.length == 0) return false;
        
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
    private function isFieldAssignment(expr: TypedExpr): Bool {
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
    private function isNilExpression(expr: TypedExpr): Bool {
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
    private function detectYCombinatorInAST(expr: TypedExpr): Bool {
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
    private function containsHSigil(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch(expr.expr) {
            case TCall(e, _):
                // Check if this is an HXX.hxx call (compiles to ~H sigil)
                switch(e.expr) {
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
                    if (containsHSigil(e)) return true;
                }
                
            case TReturn(e):
                return containsHSigil(e);
                
            case TIf(econd, eif, eelse):
                return containsHSigil(econd) || containsHSigil(eif) || (eelse != null && containsHSigil(eelse));
                
            case TSwitch(e, cases, edef):
                if (containsHSigil(e)) return true;
                for (c in cases) {
                    if (containsHSigil(c.expr)) return true;
                }
                if (edef != null && containsHSigil(edef)) return true;
                
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
        if (!sourceMapOutputEnabled) return;

        // Generate all pending source maps after output files are written.
        for (writer in pendingSourceMapWriters) {
            if (writer != null) writer.generateSourceMap();
        }
        pendingSourceMapWriters = [];
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
    public function typeToString(type: Type): String {
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
