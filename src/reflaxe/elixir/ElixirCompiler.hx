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
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.CompilationContext;

using StringTools;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.TypeHelper;

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
        this.sourceMapOutputEnabled = Context.defined("source_map_enabled") || Context.defined("source-map") || Context.defined("debug");

        // Initialize the BehaviorTransformer system
        // This replaces hardcoded behavior logic with a pluggable architecture
        reflaxe.elixir.behaviors.BehaviorTransformer.initialize();
        reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer = new reflaxe.elixir.behaviors.BehaviorTransformer();
        
        // Preprocessors are now configured in CompilerInit.hx to ensure they aren't overridden
        // The configuration was moved because options passed to ReflectCompiler.AddCompiler
        // override anything set in the constructor
    }
    
    /**
     * Override shouldGenerateClass to allow extern classes with special annotations
     * 
     * WHY: By default, GenericCompiler ignores all extern classes, but we need to
     * generate modules for extern classes with framework annotations like @:repo
     * 
     * @param classType The class to check
     * @return True if the class should be compiled
     */
    public override function shouldGenerateClass(classType: ClassType): Bool {
        // Debug for TodoApp investigation
        #if debug_annotation_transforms
        if (classType.name == "TodoApp") {
            trace('[shouldGenerateClass] Checking TodoApp...');
            trace('[shouldGenerateClass]   isExtern: ${classType.isExtern}');
            trace('[shouldGenerateClass]   has @:application: ${classType.meta.has(":application")}');
            trace('[shouldGenerateClass]   has @:native: ${classType.meta.has(":native")}');
            var result = super.shouldGenerateClass(classType);
            trace('[shouldGenerateClass]   super.shouldGenerateClass returns: ${result}');
        }
        #end
        
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
            trace('[shouldGenerateClass] Forcing compilation of @:presence class: ${classType.name} (isExtern: ${classType.isExtern})');
            #end
            return true;
        }
        
        // Check if this is a @:coreApi class (like Date, Sys, etc.)
        // These need to be generated as Elixir modules
        if (classType.meta.has(":coreApi")) {
            return true;
        }
        
        // Check if this is an @:application class
        // These need to be compiled to generate OTP application modules
        if (classType.meta.has(":application")) {
            #if debug_annotation_transforms
            trace('[shouldGenerateClass] Forcing compilation of @:application class: ${classType.name}');
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
     * Required implementation for GenericCompiler - implements class compilation
     * @param classType The Haxe class type
     * @param varFields Class variables
     * @param funcFields Class functions
     * @return ElixirAST representing the compiled module
     */
    public function compileClassImpl(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<reflaxe.elixir.ast.ElixirAST> {
        #if debug_compilation_flow
        trace('[ElixirCompiler.compileClassImpl] START compiling class: ${classType.name}');
        trace('[ElixirCompiler.compileClassImpl] varFields: ${varFields.length}, funcFields: ${funcFields.length}');
        #end

        if (classType == null) return null;

        // Debug output for TodoApp investigation
        #if debug_annotation_transforms
        if (classType.name == "TodoApp") {
            trace('[ElixirCompiler.compileClassImpl] === TodoApp Debug Info ===');
            trace('[ElixirCompiler.compileClassImpl] funcFields received: ${funcFields.length}');
            for (f in funcFields) {
                trace('[ElixirCompiler.compileClassImpl]   - Function: ${f.field.name}');
            }
            trace('[ElixirCompiler.compileClassImpl] isExtern: ${classType.isExtern}');
            trace('[ElixirCompiler.compileClassImpl] metadata: [${[for (m in classType.meta.get()) m.name].join(", ")}]');
            
            // Check if GenericCompiler considers this class extern
            trace('[ElixirCompiler.compileClassImpl] classType.fields.get().length: ${classType.fields.get().length}');
            trace('[ElixirCompiler.compileClassImpl] classType.statics.get().length: ${classType.statics.get().length}');
            for (field in classType.statics.get()) {
                trace('[ElixirCompiler.compileClassImpl]   Static field: ${field.name}, kind: ${field.kind}');
            }
        }
        #end

        // Skip standard library classes that shouldn't generate Elixir modules
        if (isStandardLibraryClass(classType.name)) {
            #if debug_compilation_flow
            trace('[ElixirCompiler.compileClassImpl] Skipping standard library class: ${classType.name}');
            #end
            return null;
        }

        // Initialize function usage collector for this module
        var functionUsageCollector = new reflaxe.elixir.helpers.FunctionUsageCollector();
        functionUsageCollector.currentModule = classType.name;

        // Check for @:native annotation to determine output path
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
        
        // Set current module for dependency tracking using the final module name
        currentCompiledModule = moduleName;
        // Initialize dependency map for this module if not exists
        if (!moduleDependencies.exists(moduleName)) {
            moduleDependencies.set(moduleName, new Map<String, Bool>());
        }
        
        // Set output file path with snake_case naming
        setUniversalOutputPath(moduleName, modulePack);
        
        // Track the output path for this module
        var outputPath = getModuleOutputPath(moduleName, modulePack);
        moduleOutputPaths.set(moduleName, outputPath);
        // Track BaseType for synthetic outputs
        moduleBaseTypes.set(moduleName, classType);
        
        // Store current class context for use in expression compilation
        this.currentClassType = classType;
        
        // Activate behavior transformer based on class metadata
        // This replaces the old isInPresenceModule flag with a more generic system
        #if debug_behavior_transformer
        trace('[ElixirCompiler] Compiling class: ${classType.name}');
        #end
        
        if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
            var behaviorName = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.checkAndActivateBehavior(classType);
            #if debug_behavior_transformer
            if (behaviorName != null) {
                trace('[BehaviorTransformer] Activated behavior "${behaviorName}" for class ${classType.name}');
            } else {
                trace('[BehaviorTransformer] No behavior found for class ${classType.name}');
            }
            #end
        }
        
        // Use AST pipeline for class compilation
        var moduleAST = buildClassAST(classType, varFields, funcFields);

        // Add function usage information to module metadata
        if (functionUsageCollector != null && moduleAST != null) {
            if (moduleAST.metadata == null) {
                moduleAST.metadata = {};
            }
            // Store the list of unused functions in metadata
            moduleAST.metadata.unusedPrivateFunctions = functionUsageCollector.getUnusedPrivateFunctions();
            moduleAST.metadata.unusedPrivateFunctionsWithArity = functionUsageCollector.getUnusedPrivateFunctionsWithArity();

            #if debug_function_usage
            functionUsageCollector.printStats();
            #end
        }

        #if debug_compilation_flow
        trace('[ElixirCompiler.compileClassImpl] END compiling class: ${classType.name}');
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
                    final result = TargetCodeInjection.checkTargetCodeInjectionGeneric(
                        options.targetCodeInjectionName,
                        expr,
                        this
                    );
                    
                    if (result != null) {
                        // Process the injection result
                        var finalCode = "";
                        for (entry in result) {
                            switch(entry) {
                                case Left(code):
                                    // Direct string code
                                    finalCode += code;
                                case Right(ast):
                                    // Compiled AST - convert to string
                                    finalCode += reflaxe.elixir.ast.ElixirASTPrinter.printAST(ast);
                            }
                        }
                        
                        // Return as raw Elixir code
                        return reflaxe.elixir.ast.ElixirAST.makeAST(
                            reflaxe.elixir.ast.ElixirASTDef.ERaw(finalCode)
                        );
                    }
                }
            case _:
        }
        
        // Not an injection, use normal compilation
        return super.compileExpression(expr, topLevel);
    }
    
    /**
     * Creates a properly initialized CompilationContext
     *
     * WHY: Centralizes context creation to ensure all contexts have proper initialization
     * including the new AST modularization infrastructure (Phase 2)
     *
     * WHAT: Creates context with BuilderFacade and all necessary references
     *
     * HOW: Initializes context, sets up BuilderFacade if enabled, registers builders
     */
    private function createCompilationContext(): CompilationContext {
        var context = new CompilationContext();
        context.compiler = this;

        // Check if we're compiling within an ExUnit test class
        // This enables proper handling of instance variables in test methods
        if (currentClassType != null && currentClassType.meta.has(":exunit")) {
            context.isInExUnitTest = true;
            #if debug_exunit
            trace('[ElixirCompiler] Setting isInExUnitTest=true for context (class: ${currentClassType.name})');
            #end
        }

        // Initialize behavior transformer
        if (context.behaviorTransformer == null) {
            context.behaviorTransformer = new reflaxe.elixir.behaviors.BehaviorTransformer();
        }

        // Initialize feature flags from compiler defines
        initializeFeatureFlags(context);

        // Phase 2: Initialize BuilderFacade for gradual migration
        // Only create if we're using any new builders
        if (context.isFeatureEnabled("use_new_pattern_builder") ||
            context.isFeatureEnabled("use_new_loop_builder") ||
            context.isFeatureEnabled("use_new_function_builder") ||
            context.isFeatureEnabled("use_new_comprehension_builder")) {

            context.builderFacade = new reflaxe.elixir.ast.builders.BuilderFacade(this, context);

            // Register specialized builders as they become available
            // TODO: Restore when PatternMatchBuilder import is fixed
            // var patternBuilder = new reflaxe.elixir.ast.builders.PatternMatchBuilder(
            //     context,
            //     context.getExpressionBuilder()
            // );
            // context.builderFacade.registerBuilder("pattern", patternBuilder);

            #if debug_ast_builder
            trace('[ElixirCompiler] BuilderFacade initialized with registered builders');
            #end
        }

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

        // Check for the new builder flags that are already being used
        if (haxe.macro.Context.defined("elixir.feature.use_new_pattern_builder")) {
            var value = haxe.macro.Context.definedValue("elixir.feature.use_new_pattern_builder");
            context.setFeatureFlag("use_new_pattern_builder", value != "false");
        }

        if (haxe.macro.Context.defined("elixir.feature.use_new_loop_builder")) {
            var value = haxe.macro.Context.definedValue("elixir.feature.use_new_loop_builder");
            context.setFeatureFlag("use_new_loop_builder", value != "false");
        }

        // Global flag to enable all experimental features
        if (haxe.macro.Context.defined("elixir.feature.experimental")) {
            var value = haxe.macro.Context.definedValue("elixir.feature.experimental");
            if (value != "false") {
                context.setFeatureFlag("new_module_builder", true);
                context.setFeatureFlag("loop_builder_enabled", true);
                context.setFeatureFlag("idiomatic_comprehensions", true);
                context.setFeatureFlag("pattern_extraction", true);
                context.setFeatureFlag("use_new_pattern_builder", true);
                context.setFeatureFlag("use_new_loop_builder", true);
            }
        }

        // Legacy compatibility mode - defaults to old behavior
        if (haxe.macro.Context.defined("elixir.feature.legacy")) {
            var value = haxe.macro.Context.definedValue("elixir.feature.legacy");
            if (value != "false") {
                // Explicitly disable all new features
                context.setFeatureFlag("new_module_builder", false);
                context.setFeatureFlag("loop_builder_enabled", false);
                context.setFeatureFlag("idiomatic_comprehensions", false);
                context.setFeatureFlag("pattern_extraction", false);
                context.setFeatureFlag("use_new_pattern_builder", false);
                context.setFeatureFlag("use_new_loop_builder", false);
            }
        }

        // Debug flag to print enabled features
        #if debug_feature_flags
        trace("Feature flags initialized:");
        for (key in context.astContext.featureFlags.keys()) {
            trace('  $key: ${context.astContext.featureFlags.get(key)}');
        }
        #end
    }

    /**
     * Implement the required abstract method for expression compilation
     *
     * WHY: Reflaxe's GenericCompiler calls this to compile individual expressions.
     * This is the correct integration point for our AST pipeline.
     *
     * WHAT: Builds AST for individual expressions
     *
     * HOW: Delegates to ElixirASTBuilder for AST generation
     */
    public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<reflaxe.elixir.ast.ElixirAST> {
        // Create a fresh compilation context for this expression
        // This ensures complete isolation between compilation units during parallel execution
        var context = createCompilationContext();

        // CRITICAL: Preprocess TypedExpr to eliminate infrastructure variables FIRST
        // This must happen BEFORE any other processing to ensure clean patterns
        expr = reflaxe.elixir.preprocessor.TypedExprPreprocessor.preprocess(expr);

        // Analyze variable usage before building AST
        // This enables context-aware naming to prevent Elixir compilation warnings
        var usageMap = reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(expr);
        context.variableUsageMap = usageMap;

        // Collect function calls if we have a collector active
        // TODO: Restore when FunctionUsageCollector is implemented
        // if (functionUsageCollector != null) {
        //     functionUsageCollector.collectCalls(expr);
        // }

        // Build AST for the expression with compilation context
        // Pass context as second parameter to ensure isolated state
        var ast = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);

        trace('[AST Pipeline] After Builder - AST type: ${ast != null ? Type.enumConstructor(ast.def) : "null"}');

        // Apply transformations to all expressions, not just function bodies
        // Pass context to transformer as well
        if (ast != null) {
            var originalAstId = Std.string(ast);
            var transformedAst = reflaxe.elixir.ast.ElixirASTTransformer.transform(ast, context);
            var transformedAstId = Std.string(transformedAst);

            trace('[AST Pipeline] After Transformer - Same object: ${originalAstId == transformedAstId}');
            trace('[AST Pipeline]   Original AST ID: $originalAstId');
            trace('[AST Pipeline]   Transformed AST ID: $transformedAstId');

            ast = transformedAst;
        }

        trace('[AST Pipeline] Returning AST to caller');
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
                trace('[ElixirCompiler] Breaking circular dependency, remaining: ' + [for (k in remaining.keys()) k].join(', '));
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
        trace('[ElixirCompiler.discoverDependencies] START for class: ${classType.name} with ${funcFields.length} functions');
        #end

        // Activate behavior transformer for dependency discovery
        // This replaces the old isInPresenceModule flag with a generic system
        var previousBehavior: Null<String> = null;
        if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
            previousBehavior = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.activeBehavior;
            var behaviorName = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.checkAndActivateBehavior(classType);
            #if debug_behavior_transformer
            if (behaviorName != null) {
                trace('[BehaviorTransformer] Activated behavior "${behaviorName}" for dependency discovery of ${classType.name}');
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

                            // Analyze variable usage for the function
                            var usageMap = reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                            context.variableUsageMap = usageMap;

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
            trace('[ElixirCompiler] After dependency discovery for ${currentCompiledModule}: ${[for (k in deps.keys()) k].join(", ")}');
        }
        #end
        
        // Restore previous behavior state
        if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
            reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.activeBehavior = previousBehavior;
        }

        #if debug_compilation_flow
        trace('[ElixirCompiler.discoverDependencies] END for class: ${classType.name}');
        #end
    }
    
    /**
     * Build AST for a class (generates Elixir module)
     */
    function buildClassAST(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<reflaxe.elixir.ast.ElixirAST> {

        #if debug_behavior_transformer
        trace('[ElixirCompiler.buildClassAST] Building class: ${classType.name}');
        trace('[ElixirCompiler.buildClassAST] Metadata: ${[for (m in classType.meta.get()) m.name]}');
        #end

        #if debug_annotation_transforms
        if (classType.name == "TodoApp") {
            trace('[ElixirCompiler.buildClassAST] TodoApp received ${funcFields.length} functions');
            for (f in funcFields) {
                trace('[ElixirCompiler.buildClassAST] Function: ${f.field.name}');
            }
        }
        #end

        // Skip built-in types that shouldn't generate modules
        if (isBuiltinAbstractType(classType.name) || isStandardLibraryClass(classType.name)) {
            return null;
        }
        
        // Activate behavior transformer if this class has a behavior annotation
        // This ensures that when the class's methods are compiled, the behavior transformer
        // is active and can inject self() or other behavior-specific transformations
        var previousBehavior: Null<String> = null;
        if (reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer != null) {
            previousBehavior = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.activeBehavior;
            var behaviorName = reflaxe.elixir.ast.ElixirASTBuilder.behaviorTransformer.checkAndActivateBehavior(classType);
            #if debug_behavior_transformer
            if (behaviorName != null) {
                trace('[BehaviorTransformer] Activated behavior "${behaviorName}" for building ${classType.name} module');
            } else {
                trace('[BehaviorTransformer] No behavior found for ${classType.name}');
            }
            #end
        }
        
        // ALWAYS use ModuleBuilder for ALL classes to eliminate duplication
        // All classes go through ModuleBuilder now for consistency

        #if debug_module_builder
        trace('[ElixirCompiler] Using provided funcFields parameter: ${funcFields.length} functions');
        trace('[ElixirCompiler] Using provided varFields parameter: ${varFields.length} variables');
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

        // Build fields from the funcFields parameter (which is already ClassFuncData array)
        var fields: Array<reflaxe.elixir.ast.ElixirAST> = [];

        // Compile each function field
        for (funcData in funcFields) {
            // Skip constructor for now
            if (funcData.field.name == "new") continue;

            // Get the function expression and preprocess it
            var expr = funcData.expr;
            // Skip functions without body - they might be extern or abstract
            if (expr == null) continue;
            
            // Preprocess the function body to eliminate infrastructure variables
            expr = reflaxe.elixir.preprocessor.TypedExprPreprocessor.preprocess(expr);

            #if debug_ast_builder
            trace('[ElixirCompiler] Compiling function: ${funcData.field.name}');
            if (expr != null) {
                trace('[ElixirCompiler]   Body type: ${Type.enumConstructor(expr.expr)}');
                switch(expr.expr) {
                    case TReturn(e) if (e != null):
                        trace('[ElixirCompiler]   TReturn contains: ${Type.enumConstructor(e.expr)}');
                        switch(e.expr) {
                            case TSwitch(_, cases, _):
                                trace('[ElixirCompiler]     Direct return of TSwitch with ${cases.length} cases');
                            case TLocal(v):
                                trace('[ElixirCompiler]     Return of TLocal: ${v.name}');
                            default:
                                trace('[ElixirCompiler]     Return of: ${Type.enumConstructor(e.expr)}');
                        }
                    case TBlock(exprs):
                        trace('[ElixirCompiler]   TBlock with ${exprs.length} expressions');
                        if (exprs.length > 0) {
                            var last = exprs[exprs.length - 1];
                            trace('[ElixirCompiler]     Last expr: ${Type.enumConstructor(last.expr)}');
                        }
                    default:
                        trace('[ElixirCompiler]   Other: ${Type.enumConstructor(expr.expr)}');
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
            trace('[ElixirCompiler] Checking ${funcData.field.name}: has("test")=${funcData.field.meta.has("test")}, isExUnitTestMethod=$isExUnitTestMethod');
            // Let's see what metadata IS present
            if (funcData.field.name.indexOf("test") == 0) {
                var metaList = [];
                for (m in funcData.field.meta.get()) {
                    metaList.push(m.name);
                }
                trace('[ElixirCompiler]   Metadata present on ${funcData.field.name}: [${metaList.join(", ")}]');
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
                trace('[ElixirCompiler] Set isInExUnitTest=true for function ${funcData.field.name}');
                trace('[ElixirCompiler] Context check immediately after setting: isInExUnitTest=${context.isInExUnitTest}');
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
            if (funcData.tfunc != null) {
                for (arg in funcData.tfunc.args) {
                    var originalName = arg.v.name;
                    var idKey = Std.string(arg.v.id);

                    // Check if parameter has numeric suffix that indicates shadowing
                    var strippedName = originalName;
                    var renamedPattern = ~/^(.+?)(\d+)$/;
                    if (renamedPattern.match(originalName)) {
                        var baseWithoutSuffix = renamedPattern.matched(1);
                        var suffix = renamedPattern.matched(2);

                        // Only strip suffix for common field names
                        var commonFieldNames = ["options", "columns", "name", "value", "type", "data", "fields", "items"];
                        if ((suffix == "2" || suffix == "3") && commonFieldNames.indexOf(baseWithoutSuffix) >= 0) {
                            strippedName = baseWithoutSuffix;

                            #if debug_variable_renaming
                            trace('[ElixirCompiler] Registering renamed parameter mapping: $originalName (id: ${arg.v.id}) -> $strippedName');
                            #end
                        }
                    }

                    // Check if this parameter is unused in the function body
                    var isUnused = if (arg.v.meta != null && arg.v.meta.has("-reflaxe.unused")) {
                        true;
                    } else if (funcData.expr != null) {
                        // Use UsageDetector to check if parameter is actually used
                        !reflaxe.elixir.helpers.UsageDetector.isParameterUsed(arg.v, funcData.expr);
                    } else {
                        false;
                    };
                    
                    // Register the mapping for use in function body
                    // Use toSafeElixirParameterName to handle reserved keywords
                    var baseName = reflaxe.elixir.ast.NameUtils.toSafeElixirParameterName(strippedName);
                    // Add underscore prefix for unused parameters
                    var finalName = if (isUnused && !baseName.startsWith("_")) {
                        "_" + baseName;
                    } else {
                        baseName;
                    };
                    if (!context.tempVarRenameMap.exists(idKey)) {
                        context.tempVarRenameMap.set(idKey, finalName);
                    }
                }
            }

            // Build the function body with proper context
            // Special handling for direct switch returns that may have lost context
            #if debug_switch_return
            trace("[SwitchReturnDebug] Building function body for: " + funcData.field.name);
            if (expr != null) {
                trace("[SwitchReturnDebug] expr.expr type: " + Type.enumConstructor(expr.expr));
            } else {
                trace("[SwitchReturnDebug] expr is null (no body)");
            }
            #end

            #if debug_exunit
            trace('[ElixirCompiler] About to build funcBody for ${funcData.field.name}, context.isInExUnitTest=${context.isInExUnitTest}');
            #end
            
            var funcBody = switch(expr.expr) {
                case TReturn(e) if (e != null):
                    #if debug_switch_return
                    trace("[SwitchReturnDebug] Found TReturn with non-null expression");
                    trace("[SwitchReturnDebug] Return expr type: " + (e != null ? Type.enumConstructor(e.expr) : "null"));
                    #end

                    // Check if it's a return of a switch (potentially wrapped in metadata)
                    var innerExpr = e;
                    switch(e.expr) {
                        case TMeta(_, inner):
                            #if debug_switch_return
                            trace("[SwitchReturnDebug] Found TMeta wrapper, unwrapping");
                            #end
                            innerExpr = inner;
                        case _:
                    }

                    #if debug_switch_return
                    trace("[SwitchReturnDebug] Inner expr type: " + Type.enumConstructor(innerExpr.expr));
                    #end

                    switch(innerExpr.expr) {
                        case TSwitch(_, _, _):
                            #if debug_switch_return
                            trace("[SwitchReturnDebug] *** Direct switch return detected! Building switch AST directly ***");
                            #end
                            // For direct switch returns, build the switch expression and wrap in parentheses
                            // This ensures the full case structure is preserved
                            var switchAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e, context);

                            #if debug_switch_return
                            trace("[SwitchReturnDebug] Built switch AST def: " + switchAST.def);
                            #end

                            // The switch itself is the body - no need for additional wrapping
                            switchAST;
                        case _:
                            #if debug_switch_return
                            trace("[SwitchReturnDebug] Not a switch, building normal return");
                            #end
                            // Normal return handling
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);
                    }
                case _:
                    #if debug_switch_return
                    trace("[SwitchReturnDebug] Not a direct return, building normally");
                    #end
                    // Normal expression handling
                    reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);
            };

            #if debug_ast_builder
            trace('[ElixirCompiler] Function ${funcData.field.name} body AST: ${funcBody.def}');
            #end

            // Get function parameters from tfunc
            var params: Array<EPattern> = [];

            // For instance methods, add struct as first parameter
            // BUT NOT for ExUnit test methods - they don't get struct parameters
            if (!isStaticMethod && !isExUnitTestMethod) {
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
            var funcDef = funcData.field.isPublic ?
                EDef(elixirName, params, null, funcBody) :
                EDefp(elixirName, params, null, funcBody);

            // Check for test-related metadata on the function field
            var funcMetadata: reflaxe.elixir.ast.ElixirAST.ElixirMetadata = {};

            // Set ExUnit-related metadata flags directly
            funcMetadata.isTest = funcData.field.meta.has(":test");
            funcMetadata.isSetup = funcData.field.meta.has(":setup");
            funcMetadata.isSetupAll = funcData.field.meta.has(":setupAll");
            funcMetadata.isTeardown = funcData.field.meta.has(":teardown");
            funcMetadata.isTeardownAll = funcData.field.meta.has(":teardownAll");
            funcMetadata.isAsync = funcData.field.meta.has(":async");

            #if debug_exunit
            if (funcMetadata.isTest) {
                trace('[ElixirCompiler] Set isTest=true for function ${funcData.field.name}');
            }
            #end

            // Check for test tags
            var tagMeta = funcData.field.meta.extract(":tag");
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

            // Check for describe block
            var describeMeta = funcData.field.meta.extract(":describe");
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
            trace('[ElixirCompiler] Class ${classType.name} extends ${parentModuleName}, isException: ${isException}');
            #end
        }

        // Enable ExUnit transformation pass for @:exunit modules
        if (classType.meta.has(":exunit")) {
            metadata.isExunit = true;
        }

        // Enable Application transformation pass for @:application modules
        if (classType.meta.has(":application")) {
            metadata.isApplication = true;
            #if debug_annotation_transforms
            trace('[ElixirCompiler] Set isApplication=true metadata for ${classType.name}');
            trace('[ElixirCompiler] Passing ${fields.length} fields to ModuleBuilder for ${classType.name}');
            #end
        }
        
        // Enable Repo transformation pass for @:repo modules
        // This was lost when ModuleBuilder was deleted in commit ecf50d9d
        if (classType.meta.has(":repo")) {
            metadata.isRepo = true;
            
            // Extract repo configuration if provided
            var repoMeta = classType.meta.extract(":repo");
            if (repoMeta.length > 0 && repoMeta[0].params != null && repoMeta[0].params.length > 0) {
                // Parse the configuration object
                // The configuration handling was also lost in the refactoring
                // For now, just set the basic metadata
                metadata.dbAdapter = "Ecto.Adapters.Postgres"; // Default to Postgres
            }
            
            #if debug_annotation_transforms
            trace('[ElixirCompiler] Set isRepo=true metadata for ${classType.name}');
            #end
        }
        
        // Enable Schema transformation pass for @:schema modules
        if (classType.meta.has(":schema")) {
            metadata.isSchema = true;
            
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
            
            // Collect schema fields from varFields for the transformation pass
            var schemaFields = [];
            for (varData in varFields) {
                // Skip if it's a static field or not a regular field
                if (!varData.isStatic && varData.field.kind.match(FVar(_, _))) {
                    var fieldName = varData.field.name;
                    var fieldType = switch(varData.field.type) {
                        case TInst(t, _): t.get().name;
                        case TAbstract(t, _): t.get().name;
                        default: "String"; // Default type
                    };
                    schemaFields.push({
                        name: fieldName,
                        type: fieldType
                    });
                }
            }
            metadata.schemaFields = schemaFields;
            
            // Store the fully qualified class name for lookups
            metadata.haxeFqcn = classType.pack.length > 0 
                ? classType.pack.join(".") + "." + classType.name 
                : classType.name;
            
            #if debug_annotation_transforms
            trace('[ElixirCompiler] Set isSchema=true metadata for ${classType.name}');
            trace('[ElixirCompiler] Table name: ${metadata.tableName}, hasTimestamps: ${metadata.hasTimestamps}');
            trace('[ElixirCompiler] Schema fields: ${schemaFields.length} fields collected');
            #end
        }
        
        // Enable Supervisor transformation pass for @:supervisor modules
        if (classType.meta.has(":supervisor")) {
            metadata.isSupervisor = true;
            #if debug_annotation_transforms
            trace('[ElixirCompiler] Set isSupervisor=true metadata for ${classType.name}');
            #end
        }
        
        // Enable Endpoint transformation pass for @:endpoint modules
        // Endpoints are also supervisors and need child_spec/start_link preservation
        if (classType.meta.has(":endpoint")) {
            metadata.isEndpoint = true;
            // Endpoints are supervisors too - they need child_spec/start_link
            metadata.isSupervisor = true;
            #if debug_annotation_transforms
            trace('[ElixirCompiler] Set isEndpoint=true and isSupervisor=true metadata for ${classType.name}');
            #end
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
            trace('[ElixirCompiler] Set isExunit=true metadata for ${classType.name}');
            #end
        }

        // Application debug output
        if (moduleAST != null && moduleAST.metadata != null && moduleAST.metadata.isApplication == true) {
            #if debug_annotation_transforms
            trace('[ElixirCompiler] Module ${classType.name} has isApplication metadata after building');
            #end
        }

        #if debug_module_builder
        if (classType.name == "Main") {
            trace('[ElixirCompiler] Received module AST for Main from ModuleBuilder');
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
                trace('[BehaviorTransformer] Restored previous behavior: ${previousBehavior}');
            } else {
                trace('[BehaviorTransformer] Deactivated behavior after building ${classType.name}');
            }
            #end
        }
        
        return moduleAST;
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
        trace('[ElixirCompiler] Generating PostgrexTypes companion module: ${typesModuleName}');
        trace('[ElixirCompiler] JSON module: ${metadata.jsonModule}, Extensions: ${metadata.extensions}');
        #end
        
        // Build the module body
        var statements = [];
        
        // Build extensions array - empty by default
        var extensionsAST = reflaxe.elixir.ast.ElixirAST.makeAST(
            reflaxe.elixir.ast.ElixirASTDef.EList([])
        );
        if (metadata.extensions != null && metadata.extensions.length > 0) {
            var extElements = metadata.extensions.map(ext -> 
                reflaxe.elixir.ast.ElixirAST.makeAST(
                    reflaxe.elixir.ast.ElixirASTDef.EAtom(ext)
                )
            );
            extensionsAST = reflaxe.elixir.ast.ElixirAST.makeAST(
                reflaxe.elixir.ast.ElixirASTDef.EList(extElements)
            );
        }
        
        // Build keyword list for options (json: Jason)
        var options = [];
        if (metadata.jsonModule != null) {
            // Create a keyword list element for json: Jason
            var jsonAtom = reflaxe.elixir.ast.ElixirAST.makeAST(
                reflaxe.elixir.ast.ElixirASTDef.EAtom(ElixirAtom.raw("json"))
            );
            var jsonModule = reflaxe.elixir.ast.ElixirAST.makeAST(
                reflaxe.elixir.ast.ElixirASTDef.EVar(metadata.jsonModule)
            );
            var keywordElement = reflaxe.elixir.ast.ElixirAST.makeAST(
                reflaxe.elixir.ast.ElixirASTDef.ETuple([jsonAtom, jsonModule])
            );
            options.push(keywordElement);
        }
        
        // Build the Postgrex.Types.define call
        var moduleRef = reflaxe.elixir.ast.ElixirAST.makeAST(
            reflaxe.elixir.ast.ElixirASTDef.EVar(typesModuleName)
        );
        var args = [
            moduleRef,          // Module reference
            extensionsAST,      // Extensions array
            reflaxe.elixir.ast.ElixirAST.makeAST(
                reflaxe.elixir.ast.ElixirASTDef.EList(options)
            )  // Options keyword list
        ];
        
        var defineCall = reflaxe.elixir.ast.ElixirAST.makeAST(
            reflaxe.elixir.ast.ElixirASTDef.ERemoteCall(
                reflaxe.elixir.ast.ElixirAST.makeAST(
                    reflaxe.elixir.ast.ElixirASTDef.EVar("Postgrex.Types")
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
        trace('[ElixirCompiler] Writing PostgrexTypes module to: ${outputPath}');
        #end
        
        // Use setExtraFile to generate the companion module
        setExtraFile(outputPath, moduleString);
    }
    
    /**
     * Helper to build AST from TypedExpr (delegates to builder)
     */
    function buildFromTypedExpr(expr: TypedExpr, ?usageMap: Map<Int, Bool>): reflaxe.elixir.ast.ElixirAST {
        // Create a fresh compilation context for this expression
        var context = createCompilationContext();

        // Set usage map if provided
        if (usageMap != null) {
            context.variableUsageMap = usageMap;
        }

        return reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);
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
     * Override called after all files have been generated by GenericCompiler.
     * This is the proper place to generate source maps since the main .ex files exist now.
     */
    public override function onCompileEnd() {
        // Generate all pending source maps after all .ex files are written
        if (sourceMapOutputEnabled) {
            for (writer in pendingSourceMapWriters) {
                if (writer != null) {
                    writer.generateSourceMap();
                }
            }
            pendingSourceMapWriters = [];
        }
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
