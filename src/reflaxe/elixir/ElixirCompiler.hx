package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Type.TConstant;
import haxe.macro.Type.AbstractType;
import haxe.macro.Type.DefType;
import haxe.macro.Expr.Binop;
import haxe.macro.Expr.Unop;
import haxe.macro.Expr;
import haxe.macro.Expr.Constant;

import reflaxe.DirectToStringCompiler;
import reflaxe.compiler.TargetCodeInjection;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;  
import reflaxe.data.EnumOptionData;
import reflaxe.preprocessors.ExpressionPreprocessor;
import reflaxe.preprocessors.ExpressionPreprocessor.*;
import reflaxe.preprocessors.implementations.RemoveTemporaryVariablesImpl.RemoveTemporaryVariablesMode;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.EnumCompiler;
import reflaxe.elixir.helpers.ClassCompiler;
import reflaxe.elixir.helpers.PatternMatcher;
import reflaxe.elixir.helpers.GuardCompiler;
import reflaxe.elixir.helpers.PipelineOptimizer;
import reflaxe.elixir.helpers.PipelineOptimizer.PipelinePattern;
import reflaxe.elixir.helpers.ImportOptimizer;
import reflaxe.elixir.helpers.MapCompiler;
import reflaxe.elixir.helpers.TemplateCompiler;
import reflaxe.elixir.helpers.SchemaCompiler;
import reflaxe.elixir.helpers.ProtocolCompiler;
import reflaxe.elixir.helpers.BehaviorCompiler;
import reflaxe.elixir.helpers.RouterCompiler;
import reflaxe.elixir.helpers.RepoCompiler;
import reflaxe.elixir.helpers.AnnotationSystem;
import reflaxe.elixir.helpers.EctoQueryAdvancedCompiler;
import reflaxe.elixir.helpers.RepositoryCompiler;
import reflaxe.elixir.helpers.FunctionCompiler;
import reflaxe.elixir.helpers.EctoErrorReporter;
import reflaxe.elixir.helpers.TypedefCompiler;
import reflaxe.elixir.helpers.HxxCompiler;
import reflaxe.elixir.helpers.LLMDocsGenerator;
import reflaxe.elixir.helpers.ExUnitCompiler;
import reflaxe.elixir.helpers.AlgebraicDataTypeCompiler;
import reflaxe.elixir.helpers.ExpressionCompiler;
import reflaxe.elixir.helpers.ArrayOptimizationCompiler;
import reflaxe.elixir.helpers.ExpressionDispatcher;
import reflaxe.elixir.ElixirTyper;
import reflaxe.elixir.helpers.DebugHelper;
import reflaxe.elixir.helpers.CompilerUtilities;
import reflaxe.elixir.helpers.LoopCompiler;
import reflaxe.elixir.helpers.PhoenixPathGenerator;
import reflaxe.elixir.helpers.PatternMatchingCompiler;
import reflaxe.elixir.helpers.MigrationCompiler;
import reflaxe.elixir.helpers.LiveViewCompiler;
import reflaxe.elixir.helpers.GenServerCompiler;
import reflaxe.elixir.helpers.MethodCallCompiler;
import reflaxe.elixir.helpers.ReflectionCompiler;
import reflaxe.elixir.helpers.ArrayMethodCompiler;
import reflaxe.elixir.helpers.MapToolsCompiler;
import reflaxe.elixir.helpers.ADTMethodCompiler;
import reflaxe.elixir.helpers.YCombinatorCompiler;
import reflaxe.elixir.helpers.PatternDetectionCompiler;
import reflaxe.elixir.helpers.WhileLoopCompiler;
import reflaxe.elixir.helpers.CodeFixupCompiler;
import reflaxe.elixir.helpers.PipelineAnalyzer;
import reflaxe.elixir.helpers.ExpressionVariantCompiler;
import reflaxe.elixir.PhoenixMapper;
import reflaxe.elixir.SourceMapWriter;

using StringTools;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.TypeHelper;

/**
 * Reflaxe.Elixir compiler for generating idiomatic Elixir code from Haxe.
 * 
 * This compiler extends BaseCompiler to provide comprehensive Haxe-to-Elixir transpilation
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
 * @see docs/05-architecture/ARCHITECTURE.md Complete architectural overview
 * @see docs/03-compiler-development/TESTING.md Testing methodology and patterns
 */
class ElixirCompiler extends DirectToStringCompiler {
    
    // File extension for generated Elixir files
    public var fileExtension: String = ".ex";
    
    // Output directory for generated files (dynamically set by Reflaxe)
    public var outputDirectory: String = "lib/";
    
    // Type mapping system for enhanced enum compilation
    private var typer: reflaxe.elixir.ElixirTyper;
    
    // Context tracking for variable substitution
    public var isInLoopContext: Bool = false;
    
    // Pattern matching and guard compilation helpers
    private var patternMatcher: reflaxe.elixir.helpers.PatternMatcher;
    private var guardCompiler: reflaxe.elixir.helpers.GuardCompiler;
    
    // Pipeline optimization for idiomatic Elixir code generation
    private var pipelineOptimizer: reflaxe.elixir.helpers.PipelineOptimizer;
    
    // Loop compilation and optimization helper
    public var loopCompiler: reflaxe.elixir.helpers.LoopCompiler;
    
    // Pattern matching compilation helper
    public var patternMatchingCompiler: reflaxe.elixir.helpers.PatternMatchingCompiler;
    
    // Schema and changeset compilation helper
    private var schemaCompiler: reflaxe.elixir.helpers.SchemaCompiler;
    
    // Migration compilation helper
    private var migrationCompiler: reflaxe.elixir.helpers.MigrationCompiler;
    
    // LiveView compilation helper
    private var liveViewCompiler: reflaxe.elixir.helpers.LiveViewCompiler;
    
    // GenServer compilation helper
    private var genServerCompiler: reflaxe.elixir.helpers.GenServerCompiler;
    
    // Method call compilation
    private var methodCallCompiler: reflaxe.elixir.helpers.MethodCallCompiler;
    
    // Reflection compilation
    private var reflectionCompiler: reflaxe.elixir.helpers.ReflectionCompiler;
    
    // Array optimization compiler for loop pattern detection and Enum function generation
    private var arrayOptimizationCompiler: reflaxe.elixir.helpers.ArrayOptimizationCompiler;
    
    // Variable substitution and renaming compiler for centralized variable handling
    public var substitutionCompiler: reflaxe.elixir.helpers.SubstitutionCompiler;
    
    // Temporary variable pattern optimization
    private var tempVariableOptimizer: reflaxe.elixir.helpers.TempVariableOptimizer;
    
    // Naming convention and file path management
    private var namingConventionCompiler: reflaxe.elixir.helpers.NamingConventionCompiler;
    
    // State threading and parameter mapping management
    private var stateManagementCompiler: reflaxe.elixir.helpers.StateManagementCompiler;
    
    // Function compilation
    private var functionCompiler: reflaxe.elixir.helpers.FunctionCompiler;
    
    // Array method compilation
    private var arrayMethodCompiler: reflaxe.elixir.helpers.ArrayMethodCompiler;
    
    // MapTools extension method compilation
    private var mapToolsCompiler: reflaxe.elixir.helpers.MapToolsCompiler;
    
    // ADT (Option/Result) static extension method compilation
    private var adtMethodCompiler: reflaxe.elixir.helpers.ADTMethodCompiler;
    
    /** Y combinator pattern detection and generation utilities */
    private var yCombinatorCompiler: reflaxe.elixir.helpers.YCombinatorCompiler;
    
    /** Pattern detection and analysis utilities */
    private var patternDetectionCompiler: reflaxe.elixir.helpers.PatternDetectionCompiler;
    
    /** Pattern analysis for structural and framework pattern detection */
    private var patternAnalysisCompiler: reflaxe.elixir.helpers.PatternAnalysisCompiler;
    
    /** Type resolution and mapping between Haxe and Elixir type systems */
    private var typeResolutionCompiler: reflaxe.elixir.helpers.TypeResolutionCompiler;
    
    /** Code fixup and post-processing operations for generated Elixir code */
    private var codeFixupCompiler: reflaxe.elixir.helpers.CodeFixupCompiler;
    
    /** Pipeline pattern detection and variable analysis for optimization compilation */
    private var pipelineAnalyzer: reflaxe.elixir.helpers.PipelineAnalyzer;
    
    /** While loop compilation with Y combinator pattern generation */
    private var whileLoopCompiler: reflaxe.elixir.helpers.WhileLoopCompiler;
    
    /** Expression variant compilation for specialized expression handling patterns */
    private var expressionVariantCompiler: reflaxe.elixir.helpers.ExpressionVariantCompiler;
    
    public var expressionDispatcher: reflaxe.elixir.helpers.ExpressionDispatcher;
    
    // Import optimization for clean import statements
    private var importOptimizer: reflaxe.elixir.helpers.ImportOptimizer;
    
    // Source mapping support for debugging and LLM workflows
    private var currentSourceMapWriter: Null<SourceMapWriter> = null;
    private var sourceMapOutputEnabled: Bool = false;
    private var pendingSourceMapWriters: Array<SourceMapWriter> = [];
    
    // Parameter mapping system for abstract type implementation methods
    public var currentFunctionParameterMap: Map<String, String> = new Map();
    
    // Map for tracking variable renames to ensure consistency between declaration and usage
    // Critical for resolving _g variable collisions in desugared loops
    public var variableRenameMap: Null<Map<String, String>> = null;
    
    // Track inline function context across multiple expressions in a block
    // Maps inline variable names (like "struct") to their assigned values (like "struct.buf")
    public var inlineContextMap: Map<String, String> = new Map<String, String>();
    private var isCompilingAbstractMethod: Bool = false;
    public var isCompilingCaseArm: Bool = false;
    
    // Track when we're inside enum parameter extraction to prevent incorrect variable mappings
    public var isInEnumExtraction: Bool = false;
    
    // Current class context for app name resolution and other class-specific operations
    public var currentClassType: Null<ClassType> = null;
    
    // Track instance variable names for LiveView classes to generate socket.assigns references
    public var liveViewInstanceVars: Null<Map<String, Bool>> = null;
    
    /**
     * STATE THREADING MODE
     * 
     * WHY: Transform mutable field assignments in Haxe to immutable struct updates in Elixir
     * WHAT: Track when we're compiling a mutating method that needs state threading
     * HOW: When enabled, field assignments generate struct updates that are threaded through
     */
    public var stateThreadingEnabled: Bool = false;
    public var stateThreadingInfo: Null<reflaxe.elixir.helpers.MutabilityAnalyzer.MutabilityInfo> = null;
    
    /**
     * GLOBAL STRUCT METHOD COMPILATION
     * 
     * WHY: Fix JsonPrinter _this issue - parameter mapping gets lost in nested contexts
     * WHAT: Track if we're compiling ANY struct method globally
     * HOW: Set flag when compiling struct methods, use global mapping that persists through all nested compilation
     */
    public var isCompilingStructMethod: Bool = false;
    public var globalStructParameterMap: Map<String, String> = new Map();
    
    /**
     * Constructor - Initialize the compiler with type mapping and pattern matching systems
     */
    public function new() {
        super();
        this.typer = new reflaxe.elixir.ElixirTyper();
        this.patternMatcher = new reflaxe.elixir.helpers.PatternMatcher();
        this.patternMatcher.setCompiler(this);
        this.guardCompiler = new reflaxe.elixir.helpers.GuardCompiler();
        this.pipelineOptimizer = new reflaxe.elixir.helpers.PipelineOptimizer(this);
        this.importOptimizer = new reflaxe.elixir.helpers.ImportOptimizer(this);
        this.loopCompiler = new reflaxe.elixir.helpers.LoopCompiler(this);
        this.patternMatchingCompiler = new reflaxe.elixir.helpers.PatternMatchingCompiler(this);
        this.schemaCompiler = new reflaxe.elixir.helpers.SchemaCompiler(this);
        this.migrationCompiler = new reflaxe.elixir.helpers.MigrationCompiler(this);
        this.liveViewCompiler = new reflaxe.elixir.helpers.LiveViewCompiler(this);
        this.genServerCompiler = new reflaxe.elixir.helpers.GenServerCompiler(this);
        this.methodCallCompiler = new reflaxe.elixir.helpers.MethodCallCompiler(this);
        this.reflectionCompiler = new reflaxe.elixir.helpers.ReflectionCompiler(this);
        this.arrayOptimizationCompiler = new reflaxe.elixir.helpers.ArrayOptimizationCompiler(this);
        this.substitutionCompiler = new reflaxe.elixir.helpers.SubstitutionCompiler(this);
        this.tempVariableOptimizer = new reflaxe.elixir.helpers.TempVariableOptimizer(this);
        this.namingConventionCompiler = new reflaxe.elixir.helpers.NamingConventionCompiler(this);
        this.stateManagementCompiler = new reflaxe.elixir.helpers.StateManagementCompiler(this);
        this.functionCompiler = new reflaxe.elixir.helpers.FunctionCompiler(this);
        this.arrayMethodCompiler = new reflaxe.elixir.helpers.ArrayMethodCompiler(this);
        this.mapToolsCompiler = new reflaxe.elixir.helpers.MapToolsCompiler(this);
        this.adtMethodCompiler = new reflaxe.elixir.helpers.ADTMethodCompiler(this);
        this.yCombinatorCompiler = new reflaxe.elixir.helpers.YCombinatorCompiler(this);
        this.patternDetectionCompiler = new reflaxe.elixir.helpers.PatternDetectionCompiler(this);
        this.patternAnalysisCompiler = new reflaxe.elixir.helpers.PatternAnalysisCompiler(this);
        this.typeResolutionCompiler = new reflaxe.elixir.helpers.TypeResolutionCompiler(this);
        this.codeFixupCompiler = new reflaxe.elixir.helpers.CodeFixupCompiler(this);
        this.pipelineAnalyzer = new reflaxe.elixir.helpers.PipelineAnalyzer(this);
        this.whileLoopCompiler = new reflaxe.elixir.helpers.WhileLoopCompiler(this);
        this.expressionVariantCompiler = new reflaxe.elixir.helpers.ExpressionVariantCompiler(this);
        this.expressionDispatcher = new reflaxe.elixir.helpers.ExpressionDispatcher(this);
        
        // Set compiler reference for delegation
        this.patternMatcher.setCompiler(this);
        
        // Enable source mapping if requested
        this.sourceMapOutputEnabled = Context.defined("source-map") || Context.defined("debug");
        
        // Configure Reflaxe 4.0 preprocessors for optimized code generation
        // These preprocessors clean up the AST before we compile it to Elixir
        options.expressionPreprocessors = [
            SanitizeEverythingIsExpression({}),                      // Convert "everything is expression" to imperative
            RemoveTemporaryVariables(RemoveTemporaryVariablesMode.AllVariables), // Remove ALL temporary variables aggressively  
            PreventRepeatVariables({}),                              // Ensure unique variable names
            RemoveSingleExpressionBlocks,                            // Simplify single-expression blocks
            RemoveConstantBoolIfs,                                   // Remove constant conditional checks
            RemoveUnnecessaryBlocks,                                 // Remove redundant blocks
            RemoveReassignedVariableDeclarations,                    // Optimize variable declarations
            RemoveLocalVariableAliases,                              // Remove unnecessary aliases
            MarkUnusedVariables                                      // Mark unused variables for removal
        ];
        
        // Initialize LLM documentation generator (optional)
        if (Context.defined("generate-llm-docs")) {
            LLMDocsGenerator.initialize();
        }
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
     * Fix malformed conditional expressions that can occur in complex Y combinator bodies
     * 
     * Pattern to fix: "}, else: expression" without proper "if condition, do:" prefix
     * These occur when if-else expressions are incorrectly split during compilation
     */
    private function fixMalformedConditionals(code: String): String {
        return codeFixupCompiler.fixMalformedConditionals(code);
    }

    public function getCurrentAppName(): String {
        return codeFixupCompiler.getCurrentAppName();
    }
    
    /**
     * Replace getAppName() calls with the actual app name from the annotation
     * This post-processing step enables dynamic app name injection in generated code
     */
    private function replaceAppNameCalls(code: String, classType: ClassType): String {
        return codeFixupCompiler.replaceAppNameCalls(code, classType);
    }
    
    /**
     * Initialize source map writer for a specific output file
     */
    private function initSourceMapWriter(outputPath: String): Void {
        codeFixupCompiler.initSourceMapWriter(outputPath);
    }
    
    /**
     * Finalize source map writer and generate .ex.map file
     */
    private function finalizeSourceMapWriter(): Null<String> {
        return codeFixupCompiler.finalizeSourceMapWriter();
    }
    
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
    public function containsVariableReference(expr: TypedExpr, variableName: String): Bool {
        return pipelineAnalyzer.containsVariableReference(expr, variableName);
    }
    
    /**
     * Determine which statement indices were processed as part of a pipeline pattern.
     * This prevents double-compilation of statements that were already included in the pipeline.
     */
    private function getProcessedStatementIndices(statements: Array<TypedExpr>, pattern: PipelinePattern): Array<Int> {
        return pipelineAnalyzer.getProcessedStatementIndices(statements, pattern);
    }
    
    // statementTargetsVariable temporarily reverted for debugging
    private function statementTargetsVariable(stmt: TypedExpr, variableName: String): Bool {
        return pipelineAnalyzer.statementTargetsVariable(stmt, variableName);
    }
    
    // isTerminalOperation temporarily reverted for debugging
    private function isTerminalOperation(stmt: TypedExpr, variableName: String): Bool {
        return pipelineAnalyzer.isTerminalOperation(stmt, variableName);
    }
    
    // isTerminalOperationOnVariable temporarily reverted for debugging
    private function isTerminalOperationOnVariable(expr: TypedExpr, variableName: String): Bool {
        return pipelineAnalyzer.isTerminalOperationOnVariable(expr, variableName);
    }
    
    /**
     * Extract the terminal function call from an expression, removing the pipeline variable reference
     * For example: Repo.all(query) becomes "Repo.all()"
     */
    private function extractTerminalCall(expr: TypedExpr, variableName: String): Null<String> {
        return pipelineAnalyzer.extractTerminalCall(expr, variableName);
    }
    
    // extractFunctionNameFromCall temporarily reverted for debugging
    private function extractFunctionNameFromCall(funcExpr: TypedExpr): String {
        return pipelineAnalyzer.extractFunctionNameFromCall(funcExpr);
    }

    // containsVariableReference moved to VariableCompiler.hx
    
    /**
     * Detect if a LiveView class uses Phoenix CoreComponents
     * Simple heuristic: assumes CoreComponents are used if this is a LiveView class
     */
    private function detectCoreComponentsUsage(classType: ClassType, funcFields: Array<ClassFuncData>): Bool {
        return patternAnalysisCompiler.detectCoreComponentsUsage(classType, funcFields);
    }
    
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
     * Delegates to NamingHelper for consistency
     */
    public function toElixirName(haxeName: String): String {
        return namingConventionCompiler.toElixirName(haxeName);
    }
    
    /**
     * Convert package.ClassName to package/class_name.ex path
     * Examples: 
     * - haxe.CallStack → haxe/call_stack  
     * - TestDocClass → test_doc_class
     * - my.nested.Module → my/nested/module
     */
    private function convertPackageToDirectoryPath(classType: ClassType): String {
        return namingConventionCompiler.convertPackageToDirectoryPath(classType);
    }
    
    /**
     * Set framework-aware output path using Reflaxe's built-in file placement system.
     * 
     * This method detects framework annotations and uses setOutputFileDir() and setOutputFileName()
     * to place files in Phoenix-expected locations BEFORE compilation occurs.
     * 
     * COMPREHENSIVE: Now handles packages, @:native annotations, and universal snake_case conversion.
     */
    private function setFrameworkAwareOutputPath(classType: ClassType): Void {
        namingConventionCompiler.setFrameworkAwareOutputPath(classType);
    }
    
    /**
     * Universal naming system for ALL module types (classes, enums, abstracts, typedefs).
     * 
     * This is the SINGLE SOURCE OF TRUTH for file naming across the entire compiler.
     * It handles dot notation (haxe.CallStack → haxe/call_stack), ensures snake_case
     * for all parts, and works with any module type.
     * 
     * @param moduleName Full module name including dots (e.g., "haxe.CallStack", "Any")
     * @param pack Package array (can be empty)
     * @return Naming rule with snake_case fileName and dirPath
     */
    /**
     * Universal naming rule system - delegates to NamingHelper for centralized logic
     * 
     * WHY: Delegates to NamingHelper for centralized naming rule management
     * WHAT: Wrapper function that maintains backward compatibility while delegating
     * HOW: Simply forwards the call to NamingHelper.getUniversalNamingRule()
     * 
     * @param moduleName The Haxe module name (can contain dots)
     * @param pack Optional package array for directory structure
     * @return Object with fileName and dirPath for consistent naming
     */
    private function getUniversalNamingRule(moduleName: String, pack: Array<String> = null): {fileName: String, dirPath: String} {
        return namingConventionCompiler.getUniversalNamingRule(moduleName, pack);
    }
    
    /**
     * Set output path for ANY module type using the universal naming system.
     * This ensures consistent snake_case naming for all generated files.
     */
    private function setUniversalOutputPath(moduleName: String, pack: Array<String> = null): Void {
        namingConventionCompiler.setUniversalOutputPath(moduleName, pack);
    }
    
    /**
     * Comprehensive naming rule system - handles ALL naming scenarios.
     * 
     * This centralizes ALL naming logic including:
     * - Package-to-directory conversion (my.package.Class → my/package/)
     * - Framework annotations (@:router, @:liveview, etc.)
     * - Universal snake_case conversion
     * - @:native annotation handling
     * 
     * Every file gets proper Elixir naming conventions applied.
     */
    /**
     * DELEGATION: Comprehensive naming rule extraction (moved to PhoenixPathGenerator.hx)
     * 
     * ARCHITECTURAL DECISION: This function was moved to PhoenixPathGenerator.hx as part of 
     * naming/path utilities consolidation. Framework-specific path generation logic belongs 
     * with other Phoenix path generation functionality, not in the main compiler.
     * 
     * @param classType The Haxe ClassType containing metadata and package information
     * @return Object with fileName and dirPath following Phoenix conventions
     */
    private function getComprehensiveNamingRule(classType: ClassType): {fileName: String, dirPath: String} {
        return namingConventionCompiler.getComprehensiveNamingRule(classType);
    }
    
    /**
     * STATE THREADING METHOD SUITE
     * 
     * WHY: Enable transformation of mutable Haxe code to immutable Elixir patterns
     * WHAT: Manage compiler state for mutable-to-immutable transformations
     * HOW: Track mutability info and enable appropriate transformations
     */
    
    /**
     * Enable state threading mode for mutating methods
     * 
     * WHY: Mutating methods need special handling to return updated structs
     * WHAT: Activates transformation of field assignments to struct updates
     * HOW: Sets flags that OperatorCompiler and other helpers check
     * 
     * @param info Mutability analysis results from MutabilityAnalyzer
     */
    public function enableStateThreadingMode(info: reflaxe.elixir.helpers.MutabilityAnalyzer.MutabilityInfo): Void {
        stateManagementCompiler.enableStateThreadingMode(info);
    }
    
    /**
     * Disable state threading mode after method compilation
     * 
     * WHY: State threading should only apply to specific mutating methods
     * WHAT: Resets transformation flags to normal compilation mode
     * HOW: Clears flags and mutability info
     */
    public function disableStateThreadingMode(): Void {
        stateManagementCompiler.disableStateThreadingMode();
    }
    
    /**
     * Check if state threading is currently enabled
     * 
     * WHY: Other compilers need to know if they should transform assignments
     * WHAT: Returns current state threading status
     * HOW: Simple flag check
     * 
     * @return True if state threading transformations should be applied
     */
    public function isStateThreadingEnabled(): Bool {
        return stateManagementCompiler.isStateThreadingEnabled();
    }
    
    /**
     * Get current mutability information
     * 
     * WHY: Helpers need to know which fields are being mutated
     * WHAT: Returns analysis results from MutabilityAnalyzer
     * HOW: Returns stored mutability info
     * 
     * @return Mutability analysis results or null
     */
    public function getStateThreadingInfo(): Null<reflaxe.elixir.helpers.MutabilityAnalyzer.MutabilityInfo> {
        return stateManagementCompiler.getStateThreadingInfo();
    }
    
    /**
     * Set parameter mapping for 'this' references
     * 
     * WHY: Haxe uses 'this' but Elixir structs use explicit parameter names
     * WHAT: Maps 'this' and '_this' to the struct parameter name
     * HOW: Updates the parameter map used during expression compilation
     * 
     * @param structParamName The parameter name to use (typically "struct")
     */
    public function setThisParameterMapping(structParamName: String): Void {
        stateManagementCompiler.setParameterMapping(structParamName);
    }
    
    /**
     * Clear parameter mapping after method compilation
     * 
     * WHY: Parameter mappings should be function-scoped
     * WHAT: Removes 'this' mappings from the parameter map
     * HOW: Clears specific keys from the map
     */
    public function clearThisParameterMapping(): Void {
        stateManagementCompiler.clearParameterMapping();
    }
    
    /**
     * Start compiling a struct method globally
     * 
     * WHY: JsonPrinter _this issue - ensure _this mapping persists through ALL nested contexts
     * WHAT: Set global flag and global parameter mapping that survives context switches
     * HOW: Store mapping in separate global map that compileExpressionImpl always checks
     * 
     * @param structParamName The parameter name to use for _this mapping (typically "struct")
     */
    public function startCompilingStructMethod(structParamName: String): Void {
        stateManagementCompiler.startGlobalStructMethodCompilation(structParamName);
    }
    
    /**
     * Stop compiling struct method globally
     * 
     * WHY: Global state should be cleaned up after struct method compilation
     * WHAT: Clear global flag and global parameter mapping
     * HOW: Reset global state variables
     */
    public function stopCompilingStructMethod(): Void {
        stateManagementCompiler.stopGlobalStructMethodCompilation();
    }
    
    /**
     * Set inline context for variable replacement
     * 
     * WHY: Some variables need to be replaced during compilation
     * WHAT: Maps variable names to replacement values
     * HOW: Updates the inline context map
     * 
     * @param varName The variable name to replace
     * @param replacement The replacement value
     */
    public function setInlineContext(varName: String, replacement: String): Void {
        stateManagementCompiler.setInlineContext(varName, replacement);
    }
    
    /**
     * Check if inline context exists for a variable
     * 
     * WHY: Need to determine if a variable has an inline replacement
     * WHAT: Checks if the variable exists in the inline context map
     * HOW: Returns true if the variable has been mapped
     * 
     * @param varName The variable name to check
     * @return True if the variable has an inline context mapping
     */
    public function hasInlineContext(varName: String): Bool {
        return stateManagementCompiler.hasInlineContext(varName);
    }
    
    /**
     * Get inline context value for a variable
     * 
     * WHY: Need to retrieve replacement values for inline context
     * WHAT: Gets the replacement value for a variable
     * HOW: Returns the mapped value or null if not found
     * 
     * @param varName The variable name to look up
     * @return The replacement value or null
     */
    private function getInlineContext(varName: String): Null<String> {
        return stateManagementCompiler.getInlineContext(varName);
    }
    
    /**
     * Clear inline context after use
     * 
     * WHY: Inline context should be scoped to specific compilations
     * WHAT: Clears the inline context map
     * HOW: Removes all entries from the map
     */
    public function clearInlineContext(): Void {
        stateManagementCompiler.clearInlineContext();
    }
    
    /**
     * Required implementation for DirectToStringCompiler - implements class compilation
     * @param classType The Haxe class type
     * @param varFields Class variables
     * @param funcFields Class functions
     * @return Generated Elixir module string
     */
    public function compileClassImpl(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<String> {
        if (classType == null) return null;
        
        // Skip standard library classes that shouldn't generate Elixir modules
        if (isStandardLibraryClass(classType.name)) {
            return null;
        }
        
        // Store current class context for use in expression compilation
        this.currentClassType = classType;
        
        // Reset import optimizer for this module
        importOptimizer.reset();
        
        // Set framework-aware file path BEFORE compilation using Reflaxe's built-in system
        setFrameworkAwareOutputPath(classType);
        trace('DEBUG: setFrameworkAwareOutputPath completed for ${classType.name}');
        
        // Initialize source mapping for this class
        if (sourceMapOutputEnabled) {
            trace('DEBUG: Starting source mapping for ${classType.name}');
            var className = classType.name;
            var actualOutputDir = this.output.outputDir != null ? this.output.outputDir : outputDirectory;
            
            // Annotation-aware file path generation for framework convention adherence
            var outputPath = PhoenixPathGenerator.generateAnnotationAwareOutputPath(classType, actualOutputDir, fileExtension);
            initSourceMapWriter(outputPath);
            trace('DEBUG: Source mapping completed for ${classType.name}');
        }
        trace('DEBUG: About to check ExUnit for ${classType.name}');
        
        // Check for ExUnit test classes first (before other annotations)
        try {
            trace('DEBUG: About to call ExUnitCompiler.isExUnitTest for ${classType.name}');
            if (ExUnitCompiler.isExUnitTest(classType)) {
                trace('DEBUG: ${classType.name} is an ExUnit test');
                var result = ExUnitCompiler.compile(classType, this);
                return result;
            }
            trace('DEBUG: ${classType.name} is NOT an ExUnit test, continuing');
        } catch (e: Dynamic) {
            trace('DEBUG: ERROR in ExUnit check for ${classType.name}: ${e}');
            throw e;
        }
        
        // Use unified annotation system for detection, validation, and routing
        trace('DEBUG: About to call AnnotationSystem.routeCompilation for ${classType.name}');
        var annotationResult = reflaxe.elixir.helpers.AnnotationSystem.routeCompilation(classType, varFields, funcFields);
        trace('DEBUG: AnnotationSystem.routeCompilation completed for ${classType.name}');
        if (annotationResult != null) {
            return annotationResult;
        }
        
        // Check if this is a LiveView class that should use special compilation
        trace('DEBUG: About to call AnnotationSystem.detectAnnotations for ${classType.name}');
        var annotationInfo = reflaxe.elixir.helpers.AnnotationSystem.detectAnnotations(classType);
        trace('DEBUG: AnnotationSystem.detectAnnotations completed for ${classType.name}');
        if (annotationInfo.primaryAnnotation == ":liveview") {
            var result = compileLiveViewClass(classType, varFields, funcFields);
            return result;
        }
        trace('DEBUG: Not a LiveView, continuing to ClassCompiler for ${classType.name}');
        
        // Use the enhanced ClassCompiler for proper struct/module generation
        trace('DEBUG: About to create ClassCompiler for ${classType.name}');
        var classCompiler = new reflaxe.elixir.helpers.ClassCompiler(this.typer);
        trace('DEBUG: ClassCompiler created, setting compiler for ${classType.name}');
        classCompiler.setCompiler(this);
        trace('DEBUG: Compiler set, setting import optimizer for ${classType.name}');
        classCompiler.setImportOptimizer(importOptimizer);
        trace('DEBUG: ClassCompiler setup complete for ${classType.name}');
        
        // Handle inheritance tracking
        trace('DEBUG: Checking inheritance for ${classType.name}');
        if (classType.superClass != null) {
            trace('DEBUG: ${classType.name} has superclass, adding for compilation');
            addModuleTypeForCompilation(TClassDecl(classType.superClass.t));
        }
        trace('DEBUG: Inheritance check complete for ${classType.name}');
        
        // Handle interface tracking
        trace('DEBUG: Checking interfaces for ${classType.name}');
        for (iface in classType.interfaces) {
            addModuleTypeForCompilation(TClassDecl(iface.t));
        }
        trace('DEBUG: Interface check complete for ${classType.name}');
        
        trace('DEBUG: About to call classCompiler.compileClass for ${classType.name}');
        var result = classCompiler.compileClass(classType, varFields, funcFields);
        trace('DEBUG: classCompiler.compileClass completed for ${classType.name}');
        
        // Post-process to replace getAppName() calls with actual app name
        if (result != null) {
            result = replaceAppNameCalls(result, classType);
        }
        
        return result;
    }
    
    /**
     * Compile @:migration annotated class to Ecto migration module
     */
    private function compileMigrationClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        // Delegate to specialized migration compiler
        return migrationCompiler.compileMigrationClass(classType, varFields, funcFields);
    }
    
    
    /**
     * Compile @:template annotated class to Phoenix template module
     */
    private function compileTemplateClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.helpers.TemplateCompiler.getTemplateConfig(classType);
        
        // Generate comprehensive template module with Phoenix.Component integration
        return reflaxe.elixir.helpers.TemplateCompiler.compileFullTemplate(className, config);
    }
    
    /**
     * Compile @:schema annotated class to Ecto.Schema module with enhanced error reporting
     */
    private function compileSchemaClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        // Delegate to specialized schema compiler
        return schemaCompiler.compileSchemaClass(classType, varFields, funcFields);
    }
    
    /**
     * Compile @:changeset annotated class to Ecto changeset module with enhanced error reporting
     */
    private function compileChangesetClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        // Delegate to specialized schema compiler (handles both @:schema and @:changeset)
        return schemaCompiler.compileChangesetClass(classType, varFields, funcFields);
    }
    
    /**
     * Compile @:genserver annotated class to OTP GenServer module
     */
    private function compileGenServerClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        // Delegate to specialized GenServer compiler
        return genServerCompiler.compileGenServerClass(classType, varFields, funcFields);
    }
    
    /**
     * Compile @:liveview annotated class to Phoenix LiveView module  
     */
    private function compileLiveViewClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        // Delegate to specialized LiveView compiler
        return liveViewCompiler.compileLiveViewClass(classType, varFields, funcFields);
    }
    
    /**
     * Required implementation for DirectToStringCompiler - implements enum compilation
     */
    public function compileEnumImpl(enumType: EnumType, options: Array<EnumOptionData>): Null<String> {
        if (enumType == null) return null;
        
        // Set universal output path for consistent snake_case naming
        setUniversalOutputPath(enumType.name, enumType.pack);
        
        // Use the enhanced EnumCompiler helper for proper type integration
        var enumCompiler = new reflaxe.elixir.helpers.EnumCompiler(this.typer);
        return enumCompiler.compileEnum(enumType, options);
    }
    
    /**
     * Compile expression - required by DirectToStringCompiler (implements abstract method)
     * 
     * WHY: Delegates to ExpressionDispatcher to replace the massive 2,011-line compileElixirExpressionInternal function
     * WHAT: Clean entry point that routes TypedExpr compilation to specialized expression compilers
     * HOW: Uses the dispatcher pattern to maintain clean separation of concerns
     */
    /**
     * Override base compileExpression to ensure ALL expression compilation goes through state threading
     * 
     * WHY: The base DirectToStringCompiler has a compileExpression method that helper classes call.
     * We need to intercept ALL these calls to apply state threading transformations consistently.
     * 
     * WHAT: Routes all expression compilation through our state threading logic before delegating
     * to the expression dispatcher for actual compilation.
     * 
     * HOW: Check for state threading conditions first, then delegate to expressionDispatcher.
     */
    public override function compileExpression(expr: TypedExpr, topLevel: Bool = false): Null<String> {
        #if debug_state_threading
        trace('[XRay ElixirCompiler] ✓ compileExpression override called');
        #end
        return compileExpressionImpl(expr, topLevel);
    }
    
    public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<String> {
        return expressionVariantCompiler.compileExpressionImpl(expr, topLevel);
    }
    
    /**
     * Compile abstract types - generates proper Elixir type aliases and implementation modules
     * Abstract types in Haxe become type aliases in Elixir with implementation modules for operators
     */
    public override function compileAbstractImpl(abstractType: AbstractType): Null<String> {
        // Skip core Haxe types that are handled elsewhere
        // Return null (not empty string) to prevent file generation
        if (isBuiltinAbstractType(abstractType.name)) {
            return null;
        }
        
        // Set universal output path for consistent snake_case naming
        setUniversalOutputPath(abstractType.name, abstractType.pack);
        
        // Skip Haxe constraint abstracts that don't need generation
        // These are internal Haxe types used for type constraints
        if (abstractType.name == "FlatEnum" || abstractType.name == "NotVoid" || 
            abstractType.name == "Constructible" || abstractType.pack.join(".") == "haxe.Constraints") {
            return null; // Return null to prevent file generation
        }
        
        // Generate Elixir type alias for the abstract
        final typeName = abstractType.name;
        final underlyingType = getElixirTypeFromHaxeType(abstractType.type);
        
        // For now, don't generate standalone type alias files - they cause compilation errors
        // Type aliases should be defined within modules that use them
        // Skipping standalone type alias generation for abstract
        
        // Return null to prevent generating a standalone file for type-only abstracts
        return null;
    }
    
    /**
     * Check if this is a built-in Haxe type that should NOT generate an Elixir module
     * This includes standard library types that are either built-in or handled elsewhere
     */
    private function isBuiltinAbstractType(name: String): Bool {
        return typeResolutionCompiler.isBuiltinAbstractType(name);
    }
    
    /**
     * Check if this is a standard library class type that should NOT generate an Elixir module
     */
    private function isStandardLibraryClass(name: String): Bool {
        return typeResolutionCompiler.isStandardLibraryClass(name);
    }

    /**
     * Get Elixir type representation from Haxe type
     */
    private function getElixirTypeFromHaxeType(type: Type): String {
        return typeResolutionCompiler.getElixirTypeFromHaxeType(type);
    }
    
    /**
     * Helper methods for managing module content - simplified for now
     */
    private function getCurrentModuleContent(abstractType: AbstractType): Null<String> {
        return typeResolutionCompiler.getCurrentModuleContent(abstractType);
    }
    
    private function addTypeDefinition(content: String, typeAlias: String): String {
        return typeResolutionCompiler.addTypeDefinition(content, typeAlias);
    }
    
    private function updateCurrentModuleContent(abstractType: AbstractType, content: String): Void {
        typeResolutionCompiler.updateCurrentModuleContent(abstractType, content);
    }
    
    /**
     * Compile typedef - Returns null to ignore typedefs as BaseCompiler recommends.
     * This prevents generating invalid StdTypes.ex files with @typedoc/@type outside modules.
     */
    public override function compileTypedefImpl(defType: DefType): Null<String> {
        return typeResolutionCompiler.compileTypedefImpl(defType);
    }
    
    
    
    /**
     * Compile switch expression to Elixir case statement with advanced pattern matching
     * Supports enum patterns, guard clauses, binary patterns, and pin operators
     */
    // Delegated to PatternMatchingCompiler - keeping for backward compatibility
    public function compileSwitchExpression(switchExpr: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, defaultExpr: Null<TypedExpr>): String {
        return expressionVariantCompiler.compileSwitchExpression(switchExpr, cases, defaultExpr);
    }
    
    /**
     * Check if an enum type is the Result<T,E> type
     */
    public function isResultType(enumType: EnumType): Bool {
        return AlgebraicDataTypeCompiler.isADTType(enumType) && 
               enumType.name == "Result";
    }
    
    /**
     * Check if an enum type is the Option<T> type  
     */
    public function isOptionType(enumType: EnumType): Bool {
        return AlgebraicDataTypeCompiler.isADTType(enumType) && 
               enumType.name == "Option";
    }
    
    
    /**
     * Helper: Compile struct definition from class variables
     */
    private function compileStruct(varFields: Array<ClassVarData>): String {
        var result = '  defstruct [';
        var fieldNames = [];
        
        for (field in varFields) {
            var fieldName = toElixirName(field.field.name);
            fieldNames.push('${fieldName}: nil');
        }
        
        result += fieldNames.join(', ');
        result += ']\n\n';
        
        return result;
    }
    
    /**
     * Helper: Compile function definition
     */
    /**
     * DELEGATION: Function compilation (moved to FunctionCompiler.hx)
     * 
     * ARCHITECTURAL DECISION: This function was moved to FunctionCompiler.hx as part of 
     * function compilation logic consolidation. Function-specific compilation including
     * parameter mapping, pipeline optimization, and LiveView callback handling belongs
     * in a specialized compiler, not in the main compiler.
     * 
     * @param funcField The Haxe function data including name, parameters, and body  
     * @param isStatic Whether this is a static function (currently unused)
     * @return Complete Elixir function definition string
     */
    public function compileFunction(funcField: ClassFuncData, isStatic: Bool = false): String {
        return functionCompiler.compileFunction(funcField, isStatic);
    }
    
    /**
     * Helper: Check if class has instance variables (non-static)
     */
    private function hasInstanceVars(varFields: Array<ClassVarData>): Bool {
        for (field in varFields) {
            if (!field.isStatic) return true;
        }
        return false;
    }
    
    /**
     * Helper: Check if expression is enum field access
     */
    private function isEnumFieldAccess(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TField(_, FEnum(_, _)): true;
            case _: false;
        }
    }
    
    /**
     * Helper: Extract enum field name from TField expression
     */
    private function extractEnumFieldName(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TField(_, FEnum(_, enumField)): NamingHelper.toSnakeCase(enumField.name);
            case _: "unknown";
        }
    }
    
    /**
     * Helper: Compile constants to Elixir literals
     */
    public function compileConstant(constant: Constant): String {
        return switch (constant) {
            case CInt(i, _): i;
            case CFloat(s, _): s;
            case CString(s, _): '"${s}"';
            case CIdent(s): s;
            case CRegexp(r, opt): '~r/${r}/${opt}';
            case _: "nil";
        }
    }
    
    /**
     * Helper: Compile TConstant (typed constants) to Elixir literals
     */
    // compileTConstant function extracted to LiteralCompiler
    
    /**
     * Compile expression with proper type awareness for operators.
     * This ensures string concatenation uses <> and not +.
     */
    private function compileExpressionWithTypeAwareness(expr: TypedExpr): String {
        return expressionVariantCompiler.compileExpressionWithTypeAwareness(expr);
    }
    
    /**
     * Check if a Type is a string type
     */
    public function isStringType(type: Type): Bool {
        if (type == null) return false;
        
        return switch (type) {
            case TInst(t, _):
                t.get().name == "String";
            case TAbstract(t, _):
                t.get().name == "String";
            case _:
                false;
        };
    }
    
    /**
     * Convert a non-string expression to a string in Elixir
     */
    public function convertToString(expr: TypedExpr, compiledExpr: String): String {
        // Check the type and use the appropriate conversion function
        return switch (expr.t) {
            case TAbstract(t, _):
                var typeName = t.get().name;
                switch (typeName) {
                    case "Int":
                        'Integer.to_string(${compiledExpr})';
                    case "Float":
                        'Float.to_string(${compiledExpr})';
                    case "Bool":
                        'Atom.to_string(${compiledExpr})';
                    case _:
                        // For other types, use Kernel.inspect for a safe conversion
                        'Kernel.inspect(${compiledExpr})';
                }
            case TInst(t, _):
                // For class instances, use inspect
                'Kernel.inspect(${compiledExpr})';
            case _:
                // Default: use inspect for safety
                'Kernel.inspect(${compiledExpr})';
        };
    }
    
    /**
     * Helper: Compile binary operators to Elixir
     */
    public function compileBinop(op: Binop): String {
        return switch (op) {
            case OpAdd: "+";
            case OpMult: "*";
            case OpDiv: "/";
            case OpSub: "-";
            case OpAssign: "=";
            case OpEq: "==";
            case OpNotEq: "!=";
            case OpGt: ">";
            case OpGte: ">=";
            case OpLt: "<";
            case OpLte: "<=";
            case OpAnd: "&&&"; // Bitwise AND in Elixir uses &&&
            case OpOr: "|||"; // Bitwise OR in Elixir uses |||
            case OpXor: "^^^"; // Bitwise XOR in Elixir uses ^^^
            case OpBoolAnd: "&&"; // Boolean AND
            case OpBoolOr: "||"; // Boolean OR
            case OpShl: "<<<"; // Bitwise shift left - needs special handling
            case OpShr: ">>>"; // Bitwise shift right - needs special handling
            case OpUShr: ">>>"; // Unsigned right shift - needs special handling
            case OpMod: "rem"; // Remainder in Elixir
            case OpAssignOp(op): compileBinop(op) + "=";
            case OpInterval: ".."; // Range operator in Elixir
            case OpArrow: "->"; // Function arrow
            case OpIn: "in"; // Membership test
            case OpNullCoal: "||"; // Null coalescing -> or
        }
    }
    
    /**
     * Helper: Compile field access
     */
    private function compileFieldAccess(e: TypedExpr, fa: FieldAccess): String {
        // Check if this is a 'this' reference that should be mapped to a parameter
        var expr = switch (e.expr) {
            case TConst(TThis): 
                var mappedName = currentFunctionParameterMap.get("this");
                mappedName != null ? mappedName : compileExpression(e);
            case TLocal(v) if (v.name == "this" || v.name == "_this"):
                // Check both "this" and "_this" mappings when state threading is enabled
                var mappedName = currentFunctionParameterMap.get("this");
                if (mappedName == null && v.name == "_this") {
                    mappedName = currentFunctionParameterMap.get("_this");
                }
                mappedName != null ? mappedName : compileExpression(e);
            case _:
                compileExpression(e);
        };
        
        return switch (fa) {
            case FInstance(classType, _, classFieldRef):
                var fieldName = classFieldRef.get().name;
                var classTypeName = classType.get().name;
                
                // Special handling for String properties
                if (classTypeName == "String" && fieldName == "length") {
                    return 'String.length(${expr})';
                }
                
                // Special handling for Array properties
                if (classTypeName == "Array" && fieldName == "length") {
                    return 'length(${expr})';
                }
                
                // Special handling for length property on any object (likely Dynamic arrays)
                if (fieldName == "length") {
                    return 'length(${expr})';
                }
                
                // CRITICAL: Instance field access for struct-based classes
                // For classes compiled as structs (like JsonPrinter, StringBuf), 
                // use map access syntax, not function calls
                fieldName = NamingHelper.toSnakeCase(fieldName);
                
                // Check if this is accessing a field on an instance-based class
                var classRef = classType.get();
                if (!classRef.isExtern && !classRef.isInterface && !classRef.isAbstract) {
                    // This is a struct field access - use direct struct syntax
                    // For struct-based classes like JsonPrinter, use direct field access
                    return '${expr}.${fieldName}';
                }
                
                // Default field access for other cases
                '${expr}.${fieldName}'; // Map access syntax
                
            case FStatic(classType, classFieldRef):
                var cls = classType.get();
                var className = NamingHelper.getElixirModuleName(cls.getNameOrNative());
                // Convert field name to snake_case for static method calls
                var fieldName = NamingHelper.toSnakeCase(classFieldRef.get().name);
                
                // Special handling for Phoenix modules
                if (cls.name == "PubSub" && cls.isExtern) {
                    // PubSub references should be fully qualified
                    className = "Phoenix.PubSub";
                    // PubSub methods don't need name mapping
                }
                // Special handling for StringTools extern
                else if (cls.name == "StringTools" && cls.isExtern) {
                    className = "StringTools";
                    // Map Haxe method names to Elixir function names
                    fieldName = switch(fieldName) {
                        case "isSpace": "is_space";
                        case "urlEncode": "url_encode";
                        case "urlDecode": "url_decode";
                        case "htmlEscape": "html_escape";
                        case "htmlUnescape": "html_unescape";
                        case "startsWith": "starts_with?";
                        case "endsWith": "ends_with?";
                        case "fastCodeAt": "fast_code_at";
                        case "unsafeCodeAt": "unsafe_code_at";
                        case "isEof": "is_eof";
                        case "utf16CodePointAt": "utf16_code_point_at";
                        case "keyValueIterator": "key_value_iterator";
                        case "quoteUnixArg": "quote_unix_arg";
                        case "quoteWinArg": "quote_win_arg";
                        case "winMetaCharacters": "win_meta_characters";
                        case other: NamingHelper.toSnakeCase(other);
                    };
                }
                
                // Special handling for Option enum static access (before name conversion)
                if (className == "Option" && (fieldName == "Some" || fieldName == "None")) {
                    if (fieldName == "Some") {
                        // Some without arguments becomes a partial function
                        return "fn value -> {:ok, value} end";
                    } else if (fieldName == "None") {
                        // None becomes the atom :error
                        return ":error";
                    }
                } else {
                    fieldName = NamingHelper.getElixirFunctionName(fieldName);
                }
                
                '${className}.${fieldName}'; // Module function call
                
            case FAnon(classFieldRef):
                var fieldName = classFieldRef.get().name;
                // Special handling for length property on anonymous types
                if (fieldName == "length") {
                    return 'length(${expr})';
                }
                fieldName = NamingHelper.toSnakeCase(fieldName);
                '${expr}.${fieldName}'; // Map access
                
            case FDynamic(s):
                // Special handling for length property on Dynamic types
                if (s == "length") {
                    return 'length(${expr})';
                }
                var fieldName = NamingHelper.toSnakeCase(s);
                '${expr}.${fieldName}'; // Dynamic access
                
            case FClosure(_, classFieldRef):
                var fieldName = NamingHelper.toSnakeCase(classFieldRef.get().name);
                // Don't generate function capture syntax here - just the field access
                // Function captures should only be generated when explicitly needed
                '${expr}.${fieldName}';
                
            case FEnum(enumType, enumField):
                // Check if this is a known algebraic data type (Result, Option, etc.)
                var enumTypeRef = enumType.get();
                if (AlgebraicDataTypeCompiler.isADTType(enumTypeRef)) {
                    var compiled = AlgebraicDataTypeCompiler.compileADTFieldAccess(enumTypeRef, enumField);
                    if (compiled != null) return compiled;
                }
                
                // Fallback for regular enum types - compile to atoms, not function calls
                var fieldName = NamingHelper.toSnakeCase(enumField.name);
                ':${fieldName}';
        }
    }
    
    /**
     * Set up parameter mapping for function compilation
     */
    public function setFunctionParameterMapping(args: Array<reflaxe.data.ClassFuncArg>): Void {
        /**
         * PRESERVE CRITICAL MAPPINGS
         * 
         * WHY: We need to preserve _this -> struct mappings for state threading
         * WHAT: Save all this-related mappings before clearing
         * HOW: Save this, _this, and struct mappings, then restore after clear
         */
        // Preserve any existing 'this' mappings for struct instance methods
        var savedThisMapping = currentFunctionParameterMap.get("this");
        var savedUnderscoreThisMapping = currentFunctionParameterMap.get("_this");
        var savedStructMapping = currentFunctionParameterMap.get("struct");
        
        currentFunctionParameterMap.clear();
        inlineContextMap.clear(); // Reset inline context for new function
        isCompilingAbstractMethod = true;
        
        // Restore ALL 'this' related mappings if they existed
        if (savedThisMapping != null) {
            currentFunctionParameterMap.set("this", savedThisMapping);
        }
        if (savedUnderscoreThisMapping != null) {
            currentFunctionParameterMap.set("_this", savedUnderscoreThisMapping);
        }
        if (savedStructMapping != null) {
            currentFunctionParameterMap.set("struct", savedStructMapping);
        }
        
        if (args != null) {
            for (i in 0...args.length) {
                var arg = args[i];
                // Get the original parameter name from multiple sources
                var originalName = if (arg.tvar != null) {
                    arg.tvar.name;
                } else {
                    // Fallback to a generated name
                    'param${i}';
                }
                
                // Map the original name to the snake_case version (no more arg0/arg1!)
                var snakeCaseName = NamingHelper.toSnakeCase(originalName);
                currentFunctionParameterMap.set(originalName, snakeCaseName);
                
                // Also handle common abstract type parameter patterns
                if (originalName == "this") {
                    currentFunctionParameterMap.set("this1", snakeCaseName);
                }
            }
        }
    }
    
    
    /**
     * Get the effective variable name for 'this' references, considering inline context and LiveView
     */
    private function resolveThisReference(): String {
        // First check if we're in an inline context where struct is active
        if (stateManagementCompiler.hasInlineContext("struct")) {
            return "struct";
        }
        
        // Check if we're in a LiveView class - in this case, 'this' references are invalid
        // because LiveView instance variables should be accessed through socket.assigns
        if (liveViewInstanceVars != null) {
            // Return a special marker that indicates this should not be used directly
            return "__LIVEVIEW_THIS__";
        }
        
        // Fall back to StateManagementCompiler for general 'this' resolution
        return stateManagementCompiler.resolveThisReference();
    }
    
    /**
     * Check if a TLocal variable represents a function being passed as a reference
     * 
     * @param v The TVar representing the local variable
     * @param originalName The original name of the variable
     * @return true if this is a function reference, false otherwise
     */
    public function isFunctionReference(v: TVar, originalName: String): Bool {
        // Check if the variable's type is a function type
        switch (v.t) {
            case TFun(_, _):
                // This is definitely a function type
                return true;
            case _:
                // Check if this is a static method reference by name
                // This handles cases where the TVar type isn't TFun but it's actually a function
                if (currentClassType != null) {
                    // Look for static methods in the current class
                    var classFields = currentClassType.statics.get();
                    for (field in classFields) {
                        if (field.name == originalName && field.type.match(TFun(_, _))) {
                            return true;
                        }
                    }
                    
                    // Look for instance methods (though these are less common as references)
                    var instanceFields = currentClassType.fields.get();
                    for (field in instanceFields) {
                        if (field.name == originalName && field.type.match(TFun(_, _))) {
                            return true;
                        }
                    }
                }
                return false;
        }
    }
    
    /**
     * Generate Elixir function reference syntax for a function name
     * 
     * @param functionName The function name to create a reference for
     * @return Elixir function reference syntax like &Module.function/arity
     */
    public function generateFunctionReference(functionName: String): String {
        // Convert function name to snake_case for Elixir
        var elixirFunctionName = NamingHelper.toSnakeCase(functionName);
        
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
    private function compileBlockExpressionsWithContext(expressions: Array<TypedExpr>): Array<String> {
        return expressionVariantCompiler.compileBlockExpressionsWithContext(expressions);
    }
    
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
        isCompilingAbstractMethod = false;
    }
    
    /**
     * Compile method calls with repository operation detection
     */
    private function compileMethodCall(e: TypedExpr, args: Array<TypedExpr>): String {
        return methodCallCompiler.compileMethodCall(e, args);
    }
    
    
    
    
    
    
    
    
    
    
    /**
     * Detect and optimize Reflect.fields iteration patterns
     * 
     * Detects field copying patterns and delegates to compileReflectFieldsIteration
     * for proper Map.merge optimization when applicable, or Enum.each for complex patterns.
     */
    private function detectReflectFieldsPattern(econd: TypedExpr, ebody: TypedExpr): Null<String> {
        return patternDetectionCompiler.detectReflectFieldsPattern(econd, ebody);
    }
    private function checkForTForInExpression(expr: TypedExpr): Bool {
        return loopCompiler.checkForTForInExpression(expr);
    }
    
    /**
     * Debug helper: Check if expression contains Reflect.fields usage
     */
    private function checkForReflectFieldsInExpression(expr: TypedExpr): Bool {
        return reflectionCompiler.checkForReflectFieldsInExpression(expr);
    }
    
    /**
     * Check if expression contains TWhile nodes that generate Y combinator patterns
     * 
     * WHY: Delegates to LoopCompiler for centralized loop pattern detection and analysis
     * WHAT: Wrapper function that maintains backward compatibility while delegating
     * HOW: Simply forwards the call to loopCompiler.containsTWhileExpression()
     * 
     * This function was moved to LoopCompiler as part of loop-related logic consolidation.
     * Y combinator pattern detection is core loop compilation functionality.
     * 
     * @param expr The expression to analyze for TWhile patterns
     * @return True if expression contains any TWhile nodes
     */
    private function containsTWhileExpression(expr: TypedExpr): Bool {
        return loopCompiler.containsTWhileExpression(expr);
    }
    
    /**
     * Generate Enum.find pattern for early return loops
     */
    private function generateEnumFindPattern(arrayExpr: String, loopVar: String, ebody: TypedExpr): String {
        return arrayOptimizationCompiler.generateEnumFindPattern(arrayExpr, loopVar, ebody);
    }
    
    /**
     * Extract condition from return statement in loop body
     */
    private function extractConditionFromReturn(expr: TypedExpr): Null<String> {
        return arrayOptimizationCompiler.extractConditionFromReturn(expr);
    }
    
    /**
     * Transform loop body for find patterns with reduce_while
     */
    private function transformFindLoopBody(expr: TypedExpr, loopVar: String): String {
        return arrayOptimizationCompiler.transformFindLoopBody(expr, loopVar);
    }
    
    /**
     * Generate Enum.count pattern for conditional counting
     */
    private function generateEnumCountPattern(arrayExpr: String, loopVar: String, conditionExpr: TypedExpr): String {
        return arrayOptimizationCompiler.generateEnumCountPattern(arrayExpr, loopVar, conditionExpr);
    }
    
    /**
     * Find the first local variable referenced in an expression
     */
    private function findFirstLocalVariable(expr: TypedExpr): Null<String> {
        return arrayOptimizationCompiler.findFirstLocalVariable(expr);
    }
    
    /**
     * Find the first local TVar referenced in an expression
     * This is more robust than string-based matching as it uses object identity
     */
    private function findFirstLocalTVar(expr: TypedExpr): Null<TVar> {
        return arrayOptimizationCompiler.findFirstLocalTVar(expr);
    }
    
    /**
     * Generate Enum.filter pattern for filtering arrays
     */
    private function generateEnumFilterPattern(arrayExpr: String, loopVar: String, conditionExpr: TypedExpr): String {
        return arrayOptimizationCompiler.generateEnumFilterPattern(arrayExpr, loopVar, conditionExpr);
    }
    
    /**
     * Generate Enum.map pattern for transforming arrays
     */
    private function generateEnumMapPattern(arrayExpr: String, loopVar: String, ebody: TypedExpr): String {
        return arrayOptimizationCompiler.generateEnumMapPattern(arrayExpr, loopVar, ebody);
    }
    
    /**
     * Find the loop variable by looking for patterns like "v.field" where v is the loop variable
     */
    private function findFirstTLocalInExpression(expr: TypedExpr): Null<TVar> {
        return arrayOptimizationCompiler.findFirstTLocalInExpression(expr);
    }

    /**
     * Find TLocal from field access patterns (e.g., v.id -> return v)
     */
    private function findTLocalFromFieldAccess(expr: TypedExpr): Null<TVar> {
        return arrayOptimizationCompiler.findTLocalFromFieldAccess(expr);
    }

    /**
     * Find the first TLocal variable in an expression recursively
     */
    private function findFirstTLocalInExpressionRecursive(expr: TypedExpr): Null<TVar> {
        return arrayOptimizationCompiler.findFirstTLocalInExpressionRecursive(expr);
    }

    /**
     * Extract transformation logic from mapping body (TVar-based version)
     */
    private function extractTransformationFromBodyWithTVar(expr: TypedExpr, sourceTVar: TVar, targetVarName: String): String {
        return expressionVariantCompiler.extractTransformationFromBodyWithTVar(expr, sourceTVar, targetVarName);
    }

    /**
     * Extract transformation logic from mapping body (string-based version)
     */
    private function extractTransformationFromBody(expr: TypedExpr, sourceVar: String, targetVar: String): String {
        return expressionVariantCompiler.extractTransformationFromBody(expr, sourceVar, targetVar);
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
     * Compile expression with variable mapping for loop variable substitution.
     * 
     * This method is crucial for handling desugared Haxe code where the original
     * lambda parameter names have been replaced with compiler-generated variables.
     * It enables proper variable substitution to generate idiomatic Elixir lambdas.
     * 
     * Example: When Haxe desugars `numbers.filter(n -> n % 2 == 0)` into a complex
     * loop using variable `v`, this method substitutes `v` with `item` to produce
     * `Enum.filter(numbers, fn item -> item rem 2 == 0 end)`.
     * 
     * @param expr The expression to compile with variable substitution
     * @param sourceVar The original variable name to replace (e.g., "v")
     * @param targetVar The target variable name to use (e.g., "item")
     * @return The compiled expression with variables substituted
     */
    private function compileExpressionWithVarMapping(expr: TypedExpr, sourceVar: String, targetVar: String): String {
        return expressionVariantCompiler.compileExpressionWithVarMapping(expr, sourceVar, targetVar);
    }
    
    /**
     * Helper function to determine if a variable name represents a system/internal variable
     * that should not be substituted in loop contexts
     */
    private function isSystemVariable(varName: String): Bool {
        return arrayOptimizationCompiler.isSystemVariable(varName);
    }
    
    /**
     * Helper function to determine if a variable should be substituted in loop contexts
     * @param varName The variable name to check
     * @param sourceVar The specific source variable we're looking for (null for aggressive mode)
     * @param isAggressiveMode Whether to substitute any non-system variable
     */
    public function shouldSubstituteVariable(varName: String, sourceVar: String = null, isAggressiveMode: Bool = false): Bool {
        if (isSystemVariable(varName)) {
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
     * Compile expression with aggressive substitution for all likely loop variables
     * Used when normal loop variable detection fails
     */
    private function compileExpressionWithAggressiveSubstitution(expr: TypedExpr, targetVar: String): String {
        return expressionVariantCompiler.compileExpressionWithAggressiveSubstitution(expr, targetVar);
    }

    /**
     * Simple approach: Always substitute all TLocal variables with the target variable
     * This replaces the complex __AGGRESSIVE__ marker system with a straightforward solution
     */
    private function extractTransformationFromBodyWithAggressiveSubstitution(expr: TypedExpr, targetVar: String): String {
        return substitutionCompiler.extractTransformationFromBodyWithAggressiveSubstitution(expr, targetVar);
    }
    
    /**
     * Compile expression with variable substitution using TVar object comparison
     */
    public function compileExpressionWithTVarSubstitution(expr: TypedExpr, sourceTVar: TVar, targetVarName: String): String {
        return expressionVariantCompiler.compileExpressionWithTVarSubstitution(expr, sourceTVar, targetVarName);
    }


    /**
     * Compile while loop with variable renamings applied (DELEGATED)
     * This handles variable collisions in desugared loop code
     */
    private function compileWhileLoopWithRenamings(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool, renamings: Map<String, String>): String {
        return whileLoopCompiler.compileWhileLoopWithRenamings(econd, ebody, normalWhile, renamings);
    }
    
    /**
     * Compile expression with multiple variable renamings applied
     * This is used to handle variable collisions in desugared loop code
     */
    /**
     * DELEGATION: Variable renaming compilation (moved to SubstitutionCompiler.hx)
     * 
     * WHY: This function was 165 lines and handled complex variable renaming logic
     * that belongs in the specialized SubstitutionCompiler helper for maintainability.
     * 
     * WHAT: Delegates to SubstitutionCompiler.compileExpressionWithRenaming()
     * HOW: Simple delegation preserving the exact same public interface
     */
    public function compileExpressionWithRenaming(expr: TypedExpr, renamings: Map<String, String>): String {
        return substitutionCompiler.compileExpressionWithRenaming(expr, renamings);
    }
    
    /**
     * Compile expression with variable substitution (string-based version)
     */
    /**
     * DELEGATION: Variable substitution compilation (moved to SubstitutionCompiler.hx)
     * 
     * WHY: This function was 92 lines handling complex variable substitution logic
     * that belongs in the specialized SubstitutionCompiler helper for maintainability.
     * 
     * WHAT: Delegates to SubstitutionCompiler.compileExpressionWithSubstitution()
     * HOW: Simple delegation preserving the exact same public interface
     */
    private function compileExpressionWithSubstitution(expr: TypedExpr, sourceVar: String, targetVar: String): String {
        return substitutionCompiler.compileExpressionWithSubstitution(expr, sourceVar, targetVar);
    }
    
    /**
     * Extract variable name from condition string
     */
    private function extractVariableFromCondition(condition: String): Null<String> {
        return arrayOptimizationCompiler.extractVariableFromCondition(condition);
    }

    /**
     * Analyze range-based loop body to detect accumulation patterns
     */
    private function analyzeRangeLoopBody(ebody: TypedExpr): {
        hasSimpleAccumulator: Bool,
        accumulator: String,
        loopVar: String,
        isAddition: Bool
    } {
        return patternAnalysisCompiler.analyzeRangeLoopBody(ebody);
    }
    
    /**
     * Transform complex loop bodies that can't be simplified to Enum.reduce
     */
    private function transformComplexLoopBody(ebody: TypedExpr): String {
        return arrayOptimizationCompiler.transformComplexLoopBody(ebody);
    }
    
    /**
     * Compile a while loop to idiomatic Elixir recursive function (DELEGATED)
     * Generates proper tail-recursive patterns that handle mutable state correctly
     */
    private function compileWhileLoop(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        return whileLoopCompiler.compileWhileLoop(econd, ebody, normalWhile);
    }
    
    /**
     * Detect if a loop body is building an array (DELEGATED)
     * Returns info about the pattern if detected, null otherwise
     */
    private function detectArrayBuildingPattern(ebody: TypedExpr): Null<{indexVar: String, accumVar: String, arrayExpr: String}> {
        return whileLoopCompiler.detectArrayBuildingPattern(ebody);
    }
    
    /**
     * Compile an array-building loop pattern to idiomatic Elixir (DELEGATED)
     */
    private function compileArrayBuildingLoop(econd: TypedExpr, ebody: TypedExpr, pattern: {indexVar: String, accumVar: String, arrayExpr: String}): String {
        return whileLoopCompiler.compileArrayBuildingLoop(econd, ebody, pattern);
    }
    
    /**
     * Extract the transformation applied to array elements (DELEGATED)
     */
    private function extractArrayTransformation(ebody: TypedExpr, indexVar: String, accumVar: String): Null<String> {
        return whileLoopCompiler.extractArrayTransformation(ebody, indexVar, accumVar);
    }
    
    /**
     * Fallback generic while loop compilation (DELEGATED)
     */
    private function compileWhileLoopGeneric(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        return whileLoopCompiler.compileWhileLoopGeneric(econd, ebody, normalWhile);
    }
    
    /**
     * Extract variables that are modified within a loop body (DELEGATED)
     */
    private function extractModifiedVariables(expr: TypedExpr): Array<{name: String, type: String}> {
        return whileLoopCompiler.extractModifiedVariables(expr);
    }
    
    /**
     * Transform loop body to handle mutations functionally by returning updated state
     */
    private function transformLoopBodyMutations(expr: TypedExpr, modifiedVars: Array<{name: String, type: String}>, normalWhile: Bool, condition: String): String {
        return whileLoopCompiler.transformLoopBodyMutations(expr, modifiedVars, normalWhile, condition);
    }
    
    /**
     * Compile expression while tracking variable mutations (DELEGATED) 
     */
    private function compileExpressionWithMutationTracking(expr: TypedExpr, updates: Map<String, String>): String {
        return expressionVariantCompiler.compileExpressionWithMutationTracking(expr, updates);
    }
    
    /**
     * Check if a method name is a common array method (DELEGATED)
     */
    public function isArrayMethod(methodName: String): Bool {
        return arrayMethodCompiler.isArrayMethod(methodName);
    }
    
    /**
     * Check if a method name is a MapTools static extension method (DELEGATED)
     */
    public function isMapMethod(methodName: String): Bool {
        return mapToolsCompiler.isMapMethod(methodName);
    }
    
    /**
     * Check if a method name is an OptionTools static extension method (DELEGATED)
     */
    public function isOptionMethod(methodName: String): Bool {
        return adtMethodCompiler.isOptionMethod(methodName);
    }
    
    /**
     * Check if a method name is a ResultTools static extension method (DELEGATED)
     */
    public function isResultMethod(methodName: String): Bool {
        return adtMethodCompiler.isResultMethod(methodName);
    }
    
    /**
     * Check if an enum type has static extension methods and compile them (DELEGATED)
     * @param enumType The enum type being called on
     * @param methodName The method name being called
     * @param objStr The compiled object expression
     * @param args The method arguments
     * @return Compiled static extension call or null if not applicable
     */
    public function compileADTStaticExtension(enumType: haxe.macro.Type.EnumType, methodName: String, objStr: String, args: Array<TypedExpr>): Null<String> {
        return adtMethodCompiler.compileADTStaticExtension(enumType, methodName, objStr, args);
    }
    
    /**
     * Compile Haxe array method calls to idiomatic Elixir Enum functions (DELEGATED)
     * 
     * @param objStr The compiled array object expression
     * @param methodName The method being called (e.g., "filter", "map")
     * @param args The method arguments as TypedExpr array
     * @return The compiled Elixir method call
     */
    public function compileArrayMethod(objStr: String, methodName: String, args: Array<TypedExpr>): String {
        return arrayMethodCompiler.compileArrayMethod(objStr, methodName, args);
    }
    
    /**
     * Compile MapTools static extension methods to idiomatic Elixir Map module calls (DELEGATED)
     */
    public function compileMapMethod(objStr: String, methodName: String, args: Array<TypedExpr>): String {
        return mapToolsCompiler.compileMapMethod(objStr, methodName, args);
    }
    
    
    /**
     * Compile HXX template function calls
     * Processes hxx() calls to transform JSX-like syntax to HEEx templates
     */
    /**
     * Compile HXX.hxx() calls to Phoenix HEEx templates
     * 
     * This method delegates to HxxCompiler for sophisticated AST-based template
     * compilation that generates idiomatic ~H sigils with proper interpolation.
     */
    public function compileHxxCall(args: Array<TypedExpr>): String {
        if (args.length != 1) {
            Context.error("hxx() expects exactly one string argument", Context.currentPos());
        }
        
        // Delegate to HxxCompiler for comprehensive AST-based template compilation
        return HxxCompiler.compileHxxTemplate(args[0]);
    }
    
    /**
     * Compile String method calls to Elixir equivalents
     */
    private function compileStringMethod(objStr: String, methodName: String, args: Array<TypedExpr>): String {
        var compiledArgs = args.map(arg -> compileExpression(arg));
        
        return switch (methodName) {
            case "charCodeAt":
                // s.charCodeAt(pos) → String.to_charlist(s) |> Enum.at(pos) 
                if (compiledArgs.length > 0) {
                    'case String.at(${objStr}, ${compiledArgs[0]}) do nil -> nil; c -> :binary.first(c) end';
                } else {
                    'nil';
                }
            case "charAt":
                // s.charAt(pos) → String.at(s, pos)
                if (compiledArgs.length > 0) {
                    'String.at(${objStr}, ${compiledArgs[0]})';
                } else {
                    '""';
                }
            case "toLowerCase":
                'String.downcase(${objStr})';
            case "toUpperCase":
                'String.upcase(${objStr})';
            case "substr" | "substring":
                // Handle substr/substring with Elixir's String.slice
                if (compiledArgs.length >= 2) {
                    'String.slice(${objStr}, ${compiledArgs[0]}, ${compiledArgs[1]})';
                } else if (compiledArgs.length == 1) {
                    'String.slice(${objStr}, ${compiledArgs[0]}..-1)';
                } else {
                    objStr;
                }
            case "indexOf":
                // s.indexOf(substr) → find index or -1
                if (compiledArgs.length > 0) {
                    'case :binary.match(${objStr}, ${compiledArgs[0]}) do {pos, _} -> pos; :nomatch -> -1 end';
                } else {
                    '-1';
                }
            case "split":
                if (compiledArgs.length > 0) {
                    'String.split(${objStr}, ${compiledArgs[0]})';
                } else {
                    '[${objStr}]';
                }
            case "trim":
                'String.trim(${objStr})';
            case "length":
                'String.length(${objStr})';
            case _:
                // Default: try to call as a regular method (might fail at runtime)
                '${objStr}.${methodName}(${compiledArgs.join(", ")})';
        };
    }
    
    /**
     * Detect schema name from repository operation arguments
     */
    private function detectSchemaFromArgs(args: Array<TypedExpr>): Null<String> {
        return patternAnalysisCompiler.detectSchemaFromArgs(args);
    }
    
    /**
     * Get field name from field access
     * Handles @:native annotations on extern methods
     */
    public function getFieldName(fa: FieldAccess): String {
        return switch (fa) {
            case FInstance(_, _, cf) | FStatic(_, cf) | FClosure(_, cf): 
                var field = cf.get();
                // Check for @:native annotation on the method
                if (field.meta != null && field.meta.has(":native")) {
                    var nativeMeta = field.meta.extract(":native");
                    if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                        // Extract the native name from the annotation
                        var nativeName = switch(nativeMeta[0].params[0].expr) {
                            case EConst(CString(s, _)): s;
                            default: field.name;
                        };
                        return nativeName;
                    }
                }
                // Convert method name to snake_case for Elixir
                return NamingHelper.toSnakeCase(field.name);
            case FAnon(cf): 
                var field = cf.get();
                // Check for @:native annotation on anonymous fields too
                if (field.meta != null && field.meta.has(":native")) {
                    var nativeMeta = field.meta.extract(":native");
                    if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                        var nativeName = switch(nativeMeta[0].params[0].expr) {
                            case EConst(CString(s, _)): s;
                            default: field.name;
                        };
                        return nativeName;
                    }
                }
                // Convert method name to snake_case for Elixir
                return NamingHelper.toSnakeCase(field.name);
            case FDynamic(s): NamingHelper.toSnakeCase(s);
            case FEnum(_, ef): NamingHelper.toSnakeCase(ef.name);
        };
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
        if (fields == null || fields.length == 0) return false;
        
        var fieldNames = fields.map(f -> f.name);
        
        // Only use atom keys for the most obvious OTP supervisor option pattern
        // This requires all three supervisor configuration fields to be present
        var supervisorFields = ["strategy", "max_restarts", "max_seconds"];
        var hasAllSupervisorFields = true;
        for (field in supervisorFields) {
            if (fieldNames.indexOf(field) == -1) {
                hasAllSupervisorFields = false;
                break;
            }
        }
        
        if (hasAllSupervisorFields && fieldNames.length == 3) {
            // Verify all field names can be atoms
            for (field in fields) {
                if (!isValidAtomName(field.name)) {
                    return false;
                }
            }
            return true;
        }
        
        // Check for Phoenix.PubSub configuration pattern
        // Objects with just a "name" field are typically PubSub configs
        if (fieldNames.length == 1 && fieldNames[0] == "name") {
            return isValidAtomName("name");
        }
        
        // Default to string keys for all other cases
        // This is safer and more predictable than trying to guess OTP patterns
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
     * Analyze child spec structure to determine the appropriate output format
     * 
     * This replaces hardcoded module name detection with structural analysis:
     * - Minimal specs (only id + start) → ModernTuple format
     * - Specs with restart/shutdown/type → TraditionalMap format
     * - Simple module reference → SimpleModule format
     */
    private function analyzeChildSpecStructure(compiledFields: Map<String, String>): String {
        return patternAnalysisCompiler.analyzeChildSpecStructure(compiledFields);
    }
    
    /**
     * Check if a start field follows simple patterns suitable for modern tuple format
     */
    private function hasSimpleStartPattern(startField: String): Bool {
        return patternAnalysisCompiler.hasSimpleStartPattern(startField);
    }
    
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
     * Compile a child spec object to proper Elixir child specification format
     * Converts from Haxe objects to Elixir maps as expected by Supervisor.start_link
     */
    public function compileChildSpec(fields: Array<{name: String, expr: TypedExpr}>, classType: Null<ClassType>): String {
        var compiledFields = new Map<String, String>();
        
        // Get app name from annotation at compile time
        var appName = AnnotationSystem.getEffectiveAppName(classType);
        
        // Extract all fields from the child spec object
        for (field in fields) {
            switch (field.name) {
                case "id":
                    var idValue = compileExpression(field.expr);
                    // Handle temp variables from ternary expressions
                    if (idValue.indexOf("temp_") != -1 || idValue.indexOf("temp") == 0) {
                        // This is typically id != null ? id : module
                        // Generate an inline ternary in Elixir
                        compiledFields.set("id", "if(id != nil, do: id, else: module)");
                    } else {
                        // Normal id value - resolve app name interpolation
                        idValue = resolveAppNameInString(idValue, appName);
                        compiledFields.set("id", idValue);
                    }
                    
                case "start":
                    // Handle start object with module, function, args
                    switch (field.expr.expr) {
                        case TObjectDecl(startFields):
                            var startValues = new Map<String, String>();
                            for (startField in startFields) {
                                var value = compileExpression(startField.expr);
                                switch (startField.name) {
                                    case "module":
                                        value = resolveAppNameInString(value, appName);
                                        startValues.set("module", value);
                                    case "func":
                                        value = value.split('"').join(''); // Remove quotes
                                        startValues.set("func", ':${value}'); // Convert to atom
                                    case "args":
                                        value = resolveAppNameInString(value, appName);
                                        startValues.set("args", value);
                                }
                            }
                            // Generate start tuple {module, func, args}
                            var moduleVal = startValues.get("module") != null ? startValues.get("module") : "module";
                            var funcVal = startValues.get("func") != null ? startValues.get("func") : ":start_link";
                            var argsVal = startValues.get("args") != null ? startValues.get("args") : "[]";
                            compiledFields.set("start", '{${moduleVal}, ${funcVal}, ${argsVal}}');
                        case _:
                            // If start is not an object, compile as-is
                            var startExpr = compileExpression(field.expr);
                            startExpr = resolveAppNameInString(startExpr, appName);
                            compiledFields.set("start", startExpr);
                    }
                    
                case "restart":
                    var restartValue = compileExpression(field.expr);
                    // Convert enum values to atoms
                    if (restartValue.indexOf("Permanent") != -1) {
                        compiledFields.set("restart", ":permanent");
                    } else if (restartValue.indexOf("Temporary") != -1) {
                        compiledFields.set("restart", ":temporary");
                    } else if (restartValue.indexOf("Transient") != -1) {
                        compiledFields.set("restart", ":transient");
                    } else {
                        compiledFields.set("restart", restartValue);
                    }
                    
                case "shutdown":
                    var shutdownValue = compileExpression(field.expr);
                    // Convert enum values to atoms or numbers
                    if (shutdownValue.indexOf("Brutal") != -1) {
                        compiledFields.set("shutdown", ":brutal_kill");
                    } else if (shutdownValue.indexOf("Infinity") != -1) {
                        compiledFields.set("shutdown", ":infinity");
                    } else if (shutdownValue.indexOf("Timeout") != -1) {
                        // Extract timeout value from Timeout(5000) pattern
                        var timeoutPattern = ~/Timeout\((\d+)\)/;
                        if (timeoutPattern.match(shutdownValue)) {
                            var timeoutMs = timeoutPattern.matched(1);
                            compiledFields.set("shutdown", timeoutMs);
                        } else {
                            compiledFields.set("shutdown", "5000"); // Default timeout
                        }
                    } else {
                        compiledFields.set("shutdown", shutdownValue);
                    }
                    
                case "type":
                    var typeValue = compileExpression(field.expr);
                    // Convert enum values to atoms
                    if (typeValue.indexOf("Worker") != -1) {
                        compiledFields.set("type", ":worker");
                    } else if (typeValue.indexOf("Supervisor") != -1) {
                        compiledFields.set("type", ":supervisor");
                    } else {
                        compiledFields.set("type", typeValue);
                    }
                    
                case "modules":
                    var modulesValue = compileExpression(field.expr);
                    // modules should be an array, resolve app name in module references
                    modulesValue = resolveAppNameInString(modulesValue, appName);
                    compiledFields.set("modules", modulesValue);
            }
        }
        
        // Use structure-based detection instead of hardcoded module names
        var idField = compiledFields.get("id") != null ? compiledFields.get("id") : "module";
        var startField = compiledFields.get("start") != null ? compiledFields.get("start") : '{module, :start_link, []}';
        
        // Analyze child spec structure to determine output format
        var specFormat = analyzeChildSpecStructure(compiledFields);
        
        switch (specFormat) {
            case MODERN_TUPLE:
                return generateModernTupleFormat(idField, startField, appName);
            case SIMPLE_MODULE:
                return generateSimpleModuleFormat(idField, appName);
            case TRADITIONAL_MAP:
                // Fall through to map generation below
        }
        
        // Default: use traditional map format for non-Phoenix modules
        var mapFields = [];
        mapFields.push('id: ${idField}');
        mapFields.push('start: ${startField}');
        
        // Optional fields
        if (compiledFields.get("restart") != null) {
            mapFields.push('restart: ${compiledFields.get("restart")}');
        }
        if (compiledFields.get("shutdown") != null) {
            mapFields.push('shutdown: ${compiledFields.get("shutdown")}');
        }
        if (compiledFields.get("type") != null) {
            mapFields.push('type: ${compiledFields.get("type")}');
        }
        if (compiledFields.get("modules") != null) {
            mapFields.push('modules: ${compiledFields.get("modules")}');
        }
        
        return '%{${mapFields.join(", ")}}';
    }
    
    /**
     * Resolve app name interpolation in a string at compile time
     * Handles patterns like: '"" <> app_name <> ".Repo"' -> 'TodoApp.Repo'
     */
    private function resolveAppNameInString(str: String, appName: String): String {
        if (str == null) return "";
        
        // Remove outer quotes
        str = str.split('"').join('');
        
        // Handle common interpolation patterns from Haxe string interpolation
        str = str.replace('" <> app_name <> "', appName);
        str = str.replace('${appName}', appName);
        str = str.replace('app_name', appName);
        
        // Clean up any remaining empty string concatenations
        str = str.replace('" <> "', '');
        str = str.replace(' <> ', '');
        
        return str;
    }
    
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
     * Compile supervisor options object to proper Elixir keyword list format
     * Converts from Haxe objects to Elixir keyword lists as expected by Supervisor.start_link
     */
    public function compileSupervisorOptions(fields: Array<{name: String, expr: TypedExpr}>, classType: Null<ClassType>): String {
        var strategy = "one_for_one";
        var name = "";
        
        // Get app name from annotation at compile time
        var appName = AnnotationSystem.getEffectiveAppName(classType);
        
        // Extract fields from the supervisor options object
        for (field in fields) {
            switch (field.name) {
                case "strategy":
                    strategy = compileExpression(field.expr);
                    strategy = strategy.split('"').join(''); // Remove quotes
                    
                    // Remove leading colon if present (enum values already include it)
                    if (strategy.startsWith(":")) {
                        strategy = strategy.substring(1);
                    }
                    
                case "name":
                    name = compileExpression(field.expr);
                    name = resolveAppNameInString(name, appName);
            }
        }
        
        // If no name was specified, generate default supervisor name
        if (name == "") {
            name = '${appName}.Supervisor';
        }
        
        // Generate proper Elixir keyword list
        var options = [];
        
        // Convert strategy to atom
        options.push('strategy: :${strategy}');
        
        // Add supervisor name
        options.push('name: ${name}');
        
        return '[${options.join(", ")}]';
    }
    
    /**
     * Check if this is a call to elixir.Syntax static methods
     * 
     * @param obj The object expression (should be TTypeExpr for elixir.Syntax)
     * @param fieldName The method name being called
     * @return true if this is an elixir.Syntax call
     */
    public function isElixirSyntaxCall(obj: TypedExpr, fieldName: String): Bool {
        return methodCallCompiler.isElixirSyntaxCall(obj, fieldName);
    }
    
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
    public function compileElixirSyntaxCall(methodName: String, args: Array<TypedExpr>): String {
        return methodCallCompiler.compileElixirSyntaxCall(methodName, args);
    }
    
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
    
    /**
     * Extract field update information from a field assignment expression
     * Returns: "field_name: new_value" for struct update syntax
     */
    private function extractFieldUpdate(expr: TypedExpr): Null<String> {
        return switch (expr.expr) {
            case TBinop(OpAssign, e1, e2):
                switch (e1.expr) {
                    case TField(e, fa):
                        var fieldName = switch (fa) {
                            case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf): cf.get().name;
                            case _: null;
                        };
                        if (fieldName != null) {
                            var value = compileExpression(e2);
                            var elixirFieldName = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(fieldName);
                            '${elixirFieldName}: ${value}';
                        } else {
                            null;
                        }
                    case _: null;
                }
            case _: null;
        };
    }
    
    /**
     * Detect temp variable patterns: temp_var = nil; case...; temp_var
     * Returns the temp variable name if pattern is detected, null otherwise.
     */
    private function detectTempVariablePattern(expressions: Array<TypedExpr>): Null<String> {
        return tempVariableOptimizer.detectTempVariablePattern(expressions);
    }
    
    /**
     * Optimize temp variable pattern to idiomatic case expression
     */
    private function optimizeTempVariablePattern(tempVarName: String, expressions: Array<TypedExpr>): String {
        return tempVariableOptimizer.optimizeTempVariablePattern(tempVarName, expressions);
    }
    
    /**
     * Fix temp variable scoping issues in compiled Elixir code
     * Transforms: if (cond), do: temp_var = val1, else: temp_var = val2\nvar = temp_var
     * Into: var = if (cond), do: val1, else: val2
     */
    private function fixTempVariableScoping(code: String, tempVarName: String): String {
        return tempVariableOptimizer.fixTempVariableScoping(code, tempVarName);
    }
    
    /**
     * Extract the value being assigned to a temp variable
     * Looks for patterns like: temp_var = actual_value
     */
    private function extractValueFromTempAssignment(expr: TypedExpr, tempVarName: String): Null<String> {
        if (expr == null) return null;
        return switch (expr.expr) {
            case TBinop(OpAssign, lhs, rhs):
                // Check if left side is our temp variable
                switch (lhs.expr) {
                    case TLocal(v):
                        var varName = getOriginalVarName(v);
                        if (varName == tempVarName) {
                            // Return the actual value being assigned
                            return compileExpression(rhs);
                        }
                    case _:
                }
                
                // Also check nested blocks and expressions
                var rhsResult = extractValueFromTempAssignment(rhs, tempVarName);
                if (rhsResult != null) return rhsResult;
                
                var lhsResult = extractValueFromTempAssignment(lhs, tempVarName);
                if (lhsResult != null) return lhsResult;
                
                null;
            case TBlock(expressions):
                // Look inside block expressions for the assignment
                for (e in expressions) {
                    var result = extractValueFromTempAssignment(e, tempVarName);
                    if (result != null) return result;
                }
                null;
            case TIf(condition, thenExpr, elseExpr):
                // Also check inside if expressions
                var thenResult = extractValueFromTempAssignment(thenExpr, tempVarName);
                if (thenResult != null) return thenResult;
                
                var elseResult = extractValueFromTempAssignment(elseExpr, tempVarName);
                if (elseResult != null) return elseResult;
                
                null;
            case _:
                null;
        };
    }
    
    /**
     * Check if expression uses a temp variable (like v = temp_var)
     */
    private function isTempVariableUsage(expr: TypedExpr, tempVarName: String): Bool {
        return switch (expr.expr) {
            case TBinop(OpAssign, lhs, rhs):
                // Check if right side uses our temp variable
                switch (rhs.expr) {
                    case TLocal(v):
                        var varName = getOriginalVarName(v);
                        return varName == tempVarName;
                    case _:
                        return false;
                }
            case _:
                return false;
        };
    }
    
    /**
     * Detect if both branches of TIf assign to the same temp variable
     * Returns {varName: String} if pattern detected, null otherwise
     */
    private function detectTempVariableAssignmentPattern(ifBranch: TypedExpr, elseBranch: Null<TypedExpr>): Null<{varName: String}> {
        return tempVariableOptimizer.detectTempVariableAssignmentPattern(ifBranch, elseBranch);
    }
    
    /**
     * Extract the variable name from an assignment expression
     */
    private function getAssignmentVariable(expr: TypedExpr): Null<String> {
        return patternAnalysisCompiler.getAssignmentVariable(expr);
    }
    
    /**
     * Extract the value being assigned in an assignment expression
     */
    private function extractAssignmentValue(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TBinop(OpAssign, lhs, rhs):
                compileExpression(rhs);
            case _:
                compileExpression(expr);
        };
    }
    
    /**
     * Detect temp variable assignment sequence in a block of expressions
     * Pattern: TIf with temp assignments in both branches + TBinop assignment using temp var
     */
    private function detectTempVariableAssignmentSequence(expressions: Array<TypedExpr>): Null<{ifIndex: Int, assignIndex: Int, tempVar: String, targetVar: String}> {
        return tempVariableOptimizer.detectTempVariableAssignmentSequence(expressions);
    }
    
    /**
     * Optimize temp variable assignment sequence
     */
    private function optimizeTempVariableAssignmentSequence(sequence: {ifIndex: Int, assignIndex: Int, tempVar: String, targetVar: String}, expressions: Array<TypedExpr>): String {
        return tempVariableOptimizer.optimizeTempVariableAssignmentSequence(sequence, expressions);
    }
    
    /**
     * Get the target variable from an assignment expression (like v = temp_var)
     */
    private function getTargetVariableFromAssignment(expr: TypedExpr): Null<String> {
        return switch (expr.expr) {
            case TBinop(OpAssign, lhs, rhs):
                // Get the left-hand side variable
                switch (lhs.expr) {
                    case TLocal(v):
                        return getOriginalVarName(v);
                    case TField(e, field):
                        var objCompiled = compileExpression(e);
                        return objCompiled; // For field access like struct.field
                    case _:
                        return null;
                }
            case _:
                return null;
        };
    }
    
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
    public function isTypeSafeChildSpecCall(obj: TypedExpr, fieldName: String): Bool {
        return methodCallCompiler.isTypeSafeChildSpecCall(obj, fieldName);
    }
    
    /**
     * Compile TypeSafeChildSpec enum constructor calls directly to ChildSpec format
     */
    public function compileTypeSafeChildSpecCall(fieldName: String, args: Array<TypedExpr>): String {
        return methodCallCompiler.compileTypeSafeChildSpecCall(fieldName, args);
    }
    
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
        return yCombinatorCompiler.detectYCombinatorInAST(expr);
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
    private function hasReflectFieldsIteration(expressions: Array<TypedExpr>): Bool {
        return reflectionCompiler.hasReflectFieldsIteration(expressions);
    }

    /**
     * Override called after all files have been generated by DirectToStringCompiler.
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