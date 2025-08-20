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
import reflaxe.elixir.helpers.EctoErrorReporter;
import reflaxe.elixir.helpers.TypedefCompiler;
import reflaxe.elixir.helpers.HxxCompiler;
import reflaxe.elixir.helpers.LLMDocsGenerator;
import reflaxe.elixir.helpers.ExUnitCompiler;
import reflaxe.elixir.helpers.AlgebraicDataTypeCompiler;
import reflaxe.elixir.helpers.ExpressionCompiler;
import reflaxe.elixir.ElixirTyper;
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
 * @see documentation/ARCHITECTURE.md Complete architectural overview
 * @see documentation/TESTING.md Testing methodology and patterns
 */
class ElixirCompiler extends DirectToStringCompiler {
    
    // File extension for generated Elixir files
    public var fileExtension: String = ".ex";
    
    // Output directory for generated files (dynamically set by Reflaxe)
    public var outputDirectory: String = "lib/";
    
    // Type mapping system for enhanced enum compilation
    private var typer: reflaxe.elixir.ElixirTyper;
    
    // Context tracking for variable substitution
    private var isInLoopContext: Bool = false;
    
    // Pattern matching and guard compilation helpers
    private var patternMatcher: reflaxe.elixir.helpers.PatternMatcher;
    private var guardCompiler: reflaxe.elixir.helpers.GuardCompiler;
    
    // Pipeline optimization for idiomatic Elixir code generation
    private var pipelineOptimizer: reflaxe.elixir.helpers.PipelineOptimizer;
    
    // Import optimization for clean import statements
    private var importOptimizer: reflaxe.elixir.helpers.ImportOptimizer;
    
    // Source mapping support for debugging and LLM workflows
    private var currentSourceMapWriter: Null<SourceMapWriter> = null;
    private var sourceMapOutputEnabled: Bool = false;
    private var pendingSourceMapWriters: Array<SourceMapWriter> = [];
    
    // Parameter mapping system for abstract type implementation methods
    private var currentFunctionParameterMap: Map<String, String> = new Map();
    
    // Track inline function context across multiple expressions in a block
    // Maps inline variable names (like "struct") to their assigned values (like "struct.buf")
    private var inlineContextMap: Map<String, String> = new Map<String, String>();
    private var isCompilingAbstractMethod: Bool = false;
    private var isCompilingCaseArm: Bool = false;
    
    // Current class context for app name resolution and other class-specific operations
    private var currentClassType: Null<ClassType> = null;
    
    // Track instance variable names for LiveView classes to generate socket.assigns references
    private var liveViewInstanceVars: Null<Map<String, Bool>> = null;
    
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
    private function getCurrentAppName(): String {
        // Priority 1: Check compiler define (most explicit and single-source-of-truth)
        // IMPORTANT: Use Context.definedValue() in macro context, NOT Compiler.getDefine()
        // Compiler.getDefine() is a macro function meant for regular code generation
        #if app_name
        var defineValue = haxe.macro.Context.definedValue("app_name");
        if (defineValue != null && defineValue.length > 0) {
            return defineValue;
        }
        #end
        
        // Priority 2: Check current class annotation
        if (this.currentClassType != null) {
            var annotatedName = AnnotationSystem.getAppName(this.currentClassType);
            if (annotatedName != null) {
                return annotatedName;
            }
        }
        
        // Priority 3: Check global registry (if any class had @:appName)
        var globalName = AnnotationSystem.getGlobalAppName();
        if (globalName != null) {
            return globalName;
        }
        
        // Priority 4: Try to infer from class name
        if (this.currentClassType != null) {
            var className = this.currentClassType.name;
            if (className.endsWith("App")) {
                return className;
            }
        }
        
        // Priority 5: Ultimate fallback
        return "App";
    }
    
    /**
     * Replace getAppName() calls with the actual app name from the annotation
     * This post-processing step enables dynamic app name injection in generated code
     */
    private function replaceAppNameCalls(code: String, classType: ClassType): String {
        var appName = AnnotationSystem.getEffectiveAppName(classType);
        
        // Replace direct getAppName() calls - these become simple string literals
        code = code.replace('getAppName()', '"${appName}"');
        
        // Replace method calls like MyClass.getAppName() (camelCase version)
        code = ~/([A-Za-z0-9_]+)\.getAppName\(\)/g.replace(code, '"${appName}"');
        
        // Replace method calls like MyClass.get_app_name() (snake_case version)
        code = ~/([A-Za-z0-9_]+)\.get_app_name\(\)/g.replace(code, '"${appName}"');
        
        // Fix any cases where we ended up with Module."AppName" syntax (invalid)
        // This handles cases where method replacement created invalid syntax
        code = ~/([A-Za-z0-9_]+)\."([^"]+)"/g.replace(code, '"$2"');
        
        return code;
    }
    
    /**
     * Initialize source map writer for a specific output file
     */
    private function initSourceMapWriter(outputPath: String): Void {
        if (!sourceMapOutputEnabled) return;
        
        currentSourceMapWriter = new SourceMapWriter(outputPath);
        pendingSourceMapWriters.push(currentSourceMapWriter);
    }
    
    /**
     * Finalize source map writer and generate .ex.map file
     */
    private function finalizeSourceMapWriter(): Null<String> {
        if (!sourceMapOutputEnabled || currentSourceMapWriter == null) return null;
        
        var sourceMapPath = currentSourceMapWriter.generateSourceMap();
        currentSourceMapWriter = null;
        return sourceMapPath;
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
    private function getOriginalVarName(v: TVar): String {
        // Check if the variable has :realPath metadata
        // TVar has both name and meta properties, so we can use the helper
        return v.getNameOrMeta(":realPath");
    }
    
    /**
     * Determine which statement indices were processed as part of a pipeline pattern.
     * This prevents double-compilation of statements that were already included in the pipeline.
     */
    private function getProcessedStatementIndices(statements: Array<TypedExpr>, pattern: PipelinePattern): Array<Int> {
        var processedIndices = [];
        var targetVariable = pattern.variable;
        
        // Find all statements that operate on the pipeline variable
        for (i in 0...statements.length) {
            var stmt = statements[i];
            if (statementTargetsVariable(stmt, targetVariable)) {
                processedIndices.push(i);
            }
        }
        
        return processedIndices;
    }
    
    /**
     * Check if a statement targets a specific variable (used for pipeline detection).
     * Excludes terminal operations that consume but don't transform the variable.
     */
    private function statementTargetsVariable(stmt: TypedExpr, variableName: String): Bool {
        // Skip terminal operations - they consume the variable but aren't part of the pipeline
        if (isTerminalOperation(stmt, variableName)) {
            return false;
        }
        
        return switch(stmt.expr) {
            case TVar(v, init) if (init != null):
                // var x = f(x, ...) pattern
                var varName = v.name;
                if (varName == variableName) {
                    // Check if the init expression uses the same variable
                    containsVariableReference(init, variableName);
                } else {
                    false;
                }
                
            case TBinop(OpAssign, {expr: TLocal(v)}, right):
                // x = f(x, ...) pattern
                var varName = v.name;
                if (varName == variableName) {
                    // Check if the right side uses the same variable
                    containsVariableReference(right, variableName);
                } else {
                    false;
                }
                
            default:
                false;
        }
    }
    
    /**
     * Check if a statement is a terminal operation that consumes a pipeline variable
     * but doesn't transform it (like Repo.all, Repo.one, etc.)
     */
    private function isTerminalOperation(stmt: TypedExpr, variableName: String): Bool {
        return switch(stmt.expr) {
            case TCall(funcExpr, args):
                // Check for Repo operations or other terminal functions
                var funcName = extractFunctionNameFromCall(funcExpr);
                var terminalFunctions = ["Repo.all", "Repo.one", "Repo.get", "Repo.insert", "Repo.update", "Repo.delete"];
                
                if (terminalFunctions.indexOf(funcName) >= 0) {
                    // Check if first argument references our variable
                    if (args.length > 0) {
                        containsVariableReference(args[0], variableName);
                    } else {
                        false;
                    }
                } else {
                    false;
                }
                
            default:
                false;
        }
    }
    
    /**
     * Check if an expression (typically from a TReturn) is a terminal operation on a specific variable
     */
    private function isTerminalOperationOnVariable(expr: TypedExpr, variableName: String): Bool {
        return switch(expr.expr) {
            case TCall(funcExpr, args):
                // Check for Repo operations or other terminal functions
                var funcName = extractFunctionNameFromCall(funcExpr);
                var terminalFunctions = ["Repo.all", "Repo.one", "Repo.get", "Repo.insert", "Repo.update", "Repo.delete"];
                
                if (terminalFunctions.indexOf(funcName) >= 0) {
                    // Check if first argument references our variable
                    if (args.length > 0) {
                        containsVariableReference(args[0], variableName);
                    } else {
                        false;
                    }
                } else {
                    false;
                }
                
            default:
                false;
        }
    }
    
    /**
     * Extract the terminal function call from an expression, removing the pipeline variable reference
     * For example: Repo.all(query) becomes "Repo.all()"
     */
    private function extractTerminalCall(expr: TypedExpr, variableName: String): Null<String> {
        return switch(expr.expr) {
            case TCall(funcExpr, args):
                // Check for Repo operations or other terminal functions
                var funcName = extractFunctionNameFromCall(funcExpr);
                var terminalFunctions = ["Repo.all", "Repo.one", "Repo.get", "Repo.insert", "Repo.update", "Repo.delete"];
                
                if (terminalFunctions.indexOf(funcName) >= 0) {
                    // Check if first argument references our variable
                    if (args.length > 0 && containsVariableReference(args[0], variableName)) {
                        // Extract remaining arguments (if any) after the pipeline variable
                        var remainingArgs = [];
                        for (i in 1...args.length) {
                            remainingArgs.push(compileExpression(args[i]));
                        }
                        
                        // Generate the terminal function call
                        if (remainingArgs.length > 0) {
                            return funcName + "(" + remainingArgs.join(", ") + ")";
                        } else {
                            return funcName + "()";
                        }
                    }
                }
                null;
                
            default:
                null;
        }
    }
    
    /**
     * Extract function name from a call expression
     */
    private function extractFunctionNameFromCall(funcExpr: TypedExpr): String {
        return switch(funcExpr.expr) {
            case TField({expr: TLocal({name: moduleName})}, fa):
                // Module.function pattern (e.g., Repo.all)
                var funcName = switch(fa) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                        cf.get().name;
                    case FDynamic(s):
                        s;
                    case FEnum(_, ef):
                        ef.name;
                };
                moduleName + "." + funcName;
                
            case TField({expr: TTypeExpr(moduleType)}, fa):
                // Type.function pattern (for static calls like Repo.all)
                switch(fa) {
                    case FStatic(classRef, cf):
                        // For static calls, get the module name from the class
                        var moduleName = switch(classRef.get().name) {
                            case "Repo": "Repo";  // Special case for Repo
                            case name: NamingHelper.toSnakeCase(name);
                        };
                        // Convert method name to snake_case for Elixir
                        var methodName = NamingHelper.toSnakeCase(cf.get().name);
                        moduleName + "." + methodName;
                    case FInstance(_, _, cf) | FAnon(cf) | FClosure(_, cf):
                        cf.get().name;
                    case FDynamic(s):
                        s;
                    case FEnum(_, ef):
                        ef.name;
                };
                
            case TLocal({name: funcName}):
                // Simple function call
                funcName;
                
            case TField(_, fa):
                // Method call without module
                switch(fa) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                        cf.get().name;
                    case FDynamic(s):
                        s;
                    case FEnum(_, ef):
                        ef.name;
                };
                
            default:
                "";
        }
    }

    /**
     * Check if an expression contains a reference to a specific variable.
     */
    private function containsVariableReference(expr: TypedExpr, variableName: String): Bool {
        return switch(expr.expr) {
            case TLocal(v):
                v.name == variableName;
                
            case TCall(func, args):
                // Check if first argument is the target variable
                if (args.length > 0 && containsVariableReference(args[0], variableName)) {
                    true;
                } else {
                    // Check other arguments and function
                    var foundInFunc = containsVariableReference(func, variableName);
                    var foundInArgs = false;
                    for (arg in args) {
                        if (containsVariableReference(arg, variableName)) {
                            foundInArgs = true;
                            break;
                        }
                    }
                    foundInFunc || foundInArgs;
                }
                
            case TBinop(_, e1, e2):
                containsVariableReference(e1, variableName) || containsVariableReference(e2, variableName);
                
            case TField(e, _):
                containsVariableReference(e, variableName);
                
            case TParenthesis(e):
                containsVariableReference(e, variableName);
                
            default:
                false;
        }
    }
    
    /**
     * Detect if a LiveView class uses Phoenix CoreComponents
     * Simple heuristic: assumes CoreComponents are used if this is a LiveView class
     */
    private function detectCoreComponentsUsage(classType: ClassType, funcFields: Array<ClassFuncData>): Bool {
        // For now, use a simple heuristic: all LiveView classes likely use CoreComponents
        // A more sophisticated implementation would analyze the function bodies for component calls
        // but that requires complex AST traversal which is beyond the current scope
        return classType.meta.has(":liveview");
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
    private function generateAnnotationAwareOutputPath(classType: ClassType, outputDir: String): String {
        var className = classType.name;
        
        // Detect framework annotations using existing AnnotationSystem
        var annotationInfo = reflaxe.elixir.helpers.AnnotationSystem.detectAnnotations(classType);
        
        if (annotationInfo.primaryAnnotation == null) {
            // No framework annotation - use default snake_case mapping with package-to-directory conversion
            return haxe.io.Path.join([outputDir, convertPackageToDirectoryPath(classType) + fileExtension]);
        }
        
        // Generate framework-specific paths based on annotation
        return switch (annotationInfo.primaryAnnotation) {
            case ":router":
                generatePhoenixRouterPath(className, outputDir);
            case ":liveview":
                generatePhoenixLiveViewPath(className, outputDir);
            case ":controller":
                generatePhoenixControllerPath(className, outputDir);
            case ":schema":
                generatePhoenixSchemaPath(className, outputDir);
            case ":endpoint":
                // Use default snake_case mapping for @:endpoint - no special Phoenix path needed
                haxe.io.Path.join([outputDir, convertPackageToDirectoryPath(classType) + fileExtension]);
            case _:
                // Unknown annotation - use default snake_case mapping with package-to-directory conversion
                haxe.io.Path.join([outputDir, convertPackageToDirectoryPath(classType) + fileExtension]);
        }
    }
    
    /**
     * Generate Phoenix router path: TodoAppRouter → /lib/todo_app_web/router.ex
     */
    private function generatePhoenixRouterPath(className: String, outputDir: String): String {
        var appName = extractAppName(className);
        var phoenixPath = '${appName}_web/router${fileExtension}';
        return haxe.io.Path.join([outputDir, phoenixPath]);
    }
    
    /**
     * Generate Phoenix LiveView path: UserLive → /lib/app_web/live/user_live.ex
     */
    private function generatePhoenixLiveViewPath(className: String, outputDir: String): String {
        var appName = extractAppName(className);
        var liveViewName = NamingHelper.toSnakeCase(className.replace("Live", ""));
        var phoenixPath = '${appName}_web/live/${liveViewName}_live${fileExtension}';
        return haxe.io.Path.join([outputDir, phoenixPath]);
    }
    
    /**
     * Generate Phoenix controller path: UserController → /lib/app_web/controllers/user_controller.ex
     */
    private function generatePhoenixControllerPath(className: String, outputDir: String): String {
        var appName = extractAppName(className);
        var controllerName = NamingHelper.toSnakeCase(className);
        var phoenixPath = '${appName}_web/controllers/${controllerName}${fileExtension}';
        return haxe.io.Path.join([outputDir, phoenixPath]);
    }
    
    /**
     * Generate Phoenix schema path: User → /lib/app/schemas/user.ex
     */
    private function generatePhoenixSchemaPath(className: String, outputDir: String): String {
        var appName = extractAppName(className);
        var schemaName = NamingHelper.toSnakeCase(className);
        var phoenixPath = '${appName}/schemas/${schemaName}${fileExtension}';
        return haxe.io.Path.join([outputDir, phoenixPath]);
    }
    
    /**
     * Extract app name from class name for Phoenix convention transformation.
     * Examples: TodoAppRouter → todo_app, MyAppLive → my_app
     */
    private function extractAppName(className: String): String {
        // First check if we can get app name from compiler defines
        #if (app_name)
        var definedName = haxe.macro.Context.definedValue("app_name");
        // Always convert to snake_case for consistency
        return NamingHelper.toSnakeCase(definedName);
        #end
        
        // Remove common Phoenix suffixes first
        var appPart = className.replace("Router", "")
                               .replace("Live", "")
                               .replace("Controller", "")
                               .replace("Schema", "")
                               .replace("Channel", "")
                               .replace("View", "");
        
        // Handle special case where class name is just the suffix (e.g., "Router")
        if (appPart == "") {
            appPart = "app"; // Default fallback
        }
        
        // Convert to snake_case
        return NamingHelper.toSnakeCase(appPart);
    }
    
    
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
        return NamingHelper.toSnakeCase(haxeName);
    }
    
    /**
     * Convert package.ClassName to package/class_name.ex path
     * Examples: 
     * - haxe.CallStack → haxe/call_stack  
     * - TestDocClass → test_doc_class
     * - my.nested.Module → my/nested/module
     */
    private function convertPackageToDirectoryPath(classType: ClassType): String {
        var packageParts = classType.pack;
        var className = classType.name;
        
        // Convert class name to snake_case
        var snakeClassName = NamingHelper.toSnakeCase(className);
        
        if (packageParts.length == 0) {
            // No package - just return snake_case class name
            return snakeClassName;
        }
        
        // Convert package parts to snake_case and join with directories
        var snakePackageParts = packageParts.map(part -> NamingHelper.toSnakeCase(part));
        return haxe.io.Path.join(snakePackageParts.concat([snakeClassName]));
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
        // Check for framework annotations first
        var annotationInfo = reflaxe.elixir.helpers.AnnotationSystem.detectAnnotations(classType);
        
        if (annotationInfo.primaryAnnotation != null) {
            // Use the comprehensive naming rule for framework annotations
            var namingRule = getComprehensiveNamingRule(classType);
            setOutputFileName(namingRule.fileName);
            setOutputFileDir(namingRule.dirPath);
        } else {
            // Use universal naming for regular classes
            setUniversalOutputPath(classType.name, classType.pack);
        }
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
    private function getUniversalNamingRule(moduleName: String, pack: Array<String> = null): {fileName: String, dirPath: String} {
        // Handle dot notation in module name (e.g., "haxe.CallStack")
        var parts = moduleName.split(".");
        
        // Convert all parts to snake_case
        var snakeParts = parts.map(part -> NamingHelper.toSnakeCase(part));
        
        var fileName: String;
        var dirPath: String;
        
        if (snakeParts.length > 1) {
            // Multi-part name: last part is filename, rest is directory
            fileName = snakeParts.pop();
            dirPath = snakeParts.join("/");
        } else if (pack != null && pack.length > 0) {
            // Single name with package: use package for directory
            fileName = snakeParts[0];
            var snakePackageParts = pack.map(part -> NamingHelper.toSnakeCase(part));
            dirPath = snakePackageParts.join("/");
        } else {
            // Single name, no package: just the filename
            fileName = snakeParts[0];
            dirPath = "";
        }
        
        return {
            fileName: fileName,
            dirPath: dirPath
        };
    }
    
    /**
     * Set output path for ANY module type using the universal naming system.
     * This ensures consistent snake_case naming for all generated files.
     */
    private function setUniversalOutputPath(moduleName: String, pack: Array<String> = null): Void {
        var namingRule = getUniversalNamingRule(moduleName, pack);
        trace('Universal naming: ${moduleName} → file: ${namingRule.fileName}, dir: ${namingRule.dirPath}');
        setOutputFileName(namingRule.fileName);
        setOutputFileDir(namingRule.dirPath);
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
    private function getComprehensiveNamingRule(classType: ClassType): {fileName: String, dirPath: String} {
        var className = classType.name;
        var packageParts = classType.pack;
        var annotationInfo = reflaxe.elixir.helpers.AnnotationSystem.detectAnnotations(classType);
        
        // Start with the base snake_case file name
        var baseFileName = NamingHelper.toSnakeCase(className);
        
        // Convert package parts to snake_case directories
        var snakePackageParts = packageParts.map(part -> NamingHelper.toSnakeCase(part));
        var packagePath = snakePackageParts.length > 0 ? snakePackageParts.join("/") : "";
        
        // Default rule: snake_case file name with package-based directory
        var rule = {
            fileName: baseFileName,
            dirPath: packagePath
        };
        
        // Apply framework annotation overrides if present
        if (annotationInfo.primaryAnnotation != null) {
            var appName = extractAppName(className);
            
            switch (annotationInfo.primaryAnnotation) {
                case ":router":
                    // TodoAppRouter → router.ex in todo_app_web/
                    rule.fileName = "router";
                    rule.dirPath = appName + "_web";
                    
                case ":liveview":
                    // UserLive → user_live.ex in app_web/live/
                    var liveViewName = baseFileName.replace("_live", "");
                    rule.fileName = liveViewName + "_live";
                    rule.dirPath = appName + "_web/live";
                    
                case ":controller":
                    // UserController → user_controller.ex in app_web/controllers/
                    rule.fileName = baseFileName;
                    rule.dirPath = appName + "_web/controllers";
                    
                case ":schema":
                    // User → user.ex in app/schemas/
                    rule.fileName = baseFileName;
                    rule.dirPath = appName + "/schemas";
                    
                case ":endpoint":
                    // Endpoint → endpoint.ex in app_web/
                    rule.fileName = "endpoint";
                    rule.dirPath = appName + "_web";
                    
                case ":application":
                    // TodoApp → todo_app.ex in lib/ (root)
                    // Special case: for @:application, we want the file named after the class
                    // not the @:native module name
                    rule.fileName = baseFileName;
                    rule.dirPath = ""; // Root lib/ directory
                    
                default:
                    // Other annotations: keep package-based path with snake_case
                    // Already set in default rule
            }
        }
        
        return rule;
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
        
        // Initialize source mapping for this class
        if (sourceMapOutputEnabled) {
            var className = classType.name;
            var actualOutputDir = this.output.outputDir != null ? this.output.outputDir : outputDirectory;
            
            // Annotation-aware file path generation for framework convention adherence
            var outputPath = generateAnnotationAwareOutputPath(classType, actualOutputDir);
            initSourceMapWriter(outputPath);
        }
        
        // Check for ExUnit test classes first (before other annotations)
        if (ExUnitCompiler.isExUnitTest(classType)) {
            var result = ExUnitCompiler.compile(classType, this);
            return result;
        }
        
        // Use unified annotation system for detection, validation, and routing
        var annotationResult = reflaxe.elixir.helpers.AnnotationSystem.routeCompilation(classType, varFields, funcFields);
        if (annotationResult != null) {
            return annotationResult;
        }
        
        // Check if this is a LiveView class that should use special compilation
        var annotationInfo = reflaxe.elixir.helpers.AnnotationSystem.detectAnnotations(classType);
        if (annotationInfo.primaryAnnotation == ":liveview") {
            var result = compileLiveViewClass(classType, varFields, funcFields);
            return result;
        }
        
        // Use the enhanced ClassCompiler for proper struct/module generation
        var classCompiler = new reflaxe.elixir.helpers.ClassCompiler(this.typer);
        classCompiler.setCompiler(this);
        classCompiler.setImportOptimizer(importOptimizer);
        
        // Handle inheritance tracking
        if (classType.superClass != null) {
            addModuleTypeForCompilation(TClassDecl(classType.superClass.t));
        }
        
        // Handle interface tracking
        for (iface in classType.interfaces) {
            addModuleTypeForCompilation(TClassDecl(iface.t));
        }
        
        var result = classCompiler.compileClass(classType, varFields, funcFields);
        
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
        try {
            var className = classType.name;
            var config = reflaxe.elixir.helpers.MigrationDSL.getMigrationConfig(classType);
            var tableName = config.table != null ? config.table : "default_table";
            
            // Validate table name
            if (tableName == "default_table") {
                reflaxe.elixir.helpers.EctoErrorReporter.warnAboutPattern(
                    "Migration using default table name",
                    "Specify a table name with @:migration({table: \"your_table\"})",
                    classType.pos
                );
            }
            
            // Extract table operations from class variables and functions
            var columns = varFields.map(field -> '${field.field.name}:${mapHaxeTypeToElixir(field.field.type)}');
            
            // Create migration data structure
            var migrationData = {
                className: className,
                timestamp: reflaxe.elixir.helpers.MigrationDSL.generateTimestamp(),
                tableName: tableName,
                columns: columns
            };
            
            // Generate comprehensive migration with table operations
            var migrationModule = reflaxe.elixir.helpers.MigrationDSL.compileFullMigration(migrationData);
        
        // Add custom migration functions if present in funcFields
        var customOperations = new Array<String>();
        for (func in funcFields) {
            if (func.field.name.indexOf("migrate") == 0) {
                var operationName = func.field.name.substring(7); // Remove "migrate" prefix
                var customOperation = generateCustomMigrationOperation(operationName, tableName);
                customOperations.push(customOperation);
            }
        }
        
        // Append custom operations to the migration if any exist
        if (customOperations.length > 0) {
            migrationModule += "\n\n  # Custom migration operations\n" + customOperations.join("\n");
        }
        
        return migrationModule;
        } catch (e: Dynamic) {
            // Dynamic used here because migration compilation can throw various error types
            reflaxe.elixir.helpers.EctoErrorReporter.reportMigrationError(
                "create_table",
                Std.string(e),
                classType.pos
            );
            return "";
        }
    }
    
    /**
     * Extract table name from migration class name
     */
    private function extractTableNameFromClassName(className: String): String {
        // Convert CreateUsersTable -> users, AlterPostsTable -> posts, etc.
        var tableName = className;
        
        // Remove common prefixes
        if (tableName.indexOf("Create") == 0) {
            tableName = tableName.substring(6);
        } else if (tableName.indexOf("Alter") == 0) {
            tableName = tableName.substring(5);
        } else if (tableName.indexOf("Drop") == 0) {
            tableName = tableName.substring(4);
        }
        
        // Remove Table suffix
        if (tableName.endsWith("Table")) {
            tableName = tableName.substring(0, tableName.length - 5);
        }
        
        // Convert to snake_case
        return reflaxe.elixir.helpers.MigrationDSL.camelCaseToSnakeCase(tableName);
    }
    
    /**
     * Map Haxe types to Elixir migration types
     */
    private function mapHaxeTypeToElixir(haxeType: Dynamic): String {
        // Simplified type mapping - would use ElixirTyper for full implementation
        return "string"; // Default to string for now
    }
    
    /**
     * Generate custom migration operation
     */
    private function generateCustomMigrationOperation(operationName: String, tableName: String): String {
        return '  # Custom operation: ${operationName}\n' +
               '  # Add custom migration logic for ${tableName} table';
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
        var className = classType.name;
        var pos = classType.pos;
        
        try {
            var config = reflaxe.elixir.helpers.SchemaCompiler.getSchemaConfig(classType);
            
            // Validate schema fields before compilation
            var fields = varFields.map(function(field) {
                var meta = field.field.meta.get();
                var fieldMeta = null;
                
                // Extract field metadata
                for (m in meta) {
                    if (m.name == ":field") {
                        fieldMeta = m.params.length > 0 ? m.params[0] : null;
                    }
                }
                
                return {
                    name: field.field.name,
                    type: mapHaxeTypeToElixir(field.field.type),
                    meta: fieldMeta
                };
            });
            
            // Validate fields using error reporter
            if (!EctoErrorReporter.validateSchemaFields(fields, pos)) {
                return ""; // Error already reported
            }
            
            // Generate comprehensive Ecto.Schema module with schema/2 macro and associations
            return reflaxe.elixir.helpers.SchemaCompiler.compileFullSchema(className, config, varFields);
        } catch (e: Dynamic) {
            // Dynamic used here because Haxe's catch can throw various error types
            // Converting to String for error reporting
            EctoErrorReporter.reportSchemaError(className, Std.string(e), pos);
            return "";
        }
    }
    
    /**
     * Compile @:changeset annotated class to Ecto changeset module with enhanced error reporting
     */
    private function compileChangesetClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var pos = classType.pos;
        
        try {
            var config = reflaxe.elixir.helpers.ChangesetCompiler.getChangesetConfig(classType);
            var schemaName = config.schema != null ? config.schema : "DefaultSchema";
            
            // Validate changeset configuration
            if (!EctoErrorReporter.validateChangesetConfig(className, config, pos)) {
                return ""; // Error already reported
            }
            
            // Extract field information from class variables for validation
            var fieldNames = varFields.map(field -> field.field.name);
            
            // Generate comprehensive changeset with schema integration
            var changesetModule = reflaxe.elixir.helpers.ChangesetCompiler.compileFullChangeset(className, schemaName);
            
            // Add custom validation functions if present in funcFields
            var customValidations = new Array<String>();
            for (func in funcFields) {
                if (func.field.name.indexOf("validate") == 0) {
                    var validationName = func.field.name.substring(8); // Remove "validate" prefix
                    var customValidation = reflaxe.elixir.helpers.ChangesetCompiler.generateCustomValidation(
                        validationName, 
                        "field", 
                        "true" // Simplified condition
                    );
                    customValidations.push(customValidation);
                }
            }
            
            // Append custom validations to the module
            if (customValidations.length > 0) {
                changesetModule += "\n\n" + customValidations.join("\n");
            }
            
            return changesetModule;
        } catch (e: Dynamic) {
            // Dynamic used here because Haxe's catch can throw various error types
            // Converting to String for error reporting
            EctoErrorReporter.reportChangesetError(className, Std.string(e), pos);
            return "";
        }
    }
    
    /**
     * Compile @:genserver annotated class to OTP GenServer module
     */
    private function compileGenServerClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.helpers.OTPCompiler.getGenServerConfig(classType);
        
        // Extract state from class variables
        var initialState = "%{";
        var stateFields = [];
        for (field in varFields) {
            var fieldName = field.field.name;
            var defaultValue = switch(Std.string(field.field.type)) {
                case "Int": "0";
                case "String": '""';
                case "Bool": "false";
                default: "nil";
            };
            stateFields.push('${fieldName}: ${defaultValue}');
        }
        initialState += stateFields.join(", ") + "}";
        
        // Extract methods and categorize into calls vs casts
        var callMethods = [];
        var castMethods = [];
        
        for (func in funcFields) {
            var methodName = func.field.name;
            
            // Methods starting with "get" or returning values are synchronous calls
            if (methodName.indexOf("get") == 0 || methodName.indexOf("is") == 0) {
                callMethods.push({name: methodName, returns: "Dynamic"});
            }
            // Methods that modify state are asynchronous casts
            else if (methodName.indexOf("set") == 0 || methodName.indexOf("update") == 0 || methodName.indexOf("increment") == 0) {
                castMethods.push({name: methodName, modifies: "value"});
            }
        }
        
        // Create GenServer data structure
        var genServerData = {
            className: className,
            initialState: initialState,
            callMethods: callMethods,
            castMethods: castMethods
        };
        
        // Generate comprehensive GenServer with all callbacks
        return reflaxe.elixir.helpers.OTPCompiler.compileFullGenServer(genServerData);
    }
    
    /**
     * Compile @:liveview annotated class to Phoenix LiveView module  
     */
    private function compileLiveViewClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var result = new StringBuf();
        
        // Generate module name from @:native annotation or use default class name
        var moduleName = classType.getNameOrNative();
        
        // Track instance variables for socket.assigns references
        this.liveViewInstanceVars = new Map<String, Bool>();
        for (field in varFields) {
            this.liveViewInstanceVars.set(field.field.name, true);
        }
        
        // Generate module header using LiveViewCompiler with resolved module name
        // Auto-detect CoreComponents usage and import if needed using dynamic app name
        var appName = reflaxe.elixir.helpers.AnnotationSystem.getEffectiveAppName(classType);
        var coreComponentsModule: Null<String> = null;
        if (detectCoreComponentsUsage(classType, funcFields)) {
            var webModuleName = appName + "Web";
            coreComponentsModule = webModuleName + ".CoreComponents";
        }
        var moduleHeader = reflaxe.elixir.LiveViewCompiler.generateModuleHeader(moduleName, appName, coreComponentsModule);
        result.add(moduleHeader);
        
        // Check if this LiveView uses HXX templates and add Phoenix.Component import
        // HXX templates compile to Phoenix HEEx format (~H sigils) and require Phoenix.Component
        var hxxChecker = new reflaxe.elixir.helpers.ClassCompiler();
        if (hxxChecker.usesHxxTemplates(classType, funcFields)) {
            result.add('  use Phoenix.Component\n\n');
        }
        
        // LiveView modules don't need constructors or instance variables
        // State is managed through socket assigns, not instance variables
        
        // Filter out the "new" function if it exists - LiveView doesn't need constructors
        var filteredFuncs = funcFields.filter(func -> func.field.name != "new");
        
        // Compile all functions using the main compiler (which we just fixed)
        for (funcField in filteredFuncs) {
            var funcName = funcField.field.name;
            
            // Add @impl true for LiveView callbacks
            if (reflaxe.elixir.LiveViewCompiler.isLiveViewCallback(funcName)) {
                result.add('  @impl true\n');
            }
            
            // Use the main compiler's compileFunction method (which now works properly)
            var compiledFunc = compileFunction(funcField, false);
            result.add(compiledFunc);
        }
        
        result.add('end\n');
        
        // Clear instance variable tracking after compilation
        this.liveViewInstanceVars = null;
        
        return result.toString();
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
     */
    public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<String> {
        return compileElixirExpressionInternal(expr, topLevel);
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
        return switch (name) {
            // Core Haxe types
            case "Int" | "Float" | "Bool" | "String" | "Dynamic" | "Void" | "Any" | "Null" | 
                 "Function" | "Class" | "Enum" | "EnumValue" | "Int32" | "Int64":
                true;
            
            // Standard library containers and collections  
            case "Array" | "Map" | "List" | "Vector" | "Stack" | "GenericStack":
                true;
                
            // Standard library iterators (handled by Elixir's Enum/Stream)
            case "IntIterator" | "ArrayIterator" | "StringIterator" | "MapIterator" |
                 "ArrayKeyValueIterator" | "StringKeyValueIterator" | "MapKeyValueIterator":
                true;
                
            // Standard library utility types (handled internally)
            case "StringBuf" | "StringTools" | "Math" | "Reflect" | "Type" | "Std":
                true;
                
            // JSON handling types are now compiled normally as structs
            // (Removed JsonPrinter | JsonParser - they compile as instance classes)
                
            // Error/debugging types (handled by Elixir's error system)
            case "CallStack" | "Exception" | "Error":
                true;
                
            // Abstract implementation types (compiler-generated)
            case name if (name.endsWith("_Impl_")):
                true;
                
            // Haxe package types (handled separately if needed)
            case name if (name.startsWith("haxe.")):
                true;
                
            default:
                false;
        };
    }
    
    /**
     * Check if this is a standard library class type that should NOT generate an Elixir module
     */
    private function isStandardLibraryClass(name: String): Bool {
        return switch (name) {
            // Haxe standard library classes that should be skipped
            case name if (name.startsWith("haxe.") || name.startsWith("sys.") || name.startsWith("js.") || name.startsWith("flash.")):
                true;
                
            // Iterator implementation classes
            case "ArrayIterator" | "StringIterator" | "IntIterator" | "MapIterator" |
                 "ArrayKeyValueIterator" | "StringKeyValueIterator" | "MapKeyValueIterator":
                true;
                
            // Data structure implementation classes
            case "StringBuf" | "StringTools" | "List" | "GenericStack" | "BalancedTree" | "TreeNode":
                true;
                
            // JSON implementation classes are now compiled normally as structs
            // (Removed JsonPrinter | JsonParser - they compile as instance classes)
                
            // Abstract implementation classes (compiler-generated)
            case name if (name.endsWith("_Impl_")):
                true;
                
            // Built-in type classes
            case "Class" | "Enum" | "Type" | "Reflect" | "Std" | "Math":
                true;
                
            // Regular expression class (has special compiler integration)
            case "EReg":
                true;
                
            default:
                false;
        };
    }

    /**
     * Get Elixir type representation from Haxe type
     */
    private function getElixirTypeFromHaxeType(type: Type): String {
        return switch (type) {
            case TInst(_.get() => classType, _):
                switch (classType.name) {
                    case "String": "String.t()";
                    case "Array": "list()";
                    default: "term()";
                }
            case TAbstract(_.get() => abstractType, _):
                switch (abstractType.name) {
                    case "Int": "integer()";
                    case "Float": "float()";
                    case "Bool": "boolean()";
                    default: "term()";
                }
            default:
                "term()";
        };
    }
    
    /**
     * Helper methods for managing module content - simplified for now
     */
    private function getCurrentModuleContent(abstractType: AbstractType): Null<String> {
        // For now, return a simple placeholder
        return "";
    }
    
    private function addTypeDefinition(content: String, typeAlias: String): String {
        return content + "\n  " + typeAlias + "\n";
    }
    
    private function updateCurrentModuleContent(abstractType: AbstractType, content: String): Void {
        // For now, this is a placeholder - in a full implementation,
        // this would update the module's content in the output system
    }
    
    /**
     * Compile typedef - Returns null to ignore typedefs as BaseCompiler recommends.
     * This prevents generating invalid StdTypes.ex files with @typedoc/@type outside modules.
     */
    public override function compileTypedefImpl(defType: DefType): Null<String> {
        // Following BaseCompiler recommendation: ignore typedefs since
        // "Haxe redirects all types automatically" - no standalone typedef files needed
        // 
        // Returning null prevents generating invalid StdTypes.ex files with 
        // @typedoc/@type directives outside modules.
        // 
        // Now using DirectToStringCompiler - typedefs still not needed for Elixir
        return null;
    }
    
    
    /**
     * Internal Elixir expression compilation
     */
    private function compileElixirExpressionInternal(expr: TypedExpr, topLevel: Bool = false): Null<String> {
        
        // DEBUG: Test if trace works at all
        if (expr.expr != null) {
            switch(expr.expr) {
                case TIf(_, _, _): // Detect TIf patterns
                case _:
            }
        }
        
        // Comprehensive expression compilation
        return switch (expr.expr) {
            case TConst(constant):
                compileTConstant(constant);
                
            case TLocal(v):
                // Get the original variable name (before Haxe's renaming for shadowing avoidance)
                var originalName = getOriginalVarName(v);
                
                // Special handling for inline context variables
                if (originalName == "_this" && hasInlineContext("struct")) {
                    return "struct";
                }
                
                // Check if this is a LiveView instance variable that should use socket.assigns
                if (liveViewInstanceVars != null && liveViewInstanceVars.exists(originalName)) {
                    var snakeCaseName = NamingHelper.toSnakeCase(originalName);
                    return 'socket.assigns.${snakeCaseName}';
                }
                
                // Check if this is a function reference being passed as an argument
                if (isFunctionReference(v, originalName)) {
                    return generateFunctionReference(originalName);
                }
                
                // Use parameter mapping if available (for both abstract methods and regular functions with standardized arg names)
                if (currentFunctionParameterMap.exists(originalName)) {
                    currentFunctionParameterMap.get(originalName);
                } else {
                    NamingHelper.toSnakeCase(originalName);
                }
                
            case TBinop(op, e1, e2):
                // Special handling for string concatenation and assignment operators
                switch (op) {
                    case OpAdd:
                        // Check if this is string concatenation
                        var e1IsString = isStringType(e1.t);
                        var e2IsString = isStringType(e2.t);
                        var isStringConcat = e1IsString || e2IsString;
                        
                        if (isStringConcat) {
                            // Use <> for string concatenation in Elixir
                            // Handle string constants directly to preserve quotes
                            var left = switch (e1.expr) {
                                case TConst(TString(s)): 
                                    // Properly escape and quote the string
                                    var escaped = StringTools.replace(s, '\\', '\\\\');
                                    escaped = StringTools.replace(escaped, '"', '\\"');
                                    escaped = StringTools.replace(escaped, '\n', '\\n');
                                    escaped = StringTools.replace(escaped, '\r', '\\r');
                                    escaped = StringTools.replace(escaped, '\t', '\\t');
                                    '"${escaped}"';
                                case _: 
                                    compileExpression(e1);
                            };
                            
                            var right = switch (e2.expr) {
                                case TConst(TString(s)): 
                                    // Properly escape and quote the string
                                    var escaped = StringTools.replace(s, '\\', '\\\\');
                                    escaped = StringTools.replace(escaped, '"', '\\"');
                                    escaped = StringTools.replace(escaped, '\n', '\\n');
                                    escaped = StringTools.replace(escaped, '\r', '\\r');
                                    escaped = StringTools.replace(escaped, '\t', '\\t');
                                    '"${escaped}"';
                                case _: 
                                    compileExpression(e2);
                            };
                            
                            // Convert non-string operands to strings
                            if (!e1IsString && e2IsString) {
                                // Left side needs conversion
                                left = convertToString(e1, left);
                            } else if (e1IsString && !e2IsString) {
                                // Right side needs conversion
                                right = convertToString(e2, right);
                            }
                            
                            '${left} <> ${right}';
                        } else {
                            compileExpression(e1) + " + " + compileExpression(e2);
                        }
                        
                        
                    case OpAssignOp(innerOp):
                        // Handle compound assignment operators (+=, -=, etc.)
                        // These need special handling since Elixir variables are immutable
                        
                        // Check if this is a field compound assignment which needs special handling
                        switch (e1.expr) {
                            case TField(structExpr, fa):
                                // Field compound assignment: struct.field += value
                                // This needs to become: struct = %{struct | field: struct.field + value}
                                
                                var structStr = compileExpression(structExpr);
                                var fieldName = switch (fa) {
                                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                                        cf.get().name;
                                    case FDynamic(s): s;
                                    case FEnum(_, ef): ef.name;
                                };
                                var elixirFieldName = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(fieldName);
                                var right = compileExpression(e2);
                                
                                // Build the compound operation expression
                                var opStr = switch (innerOp) {
                                    case OpAdd:
                                        // Check if string concatenation
                                        var isStringOp = switch (e1.t) {
                                            case TInst(t, _) if (t.get().name == "String"): true;
                                            case _: false;
                                        };
                                        isStringOp ? "<>" : "+";
                                    case OpSub: "-";
                                    case OpMult: "*";
                                    case OpDiv: "/";
                                    case _: compileBinop(innerOp);
                                };
                                
                                var newValue = '${structStr}.${elixirFieldName} ${opStr} ${right}';
                                
                                if (isCompilingCaseArm) {
                                    // In case arm: return struct update expression
                                    '%{${structStr} | ${elixirFieldName}: ${newValue}}';
                                } else {
                                    // Regular context: struct = %{struct | field: newValue}
                                    '${structStr} = %{${structStr} | ${elixirFieldName}: ${newValue}}';
                                }
                                
                            case _:
                                // Regular compound assignment
                                var left = compileExpression(e1);
                                var right = compileExpression(e2);
                                
                                switch (innerOp) {
                                    case OpAdd:
                                        // Check if string concatenation
                                        var isStringOp = switch (e1.t) {
                                            case TInst(t, _) if (t.get().name == "String"): true;
                                            case _: false;
                                        };
                                        
                                        if (isStringOp) {
                                            '${left} = ${left} <> ${right}';
                                        } else {
                                            '${left} = ${left} + ${right}';
                                        }
                                        
                                    case OpSub:
                                        '${left} = ${left} - ${right}';
                                        
                                    case OpMult:
                                        '${left} = ${left} * ${right}';
                                        
                                    case OpDiv:
                                        '${left} = ${left} / ${right}';
                                        
                                    case _:
                                        // For other operators, use the standard pattern
                                        '${left} = ${left} ${compileBinop(innerOp)} ${right}';
                                }
                        }
                        
                    case OpAssign:
                        // FIRST: Check if this is an inline context assignment like _this = struct.buf
                        switch (e1.expr) {
                            case TLocal(v):
                                var varName = getOriginalVarName(v);
                                if (varName == "_this") {
                                    // Only set inline context if this is actually an inline function expansion
                                    // Check if this is _this = this.field pattern (inline expansion)
                                    var isInlineExpansion = switch(e2.expr) {
                                        case TField(e, _): switch(e.expr) {
                                            case TConst(TThis): true;
                                            case _: false;
                                        };
                                        case _: false;
                                    };
                                    
                                    var value = compileExpression(e2);
                                    
                                    // Only set inline context for genuine inline expansions
                                    if (isInlineExpansion) {
                                        setInlineContext("struct", "active");
                                    } else {
                                    }
                                    
                                    return 'struct = ${value}';
                                }
                            case TField(_, _):
                            case _:
                        }
                        
                        // Handle struct field assignment with Elixir's immutable update syntax
                        switch (e1.expr) {
                            case TField(structExpr, fa):
                                // This is a field assignment like _this.b = value or struct.field = value
                                switch (structExpr.expr) {
                                    case TLocal(v):
                                        // Simple local variable struct update
                                        var structName = getOriginalVarName(v);
                                        var elixirStructName = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(structName);
                                        var fieldName = switch (fa) {
                                            case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                                                cf.get().name;
                                            case FDynamic(s): s;
                                            case FEnum(_, ef): ef.name;
                                        };
                                        
                                        // Convert field name to snake_case for Elixir
                                        var elixirFieldName = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(fieldName);
                                        var value = compileExpression(e2);
                                        
                                        
                                        // Check if we're in a case arm and need to return struct update as expression
                                        if (isCompilingCaseArm) {
                                            // Map 'this' to struct parameter if it exists
                                            var actualStructName = currentFunctionParameterMap.get("this");
                                            if (actualStructName == null) actualStructName = elixirStructName;
                                            
                                            // Return struct update as expression (not assignment)
                                            var result = '%{${actualStructName} | ${elixirFieldName}: ${value}}';
                                            result;
                                        } else {
                                            // Generate regular Elixir struct update assignment
                                            '${elixirStructName} = %{${elixirStructName} | ${elixirFieldName}: ${value}}';
                                        }
                                        
                                    case TConst(TThis):
                                        // Handle this.field assignments properly with enhanced inline context support
                                        var mappedName = resolveThisReference();
                                        
                                        var fieldName = switch (fa) {
                                            case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                                                cf.get().name;
                                            case FDynamic(s): s;
                                            case FEnum(_, ef): ef.name;
                                        };
                                        var value = compileExpression(e2);
                                        var elixirFieldName = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(fieldName);
                                        
                                        if (isCompilingCaseArm) {
                                            // Return struct update as expression (not assignment)
                                            '%{${mappedName} | ${elixirFieldName}: ${value}}';
                                        } else {
                                            // Generate regular Elixir struct update assignment
                                            '${mappedName} = %{${mappedName} | ${elixirFieldName}: ${value}}';
                                        }
                                        
                                    case _:
                                        // Complex struct expression
                                        if (isCompilingCaseArm) {
                                            // In case arms, we can't do assignments - return struct update expression
                                            var value = compileExpression(e2);
                                            var fieldName = switch (fa) {
                                                case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf): cf.get().name;
                                                case _: "unknown_field";
                                            };
                                            var elixirFieldName = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(fieldName);
                                            
                                            // Use struct parameter name from current function mapping
                                            var structVar = currentFunctionParameterMap.get("this");
                                            if (structVar == null) structVar = "struct";
                                            
                                            '%{${structVar} | ${elixirFieldName}: ${value}}';
                                        } else {
                                            // Complex struct expression - compile normally for now
                                            var structStr = compileExpression(structExpr);
                                            var fieldStr = compileFieldAccess(structExpr, fa);
                                            var value = compileExpression(e2);
                                            
                                            // For complex expressions, we may need a temporary variable
                                            // For now, fall back to standard assignment (will error in Elixir)
                                            '${structStr}.${fieldStr} = ${value}';
                                        }
                                }
                                
                            case _:
                                // Check if this is a field assignment that we missed
                                switch (e1.expr) {
                                    case TField(structExpr, fa):
                                        // This is a field assignment - MUST use struct update syntax
                                        
                                        // Compile the struct expression to get the variable name
                                        var structStr = compileExpression(structExpr);
                                        var fieldName = switch (fa) {
                                            case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                                                cf.get().name;
                                            case FDynamic(s): s;
                                            case FEnum(_, ef): ef.name;
                                        };
                                        var elixirFieldName = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(fieldName);
                                        var value = compileExpression(e2);
                                        
                                        // In Elixir, we MUST use struct update syntax
                                        // Direct field assignment like struct.field = value is INVALID
                                        if (isCompilingCaseArm) {
                                            // In case arms, return struct update expression
                                            '%{${structStr} | ${elixirFieldName}: ${value}}';
                                        } else {
                                            // Regular context: struct = %{struct | field: value}
                                            '${structStr} = %{${structStr} | ${elixirFieldName}: ${value}}';
                                        }
                                        
                                    case _:
                                        // Regular variable assignment
                                        compileExpression(e1) + " = " + compileExpression(e2);
                                }
                        }
                    
                    case OpShl | OpShr | OpUShr:
                        // Bitwise shift operators need to use Bitwise module
                        var left = compileExpression(e1);
                        var right = compileExpression(e2);
                        switch (op) {
                            case OpShl:
                                'Bitwise.<<<(${left}, ${right})';
                            case OpShr:
                                'Bitwise.>>>(${left}, ${right})';
                            case OpUShr:
                                'Bitwise.>>>(${left}, ${right})'; // Elixir doesn't distinguish signed/unsigned
                            case _:
                                '${left} ${compileBinop(op)} ${right}';
                        }
                        
                    case _:
                        // For all other binary operators, use standard compilation
                        compileExpression(e1) + " " + compileBinop(op) + " " + compileExpression(e2);
                }
                
            case TUnop(op, postFix, e):
                var expr_str = compileExpression(e);
                switch (op) {
                    case OpIncrement: 
                        // In Elixir, we can't mutate variables, so i++ becomes i = i + 1
                        // However, as an expression, we just return the value
                        // When used as a statement, the parent context should handle assignment
                        // For now, we'll generate the expression that evaluates to the new value
                        switch (e.expr) {
                            case TLocal(v):
                                // If it's a local variable, generate assignment
                                var originalName = getOriginalVarName(v);
                                var varName = NamingHelper.toSnakeCase(originalName);
                                '${varName} = ${varName} + 1';
                            case _:
                                // For other expressions, just generate the increment expression
                                '${expr_str} + 1';
                        }
                    case OpDecrement:
                        switch (e.expr) {
                            case TLocal(v):
                                // If it's a local variable, generate assignment
                                var originalName = getOriginalVarName(v);
                                var varName = NamingHelper.toSnakeCase(originalName);
                                '${varName} = ${varName} - 1';
                            case _:
                                // For other expressions, just generate the decrement expression
                                '${expr_str} - 1';
                        }
                    case OpNot: '!${expr_str}';
                    case OpNeg: '-${expr_str}';
                    case OpNegBits: 'bnot(${expr_str})';
                    case _: '${expr_str}';
                }
                
            case TField(e, fa):
                // Handle nested field access with inline context support
                // Special handling for enum field access - generate atoms, not field calls
                switch (fa) {
                    case FEnum(enumType, enumField):
                        // Check if this is a known algebraic data type (Result, Option, etc.)
                        var enumTypeRef = enumType.get();
                        if (AlgebraicDataTypeCompiler.isADTType(enumTypeRef)) {
                            var compiled = AlgebraicDataTypeCompiler.compileADTFieldAccess(enumTypeRef, enumField);
                            if (compiled != null) return compiled;
                        }
                        
                        // For regular enum types - compile to tuple representation
                        // Use the enum field's index property directly
                        var constructorIndex = enumField.index;
                        
                        // Generate proper atom representation for enum constructor
                        // Constructor without parameters compile to atoms like :one_for_one
                        // Constructor with parameters: handled by TCall
                        if (enumField.params.length == 0) {
                            // Simple constructor without parameters - use snake_case atom
                            var atomName = NamingHelper.toSnakeCase(enumField.name);
                            ':${atomName}';
                        } else {
                            // This case shouldn't happen here - constructors with params
                            // should be handled by TCall, but let's handle it gracefully
                            // For constructors with parameters, we still need the atom name
                            var atomName = NamingHelper.toSnakeCase(enumField.name);
                            ':${atomName}'; // Fallback for now
                        }
                        
                    case FStatic(classRef, cf):
                        // Check if this is a static method being used as a function reference
                        var field = cf.get();
                        var isFunction = switch (field.type) {
                            case TFun(_, _): true;
                            case _: false;
                        };
                        
                        // Check if this field access is being used as a function reference
                        // (i.e., not being called immediately)
                        // This happens when the field is passed as an argument to another function
                        if (isFunction && !isBeingCalled(expr)) {
                            // This is a static function reference - generate Elixir function reference syntax
                            var className = classRef.get().name;
                            var functionName = NamingHelper.toSnakeCase(field.name);
                            
                            // Determine the arity of the function
                            var arity = switch (field.type) {
                                case TFun(args, _): args.length;
                                case _: 0;
                            };
                            
                            // Generate function reference syntax: &Module.function/arity
                            return '&${className}.${functionName}/${arity}';
                        } else {
                            // Regular static field access or method call (will be handled by TCall)
                            var baseExpr = compileExpression(e);
                            var elixirFieldName = NamingHelper.toSnakeCase(field.name);
                            '${baseExpr}.${elixirFieldName}';
                        }
                        
                    case _:
                        // Regular field access for non-enum, non-static fields
                        var baseExpr = switch (e.expr) {
                            case TConst(TThis):
                                // Extract field name for LiveView check
                                var fieldName = switch (fa) {
                                    case FInstance(_, _, cf) | FAnon(cf): cf.get().name;
                                    case FDynamic(s): s;
                                    case _: "unknown_field";
                                };
                                
                                // Check if this is a LiveView instance field access
                                if (liveViewInstanceVars != null && liveViewInstanceVars.exists(fieldName)) {
                                    var elixirFieldName = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(fieldName);
                                    return 'socket.assigns.${elixirFieldName}';
                                } else {
                                    // Use enhanced inline context resolution for non-LiveView cases
                                    resolveThisReference();
                                }
                            case _:
                                compileExpression(e);
                        };
                        var fieldName = switch (fa) {
                            case FInstance(_, _, cf) | FAnon(cf): cf.get().name;
                            case FDynamic(s): s;
                            case _: "unknown_field";
                        };
                        var elixirFieldName = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(fieldName);
                        '${baseExpr}.${elixirFieldName}';
                }
                
            case TCall(e, el):
                // Check for special compile-time function calls
                switch (e.expr) {
                    case TLocal(v) if (v.name == "getAppName"):
                        // Resolve app name at compile-time from @:appName annotation
                        var appName = AnnotationSystem.getEffectiveAppName(currentClassType);
                        return '"${appName}"';
                    case TLocal(v):
                        // Check if this is a function parameter being called
                        // Function parameters need special syntax in Elixir: func_name.(args)
                        var varType = v.t;
                        var isFunction = switch (varType) {
                            case TFun(_, _): true;
                            case _: false;
                        };
                        
                        if (isFunction) {
                            // This is a function parameter being called - use Elixir's .() syntax
                            var functionName = NamingHelper.toSnakeCase(v.name);
                            var compiledArgs = el.map(arg -> compileExpression(arg));
                            return '${functionName}.(${compiledArgs.join(", ")})';
                        }
                        
                    case TField(obj, field):
                        var fieldName = switch (field) {
                            case FInstance(_, _, cf) | FStatic(_, cf) | FClosure(_, cf): cf.get().name;
                            case FAnon(cf): cf.get().name;
                            case FEnum(_, ef): ef.name;
                            case FDynamic(s): s;
                        };
                        
                        // Check for super method calls (TField on TSuper)
                        if (obj.expr.match(TConst(TSuper)) && fieldName == "toString") {
                            // Handle super.toString() specially for exception classes
                            return '"Exception"';
                        }
                        
                        // Check for elixir.Syntax calls and transform them to __elixir__ injection
                        if (isElixirSyntaxCall(obj, fieldName)) {
                            return compileElixirSyntaxCall(fieldName, el);
                        }
                        
                        // Check for TypeSafeChildSpec enum constructor calls
                        if (isTypeSafeChildSpecCall(obj, fieldName)) {
                            return compileTypeSafeChildSpecCall(fieldName, el);
                        }
                        
                        if (fieldName == "getAppName") {
                            // Handle Class.getAppName() calls
                            var appName = AnnotationSystem.getEffectiveAppName(currentClassType);
                            return '"${appName}"';
                        }
                    case _:
                        // Not a special function call, proceed normally
                }
                compileMethodCall(e, el);
                
            case TArrayDecl(el):
                "[" + el.map(expr -> compileExpression(expr)).join(", ") + "]";
                
            case TObjectDecl(fields):
                // Check if this is a Supervisor child spec object
                if (isChildSpecObject(fields)) {
                    return compileChildSpec(fields, currentClassType);
                }
                
                // Check if this is a Supervisor options object
                if (isSupervisorOptionsObject(fields)) {
                    return compileSupervisorOptions(fields, currentClassType);
                }
                
                // Determine if this object should use atom keys (for OTP patterns, etc.)
                var useAtoms = shouldUseAtomKeys(fields);
                var compiledFields = fields.map(f -> {
                    if (useAtoms && isValidAtomName(f.name)) {
                        // Use idiomatic colon syntax for atom keys: %{name: value}
                        f.name + ": " + compileExpression(f.expr);
                    } else {
                        // Use arrow syntax for string keys: %{"key" => value}
                        '"' + f.name + '"' + " => " + compileExpression(f.expr);
                    }
                });
                "%{" + compiledFields.join(", ") + "}";
                
            case TVar(tvar, expr):
                // Check if variable is marked as unused by optimizer
                if (tvar.meta != null && tvar.meta.has("-reflaxe.unused")) {
                    // Skip generating unused variables, but still evaluate expression if it has side effects
                    if (expr != null) {
                        return compileExpression(expr);
                    } else {
                        return "";  // Don't generate anything for unused variables without init
                    }
                }
                
                // Get the original variable name (before Haxe's renaming)
                var originalName = getOriginalVarName(tvar);
                
                // CRITICAL FIX: Detect variable name collision in desugared loops
                // When Haxe desugars map/filter, it may reuse variable names like _g
                // for both the accumulator array and the loop counter
                if (originalName.startsWith("_g")) {
                    // Check if this is an array initialization followed by integer reassignment
                    if (expr != null) {
                        switch (expr.expr) {
                            case TArrayDecl([]):
                                // This is array initialization - use a different name
                                originalName = originalName + "_array";
                            case TConst(TInt(0)):
                                // This is counter initialization - use a different name
                                originalName = originalName + "_counter";
                            case _:
                        }
                    }
                }
                
                // Check if this is _this and needs special handling
                var preserveUnderscore = false;
                if (originalName == "_this") {
                    // Check if this is an inline expansion of _this = this.someField
                    var isInlineThisInit = switch(expr.expr) {
                        case TField(e, _): switch(e.expr) {
                            case TConst(TThis): true;
                            case _: false;
                        };
                        case _: false;
                    };
                    
                    // Also check if we already have an inline context (struct updates)
                    var hasExistingContext = hasInlineContext("struct");
                    
                    // Preserve _this if it's an inline expansion OR if inline context is already active
                    preserveUnderscore = isInlineThisInit || hasExistingContext;
                }
                
                var varName = preserveUnderscore ? originalName : NamingHelper.toSnakeCase(originalName);
                
                if (expr != null) {
                    // Check if this is an inline expansion of _this = this.someField
                    var isInlineThisInit = originalName == "_this" && switch(expr.expr) {
                        case TField(e, _): switch(e.expr) {
                            case TConst(TThis): true;
                            case _: false;
                        };
                        case _: false;
                    };
                    
                    if (isInlineThisInit) {
                        // Temporarily disable any existing struct context to compile the right side correctly
                        var savedContext = inlineContextMap.get("struct");
                        inlineContextMap.remove("struct");
                        var compiledExpr = compileExpression(expr);
                        
                        // Now set the context for future uses - mark struct as active
                        setInlineContext("struct", "active");
                        
                        // Always use 'struct' for inline expansions instead of '_this'
                        'struct = ${compiledExpr}';
                    } else {
                        var compiledExpr = compileExpression(expr);
                        
                        // If this is _this and we preserved the underscore, activate inline context
                        if (originalName == "_this" && preserveUnderscore) {
                            setInlineContext("struct", "active");
                        }
                        
                        // In case arms, avoid temp variable assignments - return expressions directly
                        if (isCompilingCaseArm && (originalName.startsWith("temp_") || originalName.startsWith("temp"))) {
                            return compiledExpr;
                        }
                        
                        '${varName} = ${compiledExpr}';
                    }
                } else {
                    // In case arms, skip temp variable nil assignments completely
                    if (isCompilingCaseArm && (originalName.startsWith("temp_") || originalName.startsWith("temp"))) {
                        return "nil";
                    }
                    '${varName} = nil';
                }
                
            case TBlock(el):
                if (el.length == 0) {
                    "nil";
                } else if (el.length == 1) {
                    compileExpression(el[0]);
                } else {
                    // EARLY OPTIMIZATION: Check for Reflect.fields pattern before processing
                    // This catches the pattern: for (field in Reflect.fields(config)) {...}
                    // which gets desugared into a TBlock with multiple statements
                    if (el.length >= 2) {
                        // Look for pattern: TVar(_g, 0) followed by TVar(_g, Reflect.fields(...))
                        var hasReflectPattern = false;
                        var reflectTarget: String = null;
                        
                        for (i in 0...el.length) {
                            switch (el[i].expr) {
                                case TVar(tvar, init) if (init != null):
                                    switch (init.expr) {
                                        case TCall(e, args):
                                            switch (e.expr) {
                                                case TField(obj, fa):
                                                    var objStr = compileExpression(obj);
                                                    switch (fa) {
                                                        case FStatic(_, cf):
                                                            if (objStr == "Reflect" && cf.get().name == "fields" && args.length > 0) {
                                                                hasReflectPattern = true;
                                                                reflectTarget = compileExpression(args[0]);
                                                            }
                                                        case _:
                                                    }
                                                case _:
                                            }
                                        case _:
                                    }
                                case _:
                            }
                        }
                        
                        // If we found a Reflect.fields pattern, optimize the entire block
                        if (hasReflectPattern && reflectTarget != null) {
                            // Find the while loop that iterates over the fields
                            for (expr in el) {
                                switch (expr.expr) {
                                    case TWhile(econd, ebody, _):
                                        // This is the desugared for-loop
                                        // Transform to idiomatic Elixir
                                        var fieldVar = "field";
                                        var body = transformReflectLoopBody(ebody, reflectTarget, fieldVar);
                                        return 'Enum.each(Map.keys(${reflectTarget}), fn ${fieldVar} ->\n  ${body}\nend)';
                                    case _:
                                }
                            }
                        }
                    }
                    
                    // Track variable declarations and their types to detect collisions
                    var varDeclarations = new Map<String, Array<{index: Int, type: String, newName: String}>>();
                    var varRenamings = new Map<Int, String>(); // Map from expression index to new name
                    
                    // First pass: detect variable name collisions in desugared code
                    for (i in 0...el.length) {
                        switch (el[i].expr) {
                            case TVar(tvar, init):
                                var originalName = getOriginalVarName(tvar);
                                
                                // Check for desugared loop variables that get reused
                                if (originalName.startsWith("_g") || originalName == "g") {
                                    // Determine the variable type based on initialization
                                    var varType = if (init != null) {
                                        switch (init.expr) {
                                            case TArrayDecl([]): "array";
                                            case TConst(TInt(_)): "counter";
                                            case _: "other";
                                        }
                                    } else {
                                        "nil";
                                    };
                                    
                                    // Check if this variable was already declared
                                    if (varDeclarations.exists(originalName)) {
                                        var declarations = varDeclarations.get(originalName);
                                        // If same variable is being reused with different type, rename BOTH
                                        if (declarations.length > 0) {
                                            var firstDecl = declarations[0];
                                            
                                            // Rename the first declaration if not already renamed
                                            if (firstDecl.newName == originalName) {
                                                var firstNewName = switch (firstDecl.type) {
                                                    case "array": originalName + "_array";
                                                    case "counter": originalName + "_counter";
                                                    case _: originalName + "_1";
                                                };
                                                firstDecl.newName = firstNewName;
                                                varRenamings.set(firstDecl.index, firstNewName);
                                            }
                                            
                                            // Create unique name for current declaration
                                            var newName = switch (varType) {
                                                case "array": originalName + "_array";
                                                case "counter": originalName + "_counter";
                                                case _: originalName + "_" + i;
                                            };
                                            varRenamings.set(i, newName);
                                            declarations.push({index: i, type: varType, newName: newName});
                                        }
                                    } else {
                                        // First declaration of this variable - keep original name for now
                                        varDeclarations.set(originalName, [{index: i, type: varType, newName: originalName}]);
                                    }
                                }
                            case _:
                        }
                    }
                    
                    // Second pass: compile with renamed variables if needed
                    if (varRenamings.keys().hasNext()) {
                        // We have renamings to apply - compile with renamed variables
                        var currentRenamings = new Map<String, String>();
                        var compiledStatements = [];
                        
                        for (i in 0...el.length) {
                            var expr = el[i];
                            var shouldInclude = true;
                            
                            // Check if this is an orphaned temp variable reference
                            switch (expr.expr) {
                                case TLocal(v):
                                    var varName = getOriginalVarName(v);
                                    // Check if this is just a standalone temp variable reference
                                    // that appears after a TEnumParameter extraction
                                    if (varName == "g" || varName.startsWith("g") && ~/^g\d*$/.match(varName)) {
                                        // Check if the previous expression was a TEnumParameter
                                        if (i > 0) {
                                            switch (el[i - 1].expr) {
                                                case TEnumParameter(_, _, _):
                                                    // This is an orphaned temp variable after enum parameter extraction
                                                    shouldInclude = false;
                                                case _:
                                            }
                                        }
                                    }
                                case _:
                            }
                            
                            if (!shouldInclude) continue;
                            
                            // Check if this expression is a variable declaration
                            switch (expr.expr) {
                                case TVar(tvar, init):
                                    var originalName = getOriginalVarName(tvar);
                                    
                                    // Check if this variable needs renaming
                                    if (varRenamings.exists(i)) {
                                        var newName = varRenamings.get(i);
                                        // Update the current active renaming for this variable
                                        currentRenamings.set(originalName, newName);
                                        
                                        // Compile with renamed variable
                                        var compiledInit = if (init != null) {
                                            compileExpressionWithRenaming(init, currentRenamings);
                                        } else {
                                            "nil";
                                        };
                                        compiledStatements.push('${newName} = ${compiledInit}');
                                        continue; // Skip normal compilation
                                    } else {
                                        // This variable declaration doesn't need renaming,
                                        // but it might shadow a previously renamed variable
                                        // Update the mapping to use the original name
                                        if (currentRenamings.exists(originalName)) {
                                            // This declaration shadows a renamed variable
                                            // From this point on, references should use the original name
                                            currentRenamings.set(originalName, originalName);
                                        }
                                    }
                                case _:
                            }
                            
                            // Compile expression with current renamings applied
                            var compiled = compileExpressionWithRenaming(expr, currentRenamings);
                            if (compiled != null && compiled.trim() != "") {
                                compiledStatements.push(compiled);
                            }
                        }
                        
                        // Return the compiled statements with renamings applied
                        return compiledStatements.join("\n");
                    }
                    
                    // No renamings needed - continue with normal compilation
                    // Filter out orphaned Haxe temp variable references
                    var filteredExpressions = [];
                    for (i in 0...el.length) {
                        var shouldInclude = true;
                        
                        // Check if this is an orphaned temp variable reference
                        switch (el[i].expr) {
                            case TLocal(v):
                                var varName = getOriginalVarName(v);
                                // Check if this is just a standalone temp variable reference
                                // that appears after a TEnumParameter extraction
                                if (varName == "g" || varName.startsWith("g") && ~/^g\d*$/.match(varName)) {
                                    // Check if the previous expression was a TEnumParameter
                                    if (i > 0) {
                                        switch (el[i - 1].expr) {
                                            case TEnumParameter(_, _, _):
                                                // This is an orphaned temp variable after enum parameter extraction
                                                shouldInclude = false;
                                            case _:
                                        }
                                    }
                                }
                            case _:
                        }
                        
                        if (shouldInclude) {
                            filteredExpressions.push(el[i]);
                        }
                    }
                    
                    // Use filtered expressions for the rest of the compilation
                    el = filteredExpressions;
                    
                    // Analyze all expressions for import requirements
                    importOptimizer.analyzeModule(el);
                    
                    // Check for pipeline optimization opportunities first
                    var pipelinePattern = pipelineOptimizer.detectPipelinePattern(el);
                    
                    if (pipelinePattern != null) {
                        // Register pipeline imports for later optimization
                        importOptimizer.registerPipelineImports([pipelinePattern]);
                        
                        // Generate idiomatic pipeline code
                        var pipelineCode = pipelineOptimizer.compilePipeline(pipelinePattern);
                        
                        // Handle remaining statements with proper ordering for terminal operations
                        var processedIndices = getProcessedStatementIndices(el, pipelinePattern);
                        var preStatements = [];
                        var terminalStatements = [];
                        
                        // Separate remaining expressions into pre-pipeline and terminal operations
                        var preExpressions = [];
                        var terminalExpressions = [];
                        for (i in 0...el.length) {
                            if (processedIndices.indexOf(i) == -1) {
                                var stmt = el[i];
                                if (isTerminalOperation(stmt, pipelinePattern.variable)) {
                                    terminalExpressions.push(stmt);
                                } else {
                                    preExpressions.push(stmt);
                                }
                            }
                        }
                        
                        // Compile pre-pipeline statements (variable declarations, etc.)
                        if (preExpressions.length > 0) {
                            preStatements = compileBlockExpressionsWithContext(preExpressions);
                        }
                        
                        // Compile terminal statements (Repo.all, etc.)
                        if (terminalExpressions.length > 0) {
                            terminalStatements = compileBlockExpressionsWithContext(terminalExpressions);
                        }
                        
                        // Combine in correct order: pre-statements, pipeline, terminal statements
                        var allStatements = [];
                        allStatements = allStatements.concat(preStatements);
                        allStatements.push(pipelineCode);
                        allStatements = allStatements.concat(terminalStatements);
                        
                        allStatements.join("\n");
                    } else {
                        // Check for temp variable assignment sequence: TIf with temp assignments + TBinop using temp var
                        var tempAssignSequence = detectTempVariableAssignmentSequence(el);
                        if (tempAssignSequence != null) {
                            // Transform the sequence: TIf with assignments + usage → optimized assignment
                            return optimizeTempVariableAssignmentSequence(tempAssignSequence, el);
                        }
                        
                        // Check for temp variable pattern: temp_var = nil; case...; temp_var
                        var tempVarPattern = detectTempVariablePattern(el);
                        if (tempVarPattern != null) {
                            // Found temp variable pattern
                            // Transform temp variable pattern to idiomatic case expression
                            return optimizeTempVariablePattern(tempVarPattern, el);
                        }
                        
                        // No pipeline pattern detected - use traditional compilation
                        // For multiple statements, compile each and join with newlines
                        // The last expression is the return value in Elixir
                        var compiledStatements = [];
                        
                        // Special handling for case arm context - convert field assignments to struct updates
                        if (isCompilingCaseArm && el.length > 0) {
                            var fieldUpdates = [];
                            var nonAssignmentStatements = [];
                            
                            for (i in 0...el.length) {
                                var stmt = el[i];
                                if (isFieldAssignment(stmt)) {
                                    // Convert field assignment to struct update mapping
                                    var update = extractFieldUpdate(stmt);
                                    if (update != null) {
                                        fieldUpdates.push(update);
                                    }
                                } else {
                                    var compiled = compileExpression(stmt);
                                    if (compiled != null && compiled.trim() != "") {
                                        nonAssignmentStatements.push(compiled);
                                    }
                                }
                            }
                            
                            // Generate final expression for case arm
                            if (fieldUpdates.length > 0) {
                                var structVar = currentFunctionParameterMap.get("this");
                                if (structVar == null) structVar = "struct";
                                
                                // Combine any non-assignment statements with struct update
                                var allStatements = nonAssignmentStatements.copy();
                                allStatements.push('%{${structVar} | ${fieldUpdates.join(", ")}}');
                                
                                allStatements.join("\n");
                            } else {
                                // No field assignments, proceed normally with preserved context
                                compiledStatements = compileBlockExpressionsWithContext(el);
                                compiledStatements.join("\n");
                            }
                        } else {
                            // Normal block compilation with preserved inline context
                            compiledStatements = compileBlockExpressionsWithContext(el);
                            compiledStatements.join("\n");
                        }
                    }
                }
                
            case TIf(econd, eif, eelse):
                // Track TIf statements for proper compilation
                var condStr = compileExpression(econd);
                // Condition processed
                
                // ENHANCED DEBUG: Specifically trace TFor patterns within TIf
                var containsTFor = checkForTForInExpression(eif);
                var containsReflectFields = checkForReflectFieldsInExpression(eif);
                if (containsTFor || containsReflectFields) {
                    // Found TFor or ReflectFields pattern - force block syntax
                }
                
                // Check if this is a temp variable assignment pattern in both branches
                var tempVarAssignPattern = detectTempVariableAssignmentPattern(eif, eelse);
                
                if (tempVarAssignPattern != null) {
                    // Handle temp variable assignment: if (...), do: temp_var = val1, else: temp_var = val2
                    // Transform to: temp_var = if (...), do: val1, else: val2
                    var cond = compileExpression(econd);
                    var thenValue = extractAssignmentValue(eif);
                    var elseValue = eelse != null ? extractAssignmentValue(eelse) : "nil";
                    return '${tempVarAssignPattern.varName} = if ${cond}, do: ${thenValue}, else: ${elseValue}';
                }
                
                var cond = compileExpression(econd);
                
                // CRITICAL: Check if the if-body or else-body contains multiple statements
                // This must be done BEFORE compiling to avoid syntax errors
                var needsBlockSyntax = containsMultipleStatements(eif) || 
                                      (eelse != null && containsMultipleStatements(eelse));
                
                // CRITICAL FIX: Check specifically for TWhile patterns that generate Y combinators
                // TWhile patterns generate complex multi-line expressions that MUST use block syntax
                var containsTWhilePattern = containsTWhileExpression(eif) || 
                                          (eelse != null && containsTWhileExpression(eelse));
                
                if (containsTWhilePattern) {
                    // Detected TWhile pattern - forcing block syntax
                    needsBlockSyntax = true;
                }
                
                // CRITICAL FIX: Force block syntax when compiling inside case arms
                // Case arms in Elixir have different semantics and inline if syntax causes issues
                var forceCaseArmBlockSyntax = isCompilingCaseArm;
                
                // Also check if the compiled expressions contain newlines
                var ifExpr = compileExpression(eif);
                var elseExpr = eelse != null ? compileExpression(eelse) : "nil";
                var hasNewlines = ifExpr.contains("\n") || (elseExpr != "nil" && elseExpr.contains("\n"));
                
                // CRITICAL FIX: Also check for Y combinator patterns which start with parenthesis
                // or contain anonymous function definitions which indicate complex multi-line code
                // ALSO check if the expression contains Reflect operations which will be desugared
                var hasComplexPattern = ifExpr.startsWith("(") || ifExpr.contains("fn ") || 
                                       ifExpr.contains("Reflect.") || ifExpr.contains("loop_helper") ||
                                       (elseExpr != "nil" && (elseExpr.startsWith("(") || elseExpr.contains("fn ") || 
                                                              elseExpr.contains("Reflect.") || elseExpr.contains("loop_helper")));
                
                // ADDITIONAL FIX: Force block syntax if the original AST indicates complexity
                // even if the compiled result looks simple (this catches partial compilation issues)
                var forceBlockSyntax = switch(eif.expr) {
                    case TBlock(exprs) if (exprs.length > 1): true;
                    case TFor(_, _, _): true;
                    case TWhile(_, _, _): true;
                    case _: false;
                };
                
                // Also check eelse for complexity
                var forceElseBlockSyntax = false;
                if (eelse != null) {
                    forceElseBlockSyntax = switch(eelse.expr) {
                        case TBlock(exprs) if (exprs.length > 1): true;
                        case TFor(_, _, _): true;
                        case TWhile(_, _, _): true;
                        case _: false;
                    };
                }
                
                // Use block syntax if any complexity is detected
                // Check for Y combinator patterns that require block syntax
                if (ifExpr.contains("loop_helper") || (elseExpr != null && elseExpr.contains("loop_helper"))) {
                    // Y combinator pattern detected in if or else clause - force block syntax to prevent ", else: nil" syntax errors
                    needsBlockSyntax = true;
                }
                
                // Check for complex expressions that start with parentheses and span multiple lines
                if (ifExpr.startsWith("(") && ifExpr.split("\n").length > 3) {
                    // Complex multi-line parenthesized expression - use block syntax for safety
                    needsBlockSyntax = true;
                }
                
                if (needsBlockSyntax || hasNewlines || hasComplexPattern || forceBlockSyntax || forceElseBlockSyntax || forceCaseArmBlockSyntax) {
                    var result = 'if ${cond} do\n';
                    result += ifExpr.split("\n").map(line -> line.length > 0 ? "  " + line : line).join("\n") + "\n";
                    if (eelse != null) {
                        result += 'else\n';
                        result += elseExpr.split("\n").map(line -> line.length > 0 ? "  " + line : line).join("\n") + "\n";
                    }
                    result += 'end';
                    result;
                } else {
                    // Only use inline syntax for truly simple expressions
                    'if ${cond}, do: ${ifExpr}, else: ${elseExpr}';
                }
                
            case TReturn(expr):
                if (expr != null) {
                    compileExpression(expr); // Elixir uses implicit returns
                } else {
                    "nil";
                }
                
            case TParenthesis(e):
                "(" + compileExpression(e) + ")";
                
            case TSwitch(e, cases, edef):
                compileSwitchExpression(e, cases, edef);
                
            case TFor(tvar, iterExpr, blockExpr):
                // Debug: Log TFor handling
                var varName = getOriginalVarName(tvar);
                
                // Compile TFor patterns to idiomatic Elixir
                var iteratorStr = compileExpression(iterExpr);
                
                // Compile for-in loops to idiomatic Elixir Enum operations
                compileForLoop(tvar, iterExpr, blockExpr);
                
            case TWhile(econd, ebody, normalWhile):
                // Process TWhile patterns
                
                // Try to detect and optimize common for-in loop patterns
                var optimized = tryOptimizeForInPattern(econd, ebody);
                if (optimized != null) {
                    // Used optimized for-in pattern
                    return optimized;
                }
                
                // Special case: Check if this is a Reflect.fields iteration
                // This handles cases where the pattern detection might miss it
                if (isReflectFieldsLoop(ebody)) {
                    // Used optimized Reflect.fields pattern
                    return optimizeReflectFieldsLoop(econd, ebody);
                }
                
                // Generate idiomatic Elixir recursive loop (Y combinator)
                // Generate Y combinator pattern for complex while loops
                var result = compileWhileLoop(econd, ebody, normalWhile);
                return result;
                
            case TArray(e1, e2):
                var arrayExpr = compileExpression(e1);
                var indexExpr = compileExpression(e2);
                'Enum.at(${arrayExpr}, ${indexExpr})';
                
            case TNew(c, _, el):
                var className = NamingHelper.getElixirModuleName(c.toString());
                var args = el.map(expr -> compileExpression(expr));
                
                // Check if this is a Map type and handle it idiomatically
                MapCompiler.isMapType(className) ? 
                    MapCompiler.compileMapConstructor(className, args) :
                    (function() {
                        var argString = args.join(", ");
                        return argString.length > 0 ? 
                            '${className}.new(${argString})' :
                            '${className}.new()';
                    })();
                
            case TFunction(func):
                // Get original parameter names (before Haxe's renaming)
                var args = func.args.map(arg -> NamingHelper.toSnakeCase(getOriginalVarName(arg.v))).join(", ");
                // Compile the body with proper type awareness for string concatenation
                var body = compileExpressionWithTypeAwareness(func.expr);
                'fn ${args} -> ${body} end';
                
            case TMeta(metadata, expr):
                // Compile metadata wrapper - just compile the inner expression
                compileExpression(expr);
                
            case TTry(tryExpr, catches):
                var tryBody = compileExpression(tryExpr);
                var result = 'try do\n  ${tryBody}\n';
                
                for (catchItem in catches) {
                    var catchVar = NamingHelper.toSnakeCase(getOriginalVarName(catchItem.v));
                    var catchBody = compileExpression(catchItem.expr);
                    result += 'rescue\n  ${catchVar} ->\n    ${catchBody}\n';
                }
                
                result + 'end';
                
            case TThrow(expr):
                var throwExpr = compileExpression(expr);
                'throw(${throwExpr})';
                
            case TCast(expr, moduleType):
                // Simple cast - just compile the expression
                // In Elixir, we rely on pattern matching for type safety
                compileExpression(expr);
                
            case TTypeExpr(moduleType):
                // Type expression - convert to Elixir module name
                switch (moduleType) {
                    case TClassDecl(c): NamingHelper.getElixirModuleName(c.get().name);
                    case TEnumDecl(e): NamingHelper.getElixirModuleName(e.get().name);
                    case TAbstract(a): NamingHelper.getElixirModuleName(a.get().name);
                    case _: "Dynamic";
                }
                
            case TBreak:
                // Break statement - in Elixir, we use a throw/catch pattern or early return
                "throw(:break)";
                
            case TContinue:
                // Continue statement - in Elixir, we use a throw/catch pattern or skip to next iteration
                "throw(:continue)";
                
            case TEnumIndex(e):
                // Get the index of an enum value - used for enum introspection
                // This is used in switch statements to determine which enum constructor is being matched
                var enumExpr = compileExpression(e);
                
                // Check if this is a Result or Option type which needs special tuple-based handling
                // Result types compile to Elixir tuples {:ok, value} and {:error, reason}
                // Option types compile to Elixir patterns {:ok, value} and :error
                // instead of standard enum modules, so introspection works differently
                var typeInfo = switch (e.t) {
                    case TEnum(enumType, _):
                        var enumTypeRef = enumType.get();
                        {
                            isResult: isResultType(enumTypeRef),
                            isOption: isOptionType(enumTypeRef)
                        };
                    case _:
                        {isResult: false, isOption: false};
                };
                
                if (typeInfo.isResult) {
                    // Result types use tuple pattern matching to get the constructor index
                    // {:ok, _} maps to index 0, {:error, _} maps to index 1
                    // This generates a case statement that extracts the "tag" from the tuple
                    'case ${enumExpr} do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end';
                } else if (typeInfo.isOption) {
                    // Option types use pattern matching to get the constructor index
                    // {:ok, _} maps to index 0, :error maps to index 1
                    // This generates a case statement that extracts the type from the pattern
                    'case ${enumExpr} do {:ok, _} -> 0; :error -> 1; _ -> -1 end';
                } else {
                    // Standard enums compile to tagged tuples like {:constructor_name, arg1, arg2}
                    // The first element (index 0) is always the constructor tag/atom
                    'elem(${enumExpr}, 0)'; // Extract the constructor atom from tuple
                }
                
            case TEnumParameter(e, ef, index):
                // Extract a parameter from an enum constructor
                // Used when accessing constructor arguments in pattern matching or introspection
                var enumExpr = compileExpression(e);
                
                // Check if this is a Result or Option type which uses different tuple structure
                var typeInfo = switch (e.t) {
                    case TEnum(enumType, _):
                        var enumTypeRef = enumType.get();
                        {
                            isResult: isResultType(enumTypeRef),
                            isOption: isOptionType(enumTypeRef)
                        };
                    case _:
                        {isResult: false, isOption: false};
                };
                
                if (typeInfo.isResult) {
                    // Result types have a simple 2-element tuple structure: {:ok, value} or {:error, reason}
                    // Both constructors have exactly one parameter at the same position
                    if (index == 0) {
                        // Extract the value from either {:ok, value} or {:error, value}
                        // Uses pattern matching to safely extract from either constructor
                        'case ${enumExpr} do {:ok, value} -> value; {:error, value} -> value; _ -> nil end';
                    } else {
                        // Result types only have one parameter, so index > 0 should not occur
                        // Return nil for safety if this happens
                        'nil';
                    }
                } else if (typeInfo.isOption) {
                    // Option types have either {:ok, value} or :error
                    // Only Some has a parameter (index 0), None has no parameters
                    if (index == 0) {
                        // Extract the value from {:ok, value}, return nil for :error
                        'case ${enumExpr} do {:ok, value} -> value; :error -> nil; _ -> nil end';
                    } else {
                        // Option types only have one parameter in Some, so index > 0 should not occur
                        // Return nil for safety if this happens
                        'nil';
                    }
                } else {
                    // Standard enums compile to tuples like {:constructor, param1, param2, ...}
                    // Parameters start at index 1 (index 0 is the constructor tag)
                    // So we add 1 to the parameter index to get the correct tuple position
                    'elem(${enumExpr}, ${index + 1})';
                }
                
            case _:
                // Handle unknown expression types gracefully
                // Warning: Unhandled expression type
                "nil";
        }
    }
    
    /**
     * Compile switch expression to Elixir case statement with advanced pattern matching
     * Supports enum patterns, guard clauses, binary patterns, and pin operators
     */
    private function compileSwitchExpression(switchExpr: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, defaultExpr: Null<TypedExpr>): String {
        // Use PatternMatcher for complete switch expression compilation
        if (patternMatcher == null) {
            patternMatcher = new reflaxe.elixir.helpers.PatternMatcher();
            patternMatcher.setCompiler(this);
        }
        
        // Check for exhaustive pattern matching and warn if incomplete
        var exhaustivenessWarnings = patternMatcher.validatePatternExhaustiveness(switchExpr, cases, defaultExpr);
        for (warning in exhaustivenessWarnings) {
            haxe.macro.Context.warning(warning, switchExpr.pos);
        }
        
        // Check if this is a Result pattern that should use with statements
        if (shouldUseWithStatement(switchExpr, cases)) {
            return compileWithStatement(switchExpr, cases, defaultExpr);
        }
        
        // Use PatternMatcher's comprehensive switch compilation
        return patternMatcher.compileSwitchExpression(switchExpr, cases, defaultExpr);
    }
    
    /**
     * Check if switch expression should use with statement instead of case
     * Returns true for Result patterns that benefit from Elixir's with syntax
     */
    private function shouldUseWithStatement(switchExpr: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>): Bool {
        // Detect Result patterns that chain operations - ideal for with statements
        if (cases.length >= 2) {
            var hasSuccessPattern = false;
            var hasErrorPattern = false;
            
            for (caseItem in cases) {
                for (value in caseItem.values) {
                    if (isResultSuccessPattern(value)) hasSuccessPattern = true;
                    if (isResultErrorPattern(value)) hasErrorPattern = true;
                }
            }
            
            return hasSuccessPattern && hasErrorPattern;
        }
        
        return false;
    }
    
    /**
     * Compile Result patterns using Elixir's with statement
     * Generates idiomatic with/else syntax for Result chaining
     */
    private function compileWithStatement(switchExpr: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, defaultExpr: Null<TypedExpr>): String {
        var result = new StringBuf();
        var switchValue = compileExpression(switchExpr);
        
        result.add('with ');
        
        var successCases = [];
        var errorCases = [];
        
        // Separate success and error patterns
        for (caseItem in cases) {
            for (value in caseItem.values) {
                if (isResultSuccessPattern(value)) {
                    successCases.push({pattern: value, expr: caseItem.expr});
                } else if (isResultErrorPattern(value)) {
                    errorCases.push({pattern: value, expr: caseItem.expr});
                }
            }
        }
        
        // Generate with clause for success pattern
        if (successCases.length > 0) {
            var successCase = successCases[0];
            var pattern = patternMatcher.compilePattern(successCase.pattern);
            result.add('${pattern} <- ${switchValue} do\n');
            
            var successExpr = compileExpression(successCase.expr);
            result.add('  ${successExpr}\n');
        }
        
        // Generate else clause for error patterns
        if (errorCases.length > 0) {
            result.add('else\n');
            
            for (errorCase in errorCases) {
                var pattern = patternMatcher.compilePattern(errorCase.pattern);
                var errorExpr = compileExpression(errorCase.expr);
                result.add('  ${pattern} -> ${errorExpr}\n');
            }
        }
        
        // Add default case to else if present
        if (defaultExpr != null) {
            if (errorCases.length == 0) result.add('else\n');
            var defaultCode = compileExpression(defaultExpr);
            result.add('  _ -> ${defaultCode}\n');
        }
        
        result.add('end');
        return result.toString();
    }
    
    /**
     * Check if pattern represents Result success case
     */
    private function isResultSuccessPattern(pattern: TypedExpr): Bool {
        // This is a simplified check - in practice would analyze the pattern more thoroughly
        var patternStr = patternMatcher.compilePattern(pattern);
        return patternStr.indexOf(":ok") >= 0 || patternStr.indexOf("success") >= 0;
    }
    
    /**
     * Check if pattern represents Result error case
     */
    private function isResultErrorPattern(pattern: TypedExpr): Bool {
        // This is a simplified check - in practice would analyze the pattern more thoroughly
        var patternStr = patternMatcher.compilePattern(pattern);
        return patternStr.indexOf(":error") >= 0 || patternStr.indexOf("error") >= 0;
    }
    
    /**
     * Check if an enum type is the Result<T,E> type
     * @deprecated Use AlgebraicDataTypeCompiler.isADTType() instead
     */
    private function isResultType(enumType: EnumType): Bool {
        return AlgebraicDataTypeCompiler.isADTType(enumType) && 
               enumType.name == "Result";
    }
    
    /**
     * Check if an enum type is the Option<T> type
     * @deprecated Use AlgebraicDataTypeCompiler.isADTType() instead
     */
    private function isOptionType(enumType: EnumType): Bool {
        return AlgebraicDataTypeCompiler.isADTType(enumType) && 
               enumType.name == "Option";
    }
    
    /**
     * Extract enum type and field information from an expression
     */
    private function extractEnumInfo(expr: TypedExpr): Null<{enumType: haxe.macro.Ref<EnumType>, enumField: EnumField}> {
        return switch (expr.expr) {
            case TField(_, FEnum(enumType, enumField)):
                {enumType: enumType, enumField: enumField};
            case _:
                null;
        }
    }
    
    /**
     * Compile Result enum constructor to proper Elixir tuple
     * @deprecated Use AlgebraicDataTypeCompiler.compileADTPattern() instead
     */
    private function compileResultPattern(enumField: EnumField, args: Array<TypedExpr>): String {
        // Find the Result enum type - this is a bit hacky but works for backward compatibility
        var resultEnum = null;
        try {
            var resultType = haxe.macro.Context.getType("haxe.functional.Result");
            switch (resultType) {
                case TEnum(enumRef, _):
                    resultEnum = enumRef.get();
                case _:
            }
        } catch (e: Dynamic) {
            // Fallback if type not found
        }
        
        if (resultEnum != null) {
            var compiled = AlgebraicDataTypeCompiler.compileADTPattern(resultEnum, enumField, args, (expr) -> compilePatternArgument(expr));
            if (compiled != null) return compiled;
        }
        
        // Fallback to original logic for unknown patterns
        var fieldName = enumField.name.toLowerCase();
        var snakeName = NamingHelper.toSnakeCase(fieldName);
        if (args.length == 0) {
            return ':${snakeName}';
        } else if (args.length == 1) {
            var argPattern = compilePatternArgument(args[0]);
            return '{:${snakeName}, ${argPattern}}';
        } else {
            var argPatterns = args.map(compilePatternArgument);
            return '{:${snakeName}, ${argPatterns.join(', ')}}';
        }
    }
    
    /**
     * Compile Option enum constructor to proper Elixir pattern
     * @deprecated Use AlgebraicDataTypeCompiler.compileADTPattern() instead
     */
    private function compileOptionPattern(enumField: EnumField, args: Array<TypedExpr>): String {
        // Find the Option enum type - this is a bit hacky but works for backward compatibility
        var optionEnum = null;
        try {
            var optionType = haxe.macro.Context.getType("haxe.ds.Option");
            switch (optionType) {
                case TEnum(enumRef, _):
                    optionEnum = enumRef.get();
                case _:
            }
        } catch (e: Dynamic) {
            // Fallback if type not found
        }
        
        if (optionEnum != null) {
            var compiled = AlgebraicDataTypeCompiler.compileADTPattern(optionEnum, enumField, args, (expr) -> compilePatternArgument(expr));
            if (compiled != null) return compiled;
        }
        
        // Fallback to original logic for unknown patterns
        var fieldName = enumField.name.toLowerCase();
        var snakeName = NamingHelper.toSnakeCase(fieldName);
        return ':${snakeName}';
    }
    
    /**
     * Compile enum constructor pattern for case matching
     */
    private function compileEnumPattern(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TField(_, FEnum(enumType, enumField)):
                // Check if this is a known algebraic data type (Result, Option, etc.)
                var enumTypeRef = enumType.get();
                if (AlgebraicDataTypeCompiler.isADTType(enumTypeRef)) {
                    var compiled = AlgebraicDataTypeCompiler.compileADTPattern(enumTypeRef, enumField, [], (expr) -> compilePatternArgument(expr));
                    if (compiled != null) return compiled;
                }
                // Simple enum pattern: SomeEnum.Option → :option
                var fieldName = NamingHelper.toSnakeCase(enumField.name);
                ':${fieldName}';
                
            case TCall(e, args) if (isEnumFieldAccess(e)):
                // Check if this is a known algebraic data type constructor call
                var enumInfo = extractEnumInfo(e);
                if (enumInfo != null && AlgebraicDataTypeCompiler.isADTType(enumInfo.enumType.get())) {
                    var compiled = AlgebraicDataTypeCompiler.compileADTPattern(enumInfo.enumType.get(), enumInfo.enumField, args, (expr) -> compilePatternArgument(expr));
                    if (compiled != null) return compiled;
                }
                
                // Parameterized enum pattern: SomeEnum.Option(value) → {:option, value}
                var fieldName = extractEnumFieldName(e);
                if (args.length == 0) {
                    ':${fieldName}';
                } else if (args.length == 1) {
                    var argPattern = compilePatternArgument(args[0]);
                    '{:${fieldName}, ${argPattern}}';
                } else {
                    var argPatterns = args.map(compilePatternArgument);
                    '{:${fieldName}, ${argPatterns.join(', ')}}';
                }
                
            case TConst(constant):
                // Literal constants in switch
                compileTConstant(constant);
                
            case _:
                // Fallback - compile as regular expression
                compileExpression(expr);
        }
    }
    
    /**
     * Compile pattern argument (variable binding or literal)
     */
    private function compilePatternArgument(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TLocal(v):
                // Variable binding in pattern
                var originalName = getOriginalVarName(v);
                NamingHelper.toSnakeCase(originalName);
                
            case TConst(constant):
                // Literal in pattern
                compileTConstant(constant);
                
            case _:
                // Wildcard or complex pattern
                "_";
        }
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
    private function compileFunction(funcField: ClassFuncData, isStatic: Bool = false): String {
        var funcName = NamingHelper.getElixirFunctionName(funcField.field.name);
        
        // Build parameter list - check for LiveView callback override first
        var paramStr = "";
        var liveViewParams = reflaxe.elixir.LiveViewCompiler.getLiveViewCallbackParams(funcName);
        
        if (liveViewParams != null) {
            // Use LiveView-specific parameter names for callbacks
            paramStr = liveViewParams;
        } else {
            // Use actual parameter names converted to snake_case for regular functions
            var params = [];
            for (i in 0...funcField.args.length) {
                var arg = funcField.args[i];
                // Get the actual parameter name from tvar (consistent with setFunctionParameterMapping)
                var originalName = if (arg.tvar != null) {
                    arg.tvar.name;
                } else {
                    // Fallback to getName() if tvar is not available
                    arg.getName();
                }
                var paramName = NamingHelper.toSnakeCase(originalName);
                params.push(paramName);
            }
            paramStr = params.join(", ");
        }
        var result = '  @doc "Generated from Haxe ${funcField.field.name}"\n';
        result += '  def ${funcName}(${paramStr}) do\n';
        
        if (funcField.expr != null) {
            // Check if function body is a TBlock that could benefit from pipeline optimization
            var compiledBody = switch(funcField.expr.expr) {
                case TBlock(el) if (el.length > 1):
                    // Check for pipeline optimization opportunities in function body
                    var pipelinePattern = pipelineOptimizer.detectPipelinePattern(el);
                    
                    if (pipelinePattern != null) {
                        
                        // Handle remaining statements with proper ordering for terminal operations
                        var processedIndices = getProcessedStatementIndices(el, pipelinePattern);
                        var preStatements = [];
                        
                        // Separate remaining expressions into pre-pipeline and potential terminal operations
                        var preExpressions = [];
                        var terminalReturnExpr: TypedExpr = null;
                        
                        for (i in 0...el.length) {
                            if (processedIndices.indexOf(i) == -1) {
                                var stmt = el[i];
                                
                                // Check if this is a TReturn with a terminal operation that uses our pipeline variable
                                switch(stmt.expr) {
                                    case TReturn(returnExpr) if (returnExpr != null):
                                        if (isTerminalOperationOnVariable(returnExpr, pipelinePattern.variable)) {
                                            // This return contains a terminal operation on our pipeline variable
                                            terminalReturnExpr = returnExpr;
                                        } else {
                                            preExpressions.push(stmt);
                                        }
                                    case _:
                                        if (isTerminalOperation(stmt, pipelinePattern.variable)) {
                                            // Direct terminal operation (not in return)
                                            terminalReturnExpr = stmt;
                                        } else {
                                            preExpressions.push(stmt);
                                        }
                                }
                            }
                        }
                        
                        // Compile pre-pipeline statements (variable declarations, etc.)
                        if (preExpressions.length > 0) {
                            preStatements = compileBlockExpressionsWithContext(preExpressions);
                        }
                        
                        // Generate pipeline with integrated terminal operation
                        var finalPipelineCode: String;
                        if (terminalReturnExpr != null) {
                            // Extract the terminal function call from the return expression
                            var terminalCall = extractTerminalCall(terminalReturnExpr, pipelinePattern.variable);
                            if (terminalCall != null) {
                                // Generate pipeline ending with terminal operation
                                var pipelineCode = pipelineOptimizer.compilePipeline(pipelinePattern);
                                finalPipelineCode = pipelineCode + "\n  |> " + terminalCall;
                            } else {
                                // Fallback: use original pipeline + compile terminal separately
                                var pipelineCode = pipelineOptimizer.compilePipeline(pipelinePattern);
                                var terminalCode = compileExpression(terminalReturnExpr);
                                finalPipelineCode = pipelineCode + "\n" + terminalCode;
                            }
                        } else {
                            // No terminal operation found - use regular pipeline
                            finalPipelineCode = pipelineOptimizer.compilePipeline(pipelinePattern);
                        }
                        
                        // Combine: pre-statements + integrated pipeline
                        var allParts = [];
                        if (preStatements.length > 0) allParts = allParts.concat(preStatements);
                        allParts.push(finalPipelineCode);
                        
                        allParts.join("\n");
                    } else {
                        // No pipeline pattern - use regular compilation
                        compileExpression(funcField.expr);
                    }
                    
                case _:
                    // Not a multi-statement block - use regular compilation
                    compileExpression(funcField.expr);
            };
            
            if (compiledBody != null && compiledBody.trim() != "") {
                // Indent the function body properly
                var indentedBody = compiledBody.split("\n").map(line -> line.length > 0 ? "    " + line : line).join("\n");
                result += '${indentedBody}\n';
            } else {
                // Only use nil if compilation actually failed/returned empty
                result += '    nil\n';
            }
        } else {
            // No expression provided - this is a truly empty function
            result += '    nil\n';
        }
        result += '  end\n\n';
        
        return result;
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
    private function compileConstant(constant: Constant): String {
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
    private function compileTConstant(constant: TConstant): String {
        return switch (constant) {
            case TInt(i): Std.string(i);
            case TFloat(s): s;
            case TString(s): 
                // Properly escape string content for Elixir
                var escaped = StringTools.replace(s, '\\', '\\\\'); // Escape backslashes first
                escaped = StringTools.replace(escaped, '"', '\\"');  // Escape double quotes
                escaped = StringTools.replace(escaped, '\n', '\\n'); // Escape newlines
                escaped = StringTools.replace(escaped, '\r', '\\r'); // Escape carriage returns
                escaped = StringTools.replace(escaped, '\t', '\\t'); // Escape tabs
                '"${escaped}"';
            case TBool(b): b ? "true" : "false";
            case TNull: "nil";
            case TThis: 
                // Check if 'this' should be mapped to a parameter (e.g., 'struct' in instance methods)
                var mappedName = currentFunctionParameterMap.get("this");
                mappedName != null ? mappedName : "__MODULE__"; // Default to __MODULE__ if no mapping
            case TSuper: "\"Exception\""; // Elixir doesn't have super() - return base type string
            case _: "nil";
        }
    }
    
    /**
     * Compile expression with proper type awareness for operators.
     * This ensures string concatenation uses <> and not +.
     */
    private function compileExpressionWithTypeAwareness(expr: TypedExpr): String {
        if (expr == null) return "nil";
        
        // For binary operations, check if we need special handling
        switch (expr.expr) {
            case TBinop(OpAdd, e1, e2):
                // Check if either operand is a string type
                var e1IsString = isStringType(e1.t);
                var e2IsString = isStringType(e2.t);
                var isStringConcat = e1IsString || e2IsString;
                
                if (isStringConcat) {
                    // Handle string constants directly to preserve quotes
                    var left = switch (e1.expr) {
                        case TConst(TString(s)): 
                            // Properly escape and quote the string
                            var escaped = StringTools.replace(s, '\\', '\\\\');
                            escaped = StringTools.replace(escaped, '"', '\\"');
                            escaped = StringTools.replace(escaped, '\n', '\\n');
                            escaped = StringTools.replace(escaped, '\r', '\\r');
                            escaped = StringTools.replace(escaped, '\t', '\\t');
                            '"${escaped}"';
                        case _: compileExpressionWithTypeAwareness(e1);
                    };
                    
                    var right = switch (e2.expr) {
                        case TConst(TString(s)): 
                            // Properly escape and quote the string
                            var escaped = StringTools.replace(s, '\\', '\\\\');
                            escaped = StringTools.replace(escaped, '"', '\\"');
                            escaped = StringTools.replace(escaped, '\n', '\\n');
                            escaped = StringTools.replace(escaped, '\r', '\\r');
                            escaped = StringTools.replace(escaped, '\t', '\\t');
                            '"${escaped}"';
                        case _: compileExpressionWithTypeAwareness(e2);
                    };
                    
                    // Convert non-string operands to strings
                    if (!e1IsString && e2IsString) {
                        left = convertToString(e1, left);
                    } else if (e1IsString && !e2IsString) {
                        right = convertToString(e2, right);
                    }
                    
                    return '${left} <> ${right}';
                } else {
                    var left = compileExpressionWithTypeAwareness(e1);
                    var right = compileExpressionWithTypeAwareness(e2);
                    return '${left} + ${right}';
                }
                
            case TBinop(op, e1, e2):
                var left = compileExpressionWithTypeAwareness(e1);
                var right = compileExpressionWithTypeAwareness(e2);
                return '${left} ${compileBinop(op)} ${right}';
                
            case _:
                // For all other cases, use regular compilation
                return compileExpression(expr);
        }
    }
    
    /**
     * Check if a Type is a string type
     */
    private function isStringType(type: Type): Bool {
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
    private function convertToString(expr: TypedExpr, compiledExpr: String): String {
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
    private function compileBinop(op: Binop): String {
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
                var mappedName = currentFunctionParameterMap.get("this");
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
        // Preserve any existing 'this' mappings for struct instance methods
        var savedThisMapping = currentFunctionParameterMap.get("this");
        var savedThisMapping2 = currentFunctionParameterMap.get("struct");
        
        currentFunctionParameterMap.clear();
        inlineContextMap.clear(); // Reset inline context for new function
        isCompilingAbstractMethod = true;
        
        // Restore 'this' mappings if they existed
        if (savedThisMapping != null) {
            currentFunctionParameterMap.set("this", savedThisMapping);
        }
        if (savedThisMapping2 != null) {
            currentFunctionParameterMap.set("struct", savedThisMapping2);
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
     * Set up parameter mapping for 'this' references in struct instance methods
     */
    public function setThisParameterMapping(structParamName: String): Void {
        // Map 'this' references to the struct parameter name
        currentFunctionParameterMap.set("this", structParamName);
        // Also handle variations like _this which Haxe might generate
        currentFunctionParameterMap.set("struct", structParamName);
    }
    
    /**
     * Clear 'this' parameter mapping after function compilation
     */
    public function clearThisParameterMapping(): Void {
        // Remove 'this' mappings while preserving other parameter mappings
        currentFunctionParameterMap.remove("this");
        currentFunctionParameterMap.remove("struct");
    }
    
    /**
     * Helper methods for managing inline function context
     */
    private function setInlineContext(varName: String, value: String): Void {
        inlineContextMap.set(varName, value);
    }
    
    private function getInlineContext(varName: String): Null<String> {
        return inlineContextMap.get(varName);
    }
    
    private function hasInlineContext(varName: String): Bool {
        return inlineContextMap.exists(varName);
    }
    
    public function clearInlineContext(): Void {
        inlineContextMap.clear();
    }
    
    /**
     * Get the effective variable name for 'this' references, considering inline context and LiveView
     */
    private function resolveThisReference(): String {
        // First check if we're in an inline context where struct is active
        if (hasInlineContext("struct")) {
            return "struct";
        }
        
        // Check if we're in a LiveView class - in this case, 'this' references are invalid
        // because LiveView instance variables should be accessed through socket.assigns
        if (liveViewInstanceVars != null) {
            // Return a special marker that indicates this should not be used directly
            return "__LIVEVIEW_THIS__";
        }
        
        // Fall back to parameter mapping
        var mapped = currentFunctionParameterMap.get("this");
        var result = mapped != null ? mapped : "struct";
        return result;
    }
    
    /**
     * Check if a TLocal variable represents a function being passed as a reference
     * 
     * @param v The TVar representing the local variable
     * @param originalName The original name of the variable
     * @return true if this is a function reference, false otherwise
     */
    private function isFunctionReference(v: TVar, originalName: String): Bool {
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
    private function generateFunctionReference(functionName: String): String {
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
    private function getCurrentModuleName(): String {
        if (currentClassType != null) {
            // Use the current class name as the module name
            return currentClassType.name;
        }
        return "UnknownModule";
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
        var compiledStatements = [];
        
        // Compile each expression while maintaining inline context
        // DO NOT save/restore context - we want inline context to persist across expressions
        for (i in 0...expressions.length) {
            var compiled = compileExpression(expressions[i]);
            if (compiled != null && compiled.trim() != "") {
                compiledStatements.push(compiled);
            }
        }
        
        return compiledStatements;
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
        // Check for repository operations (Repo.method calls)
        switch (e.expr) {
            case TField(obj, fa):
                var methodName = getFieldName(fa);
                var objStr = compileExpression(obj);
                
                // Detect Phoenix.PubSub operations
                if (objStr == "Phoenix.PubSub" || objStr == "PubSub") {
                    var compiledArgs = args.map(arg -> compileExpression(arg));
                    
                    // PubSub methods need the app's PubSub module as first argument
                    var appName = getCurrentAppName();
                    var pubsubModule = '${appName}.PubSub';
                    
                    switch (methodName) {
                        case "subscribe":
                            // Phoenix.PubSub.subscribe(TodoApp.PubSub, topic)
                            return 'Phoenix.PubSub.subscribe(${pubsubModule}, ${compiledArgs.join(", ")})';
                        case "broadcast":
                            // Phoenix.PubSub.broadcast(TodoApp.PubSub, topic, message)
                            return 'Phoenix.PubSub.broadcast(${pubsubModule}, ${compiledArgs.join(", ")})';
                        case "broadcast_from":
                            // Phoenix.PubSub.broadcast_from(TodoApp.PubSub, from_pid, topic, message)
                            return 'Phoenix.PubSub.broadcast_from(${pubsubModule}, ${compiledArgs.join(", ")})';
                        default:
                            // Other PubSub methods
                            return 'Phoenix.PubSub.${methodName}(${pubsubModule}, ${compiledArgs.join(", ")})';
                    }
                }
                
                // Detect HXX template function calls
                if (objStr == "HXX" && methodName == "hxx") {
                    return compileHxxCall(args);
                }
                
                // Also handle direct hxx() calls (via import HXX.*)
                if (methodName == "hxx" && args.length == 1) {
                    // Check if this is likely an HXX call based on context
                    switch (obj.expr) {
                        case TField({expr: TTypeExpr(_)}, FStatic(c, _)):
                            var className = c.get().name;
                            if (className == "HXX") {
                                return compileHxxCall(args);
                            }
                        case _:
                    }
                }
                
                // Detect Map method calls and transform to idiomatic Elixir
                if (MapCompiler.isMapMethod(methodName)) {
                    // Check if the object is a Map type or if this is a Map method call
                    // We need to determine this from the object's type or compilation context
                    var isMapObject = false;
                    
                    // First check the object's type information - most accurate
                    switch (obj.t) {
                        case TInst(t, _):
                            var typeName = t.get().name;
                            if (MapCompiler.isMapType(typeName)) {
                                isMapObject = true;
                            }
                        case TAbstract(t, _):
                            var typeName = t.get().name;
                            // Check for Map abstract types
                            if (typeName == "Map" || typeName.contains("Map")) {
                                isMapObject = true;
                            }
                        case _:
                    }
                    
                    // Fallback: Check if objStr looks like a map variable or map expression
                    if (!isMapObject) {
                        if (objStr.contains("Map.") || objStr.contains("%{") || 
                            objStr.contains("map") || objStr.contains("_map") ||
                            // Check common map variable names
                            objStr == "map" || objStr.endsWith("_map") || objStr.endsWith("Map") ||
                            // Also check for variables that might be maps based on naming
                            objStr.contains("conditions") || objStr.contains("params") || 
                            objStr.contains("attributes") || objStr.contains("data")) {
                            isMapObject = true;
                        }
                    }
                    
                    if (isMapObject) {
                        var compiledArgs = args.map(arg -> compileExpression(arg));
                        return MapCompiler.compileMapMethod(objStr, methodName, compiledArgs);
                    }
                }
                
                // Detect Repo operations
                if (objStr == "Repo") {
                    var compiledArgs = args.map(arg -> compileExpression(arg));
                    var schemaName = detectSchemaFromArgs(args);
                    
                    // Special handling for @:native methods like get!
                    if (methodName == "getBang") {
                        methodName = "get!";
                    }
                    
                    return RepositoryCompiler.compileRepoCall(methodName, compiledArgs, schemaName);
                }
                
                // Check if this is an algebraic data type constructor call (Result, Option, etc.)
                switch (fa) {
                    case FEnum(enumType, enumField):
                        var enumTypeRef = enumType.get();
                        if (AlgebraicDataTypeCompiler.isADTType(enumTypeRef)) {
                            // Handle standard library ADT types with idiomatic patterns
                            var compiled = AlgebraicDataTypeCompiler.compileADTPattern(enumTypeRef, enumField, args, (expr) -> compileExpression(expr));
                            if (compiled != null) return compiled;
                        } else {
                            // Handle user-defined enums with literal patterns
                            var fieldName = NamingHelper.toSnakeCase(enumField.name);
                            if (args.length == 0) {
                                return ':${fieldName}';
                            } else {
                                var compiledArgs = args.map(arg -> compileExpression(arg));
                                if (args.length == 1) {
                                    return '{:${fieldName}, ${compiledArgs[0]}}';
                                } else {
                                    return '{:${fieldName}, ${compiledArgs.join(", ")}}';
                                }
                            }
                        }
                    case _:
                }
                
                // Check if this is a String method call
                switch (obj.t) {
                    case TInst(t, _) if (t.get().name == "String"):
                        return compileStringMethod(objStr, methodName, args);
                    case _:
                        // Continue with normal method call handling
                }
                
                // Check if this is a static extension call from OptionTools, ResultTools, or ArrayTools
                // Haxe's 'using' transforms user.map() into OptionTools.map(user, ...) 
                if (objStr == "OptionTools" && isOptionMethod(methodName)) {
                    var compiledArgs = args.map(arg -> compileExpression(arg));
                    return 'OptionTools.${methodName}(${compiledArgs.join(", ")})';
                } else if (objStr == "ResultTools" && isResultMethod(methodName)) {
                    var compiledArgs = args.map(arg -> compileExpression(arg));
                    return 'ResultTools.${methodName}(${compiledArgs.join(", ")})';
                } else if (objStr == "ArrayTools" && isArrayMethod(methodName)) {
                    // ArrayTools static extensions need to be compiled to idiomatic Elixir Enum calls
                    // The first argument is the array, remaining arguments are method parameters
                    if (args.length > 0) {
                        var arrayExpr = compileExpression(args[0]);  // First arg is the array
                        var methodArgs = args.slice(1);             // Remaining args are method parameters
                        return compileArrayMethod(arrayExpr, methodName, methodArgs);
                    } else {
                        // Fallback for methods with no arguments
                        return 'ArrayTools.${methodName}()';
                    }
                } else if (objStr == "MapTools" && isMapMethod(methodName)) {
                    // MapTools static extensions need to be compiled to idiomatic Elixir Map calls
                    // The first argument is the map, remaining arguments are method parameters
                    if (args.length > 0) {
                        var mapExpr = compileExpression(args[0]);    // First arg is the map
                        var methodArgs = args.slice(1);             // Remaining args are method parameters
                        return compileMapMethod(mapExpr, methodName, methodArgs);
                    } else {
                        // Fallback for methods with no arguments
                        return 'MapTools.${methodName}()';
                    }
                }
                
                // Check if this is an ADT type (Option<T>, Result<T,E>, etc.) with static extension methods
                switch (obj.t) {
                    case TEnum(enumRef, _):
                        var enumType = enumRef.get();
                        var compiled = compileADTStaticExtension(enumType, methodName, objStr, args);
                        if (compiled != null) return compiled;
                    case _:
                        // Continue with normal method call handling
                }
                
                // Check if this is an Array method call
                switch (obj.t) {
                    case TInst(t, _) if (t.get().name == "Array"):
                        return compileArrayMethod(objStr, methodName, args);
                    case _:
                        // Continue with normal method call handling
                }
                
                // Check if this is a common array method on a Dynamic type
                // This handles cases where we're calling array methods on Dynamic typed values
                if (isArrayMethod(methodName)) {
                    return compileArrayMethod(objStr, methodName, args);
                }
                
                // Handle other method calls normally
                var compiledArgs = args.map(arg -> compileExpression(arg));
                
                // Check for standard library ADT constructor calls that weren't detected as FEnum
                // Only applies to actual standard library types, not user-defined enums with same names
                if (AlgebraicDataTypeCompiler.isADTTypeName(objStr)) {
                    var config = AlgebraicDataTypeCompiler.getADTConfigByTypeName(objStr);
                    if (config != null) {
                        // Verify this is actually the standard library type, not a user-defined type
                        var enumType = null;
                        try {
                            var fullTypeName = '${config.moduleName}.${config.typeName}';
                            var adtType = haxe.macro.Context.getType(fullTypeName);
                            switch (adtType) {
                                case TEnum(enumRef, _):
                                    enumType = enumRef.get();
                                    // Additional check: ensure this is actually an ADT type
                                    if (!AlgebraicDataTypeCompiler.isADTType(enumType)) {
                                        enumType = null; // Not actually a standard library ADT
                                    }
                                case _:
                            }
                        } catch (e: Dynamic) {
                            // Fallback if type not found - definitely not a standard library type
                        }
                        
                        if (enumType != null) {
                            // Create a fake enum field for the method call
                            var fakeField = null;
                            for (field in enumType.constructs) {
                                if (field.name.toLowerCase() == methodName.toLowerCase()) {
                                    fakeField = field;
                                    break;
                                }
                            }
                            
                            if (fakeField != null) {
                                var compiled = AlgebraicDataTypeCompiler.compileADTMethodCall(enumType, methodName, args, (expr) -> compileExpression(expr));
                                if (compiled != null) return compiled;
                            }
                        }
                    }
                }
                
                // Check if methodName already contains a module path (from @:native annotation)
                if (methodName.indexOf(".") >= 0) {
                    // Native method with full path - use it directly
                    return '${methodName}(${compiledArgs.join(", ")})';
                } else {
                    // Regular method call - concatenate with object
                    return '${objStr}.${methodName}(${compiledArgs.join(", ")})';
                }
                
            case _:
                // Check for direct hxx() calls (via import HXX.*)
                var functionName = compileExpression(e);
                if (functionName == "hxx") {
                    return compileHxxCall(args);
                }
                
                // Regular function call
                var compiledArgs = args.map(arg -> compileExpression(arg));
                var functionName = compileExpression(e);
                
                // Check if this is an anonymous function call (function parameter)
                // In Elixir, function parameters need dot syntax: fn.(args) instead of fn(args)
                // This includes reserved keywords (ending with _) and regular function parameters
                var isFunctionParameter = (functionName.endsWith("_") || 
                    (functionName.toLowerCase() == functionName && // snake_case (likely parameter)
                     !functionName.contains(".") && 
                     !functionName.contains(" ") &&
                     functionName.length > 1 && // not single chars
                     functionName != "nil" && // not literals
                     functionName != "true" &&
                     functionName != "false"));
                     
                if (isFunctionParameter) {
                    return functionName + ".(" + compiledArgs.join(", ") + ")";
                } else {
                    return functionName + "(" + compiledArgs.join(", ") + ")";
                }
        }
    }
    
    /**
     * Compile for-in loops to idiomatic Elixir Enum operations
     * 
     * Transforms Haxe for loops into appropriate Elixir patterns.
     * Since Elixir is functional, we need to transform mutable operations
     * into functional equivalents.
     * 
     * @param tvar The loop variable
     * @param iterExpr The iterable expression (array, range, etc.)
     * @param blockExpr The loop body
     * @return Compiled Elixir code
     */
    private function compileForLoop(tvar: TVar, iterExpr: TypedExpr, blockExpr: TypedExpr): String {
        // Get the original variable name and use it as the lambda parameter
        var originalName = getOriginalVarName(tvar);
        var loopVar = NamingHelper.toSnakeCase(originalName);
        
        // Special case: Check if we're iterating over Reflect.fields
        var isReflectFields = false;
        var targetObject: String = null;
        switch (iterExpr.expr) {
            case TCall(e, args):
                switch (e.expr) {
                    case TField(obj, fa):
                        var objStr = compileExpression(obj);
                        switch (fa) {
                            case FStatic(_, cf):
                                if (objStr == "Reflect" && cf.get().name == "fields" && args.length > 0) {
                                    isReflectFields = true;
                                    targetObject = compileExpression(args[0]);
                                }
                            case _:
                        }
                    case _:
                }
            case _:
        }
        
        if (isReflectFields && targetObject != null) {
            // Optimize Reflect.fields iteration to idiomatic Elixir
            return compileReflectFieldsIteration(loopVar, targetObject, blockExpr);
        }
        
        var iterableExpr = compileExpression(iterExpr);
        
        // Check if this is a find pattern (early return) - highest priority
        if (hasReturnStatement(blockExpr)) {
            var body = compileExpression(blockExpr);
            // Extract just the condition from the return statement
            var returnPattern = ~/return\s+(.+);?/;
            if (returnPattern.match(body)) {
                var condition = returnPattern.matched(1);
                return 'Enum.find(${iterableExpr}, fn ${loopVar} -> ${condition} end)';
            }
        }
        
        // Check if this is a counting pattern (count++ in loop)
        if (hasCountingPattern(blockExpr)) {
            // For counting patterns, we need to handle the mutation differently
            // Count elements that match a condition
            var condition = extractCountingCondition(blockExpr, loopVar);
            if (condition != null) {
                return 'Enum.count(${iterableExpr}, fn ${loopVar} -> ${condition} end)';
            } else {
                // Simple counting without condition - just return length
                return 'length(${iterableExpr})';
            }
        }
        
        // Default: compile as Enum.each for side effects or Enum.map for transformations
        var body = compileExpression(blockExpr);
        
        // Check if the body has side effects only
        if (body.contains("Phoenix.PubSub") || body.contains("Repo.") || body.contains("IO.")) {
            return 'Enum.each(${iterableExpr}, fn ${loopVar} -> ${body} end)';
        } else {
            // Otherwise use map for potential transformations
            return 'Enum.map(${iterableExpr}, fn ${loopVar} -> ${body} end)';
        }
    }
    
    /**
     * Check if the expression has a counting pattern
     */
    private function hasCountingPattern(expr: TypedExpr): Bool {
        switch (expr.expr) {
            case TBlock(exprs):
                for (e in exprs) {
                    if (hasCountingPattern(e)) return true;
                }
            case TIf(_, eif, _):
                // Check if the if branch has count++
                switch (eif.expr) {
                    case TUnop(OpIncrement, _, {expr: TLocal(_)}):
                        return true;
                    case TBlock(exprs):
                        for (e in exprs) {
                            if (hasCountingPattern(e)) return true;
                        }
                    case _:
                }
            case TUnop(OpIncrement, _, {expr: TLocal(_)}):
                return true;
            case _:
        }
        return false;
    }
    
    /**
     * Extract the condition from a counting pattern
     */
    private function extractCountingCondition(expr: TypedExpr, loopVar: String): Null<String> {
        switch (expr.expr) {
            case TBlock(exprs):
                for (e in exprs) {
                    var result = extractCountingCondition(e, loopVar);
                    if (result != null) return result;
                }
            case TIf(econd, eif, _):
                // Check if the if branch has count++
                switch (eif.expr) {
                    case TUnop(OpIncrement, _, {expr: TLocal(_)}):
                        return compileExpression(econd);
                    case TBlock(exprs):
                        for (e in exprs) {
                            switch (e.expr) {
                                case TUnop(OpIncrement, _, {expr: TLocal(_)}):
                                    return compileExpression(econd);
                                case _:
                            }
                        }
                    case _:
                }
            case _:
        }
        return null;
    }
    
    /**
     * Extract the condition from a find pattern
     */
    private function extractFindCondition(expr: TypedExpr, loopVar: String): Null<String> {
        switch (expr.expr) {
            case TBlock(exprs):
                for (e in exprs) {
                    var result = extractFindCondition(e, loopVar);
                    if (result != null) return result;
                }
            case TIf(econd, eif, _):
                // Check if the if branch has a return
                switch (eif.expr) {
                    case TReturn(_):
                        return compileExpression(econd);
                    case TBlock(exprs):
                        for (e in exprs) {
                            switch (e.expr) {
                                case TReturn(_):
                                    return compileExpression(econd);
                                case _:
                            }
                        }
                    case _:
                }
            case _:
        }
        return null;
    }
    
    /**
     * Try to optimize for-in loop patterns that have been desugared to while loops.
     * 
     * This is a key desugaring reversal function. Haxe transforms convenient for-in
     * loops into verbose while loops with index tracking. We detect these patterns
     * and convert them back to idiomatic Elixir Enum functions.
     * 
     * Detected patterns:
     * - `_g = 0; while (_g < array.length)` → `Enum.each(array, fn item -> ... end)`
     * - `_g = 0; while (_g < _g1)` → `Enum.reduce(start..end, acc, fn i, acc -> ... end)`
     * - Array mapping patterns → `Enum.map(array, fn item -> ... end)`
     * - Array filtering patterns → `Enum.filter(array, fn item -> ... end)`
     * 
     * @param econd The while loop condition expression
     * @param ebody The while loop body expression
     * @return Optimized Elixir code string, or null if no pattern detected
     */
    private function tryOptimizeForInPattern(econd: TypedExpr, ebody: TypedExpr): Null<String> {
        // Try to detect range-based for loop pattern: _g < _gX where _g and _gX are range bounds
        var conditionStr = compileExpression(econd);
        if (conditionStr == null) return null;
        
        // Check if this is a Reflect.fields iteration pattern
        // The pattern in the problematic code is: _g < g.length or similar variants
        // where g or _g_X contains Reflect.fields result
        var reflectFieldsPattern = detectReflectFieldsPattern(econd, ebody);
        if (reflectFieldsPattern != null) {
            return reflectFieldsPattern;
        }
        
        // Look for pattern: _g < _g1 (range iteration) - account for parentheses
        var rangePattern = ~/^\(?_g\s*<\s*_g1\)?$/;
        if (rangePattern.match(conditionStr)) {
            // This is likely a range-based for loop: for (i in start...end)
            return optimizeRangeLoop(ebody);
        }
        
        // Look for array iteration pattern: _g < array.length or _g < length(array)
        // Handle optional parentheses around the entire condition
        var arrayPattern1 = ~/^\(?_g\s*<\s*(.+?)\.length\)?$/;
        var arrayPattern2 = ~/^\(?_g\s*<\s*length\(([^)]+)\)\)?$/;
        var arrayPattern3 = ~/^\(?_g\d*\s*<\s*length\(([^)]+)\)\)?$/; // Handle _g1, _g2 etc
        
        if (arrayPattern1.match(conditionStr)) {
            var arrayExpr = arrayPattern1.matched(1);
            return optimizeArrayLoop(arrayExpr, ebody);
        } else if (arrayPattern2.match(conditionStr)) {
            var arrayExpr = arrayPattern2.matched(1);
            return optimizeArrayLoop(arrayExpr, ebody);
        } else if (arrayPattern3.match(conditionStr)) {
            var arrayExpr = arrayPattern3.matched(1);
            return optimizeArrayLoop(arrayExpr, ebody);
        }
        return null;
    }
    
    /**
     * Compile Reflect.fields iteration to idiomatic Elixir
     */
    private function compileReflectFieldsIteration(fieldVar: String, targetObject: String, blockExpr: TypedExpr): String {
        // Transform the loop body to use Map operations
        var transformedBody = compileReflectFieldsBody(blockExpr, targetObject, fieldVar);
        
        // Generate Enum.each with Map.keys
        return 'Enum.each(Map.keys(${targetObject}), fn ${fieldVar} ->\n' +
               '  ${transformedBody}\n' +
               'end)';
    }
    
    /**
     * Compile body of Reflect.fields iteration
     */
    private function compileReflectFieldsBody(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        switch (expr.expr) {
            case TBlock(exprs):
                var statements = [];
                for (e in exprs) {
                    var stmt = compileReflectFieldsStatement(e, targetObject, fieldVar);
                    if (stmt != null && stmt != "") {
                        statements.push(stmt);
                    }
                }
                return statements.join("\n  ");
                
            case _:
                return compileReflectFieldsStatement(expr, targetObject, fieldVar);
        }
    }
    
    /**
     * Compile individual statement in Reflect.fields iteration
     */
    private function compileReflectFieldsStatement(expr: TypedExpr, sourceObject: String, fieldVar: String): String {
        switch (expr.expr) {
            case TCall(e, args):
                switch (e.expr) {
                    case TField(obj, fa):
                        var objStr = compileExpression(obj);
                        switch (fa) {
                            case FStatic(_, cf):
                                var methodName = cf.get().name;
                                if (objStr == "Reflect") {
                                    if (methodName == "setField" && args.length >= 3) {
                                        // Reflect.setField(target, field, value)
                                        var target = compileExpression(args[0]);
                                        var field = compileExpression(args[1]);
                                        var value = compileExpression(args[2]);
                                        
                                        // If field is the loop variable, use it directly
                                        if (field == fieldVar || field.contains("field")) {
                                            field = fieldVar;
                                        }
                                        
                                        // If value is Reflect.field, optimize it
                                        if (value.contains("Reflect.field")) {
                                            value = 'Map.get(${sourceObject}, ${fieldVar})';
                                        }
                                        
                                        // Generate Map.put assignment
                                        return '${target} = Map.put(${target}, ${field}, ${value})';
                                    } else if (methodName == "field" && args.length >= 2) {
                                        // This is handled in the value part above
                                        var source = compileExpression(args[0]);
                                        var field = compileExpression(args[1]);
                                        if (field == fieldVar || field.contains("field")) {
                                            field = fieldVar;
                                        }
                                        return 'Map.get(${source}, ${field})';
                                    }
                                }
                            case _:
                        }
                    case _:
                }
                // Default compilation for other calls
                return compileExpression(expr);
                
            case _:
                return compileExpression(expr);
        }
    }
    
    /**
     * Check if loop body contains Reflect.field/setField operations
     */
    private function isReflectFieldsLoop(ebody: TypedExpr): Bool {
        var hasReflectOps = false;
        
        function scan(expr: TypedExpr): Void {
            if (hasReflectOps) return; // Early exit if already found
            
            switch (expr.expr) {
                case TCall(e, _):
                    switch (e.expr) {
                        case TField(obj, fa):
                            var objStr = compileExpression(obj);
                            switch (fa) {
                                case FStatic(_, cf):
                                    var methodName = cf.get().name;
                                    if (objStr == "Reflect" && (methodName == "field" || methodName == "setField")) {
                                        hasReflectOps = true;
                                    }
                                case _:
                            }
                        case _:
                    }
                case TBlock(exprs):
                    for (e in exprs) scan(e);
                case TIf(_, eif, eelse):
                    scan(eif);
                    if (eelse != null) scan(eelse);
                case TBinop(_, e1, e2):
                    scan(e1);
                    scan(e2);
                case TVar(_, init):
                    if (init != null) scan(init);
                case _:
            }
        }
        
        scan(ebody);
        return hasReflectOps;
    }
    
    /**
     * Optimize Reflect.fields loop to idiomatic Elixir
     */
    private function optimizeReflectFieldsLoop(econd: TypedExpr, ebody: TypedExpr): String {
        // Find the target object being iterated over
        var targetObject: String = null;
        var fieldVar = "field";
        
        function findTarget(expr: TypedExpr): Void {
            switch (expr.expr) {
                case TCall(e, args):
                    switch (e.expr) {
                        case TField(obj, fa):
                            var objStr = compileExpression(obj);
                            switch (fa) {
                                case FStatic(_, cf):
                                    if (objStr == "Reflect" && cf.get().name == "setField" && args.length > 0) {
                                        // First argument is usually the target object
                                        targetObject = compileExpression(args[0]);
                                    }
                                case _:
                            }
                        case _:
                    }
                case TBlock(exprs):
                    for (e in exprs) findTarget(e);
                case _:
            }
        }
        
        findTarget(ebody);
        
        // If we couldn't find a specific target, use a generic approach
        if (targetObject == null) {
            targetObject = "config"; // Common case
        }
        
        // Transform the loop body
        var transformedBody = transformReflectLoopBody(ebody, targetObject, fieldVar);
        
        // Generate optimized Elixir code
        return 'if ${targetObject} != nil do\n' +
               '  Enum.each(Map.keys(${targetObject}), fn ${fieldVar} ->\n' +
               '    ${transformedBody}\n' +
               '  end)\n' +
               'end';
    }
    
    /**
     * Transform Reflect loop body to work with Enum.each
     */
    private function transformReflectLoopBody(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        switch (expr.expr) {
            case TBlock(exprs):
                var statements = [];
                for (e in exprs) {
                    var stmt = transformReflectStatement(e, targetObject, fieldVar);
                    if (stmt != null && stmt != "") {
                        statements.push(stmt);
                    }
                }
                return statements.join("\n    ");
            case TIf(econd, eif, eelse):
                // Handle if-statements in the loop body
                var cond = compileExpression(econd);
                var ifBody = transformReflectLoopBody(eif, targetObject, fieldVar);
                if (eelse != null) {
                    var elseBody = transformReflectLoopBody(eelse, targetObject, fieldVar);
                    return 'if ${cond} do\n      ${ifBody}\n    else\n      ${elseBody}\n    end';
                } else {
                    return 'if ${cond} do\n      ${ifBody}\n    end';
                }
            case _:
                return transformReflectStatement(expr, targetObject, fieldVar);
        }
    }
    
    /**
     * Transform individual Reflect statements
     */
    private function transformReflectStatement(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        switch (expr.expr) {
            case TVar(v, init):
                var varName = getOriginalVarName(v);
                // Skip loop counter variables
                if (varName == "field" || varName.contains("_g")) {
                    return "";
                }
                if (init != null) {
                    var value = transformReflectExpression(init, targetObject, fieldVar);
                    return '${NamingHelper.toSnakeCase(varName)} = ${value}';
                }
                return "";
                
            case TBinop(OpAssign, e1, e2):
                var left = compileExpression(e1);
                var right = transformReflectExpression(e2, targetObject, fieldVar);
                return '${left} = ${right}';
                
            case TCall(_, _):
                return transformReflectExpression(expr, targetObject, fieldVar);
                
            case _:
                return compileExpression(expr);
        }
    }
    
    /**
     * Transform Reflect expressions to use Map operations
     */
    private function transformReflectExpression(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        switch (expr.expr) {
            case TCall(e, args):
                switch (e.expr) {
                    case TField(obj, fa):
                        var objStr = compileExpression(obj);
                        switch (fa) {
                            case FStatic(_, cf):
                                var methodName = cf.get().name;
                                if (objStr == "Reflect") {
                                    if (methodName == "field" && args.length >= 2) {
                                        var source = compileExpression(args[0]);
                                        var field = compileExpression(args[1]);
                                        // Replace array access patterns with the field variable
                                        if (field.contains("Enum.at")) {
                                            field = fieldVar;
                                        }
                                        return 'Map.get(${source}, ${field})';
                                    } else if (methodName == "setField" && args.length >= 3) {
                                        var target = compileExpression(args[0]);
                                        var field = compileExpression(args[1]);
                                        var value = transformReflectExpression(args[2], targetObject, fieldVar);
                                        // Replace array access patterns with the field variable
                                        if (field.contains("Enum.at")) {
                                            field = fieldVar;
                                        }
                                        return 'Map.put(${target}, ${field}, ${value})';
                                    }
                                }
                            case _:
                        }
                    case _:
                }
                // Default compilation
                return compileExpression(expr);
            case _:
                return compileExpression(expr);
        }
    }
    
    /**
     * Detect and optimize Reflect.fields iteration patterns
     * This converts Y combinator patterns to idiomatic Enum.each
     */
    private function detectReflectFieldsPattern(econd: TypedExpr, ebody: TypedExpr): Null<String> {
        // Look for patterns where we're iterating over Reflect.fields result
        // The condition is typically: _g < array.length where array = Reflect.fields(obj)
        
        // First, check if the body contains Reflect.field/setField operations
        var hasReflectOperations = false;
        var targetObject: String = null;
        
        function scanForReflect(expr: TypedExpr): Void {
            switch (expr.expr) {
                case TCall(e, args):
                    switch (e.expr) {
                        case TField(obj, fa):
                            var objStr = compileExpression(obj);
                            switch (fa) {
                                case FStatic(_, cf):
                                    var fieldName = cf.get().name;
                                    if (objStr == "Reflect" && (fieldName == "field" || fieldName == "setField")) {
                                        hasReflectOperations = true;
                                        // Try to extract the target object from the first argument
                                        if (args.length > 0 && targetObject == null) {
                                            switch (args[0].expr) {
                                                case TLocal(v):
                                                    targetObject = NamingHelper.toSnakeCase(getOriginalVarName(v));
                                                case _:
                                                    targetObject = compileExpression(args[0]);
                                            }
                                        }
                                    }
                                case _:
                            }
                        case _:
                    }
                case TBlock(exprs):
                    for (e in exprs) scanForReflect(e);
                case TIf(_, eif, eelse):
                    scanForReflect(eif);
                    if (eelse != null) scanForReflect(eelse);
                case TWhile(_, e, _):
                    scanForReflect(e);
                case TBinop(_, e1, e2):
                    scanForReflect(e1);
                    scanForReflect(e2);
                case _:
            }
        }
        
        scanForReflect(ebody);
        
        if (!hasReflectOperations) {
            return null;
        }
        
        // Now we know this is a Reflect.fields iteration pattern
        // Generate idiomatic Elixir code using Enum.each
        
        // Extract the field variable name from the loop body
        var fieldVarName = "field"; // Default
        var fieldsVarName = "_fields"; // Default for the fields array
        
        // Look for the pattern where we access array elements
        function findArrayAccess(expr: TypedExpr): Void {
            switch (expr.expr) {
                case TArray(arr, index):
                    // This is array[index] access - the array is likely our fields
                    var arrStr = compileExpression(arr);
                    if (arrStr != null && (arrStr.contains("g") || arrStr.contains("_g"))) {
                        fieldsVarName = arrStr;
                    }
                case TLocal(v):
                    var name = getOriginalVarName(v);
                    if (name == "field") {
                        fieldVarName = name;
                    }
                case TBlock(exprs):
                    for (e in exprs) findArrayAccess(e);
                case _:
            }
        }
        
        findArrayAccess(ebody);
        
        // Transform the loop body to work with Enum.each
        var transformedBody = transformReflectFieldsBody(ebody, targetObject, fieldVarName);
        
        // Generate the optimized Elixir code
        if (targetObject != null) {
            return 'if ${targetObject} != nil do\n' +
                   '  Enum.each(Map.keys(${targetObject}), fn ${NamingHelper.toSnakeCase(fieldVarName)} ->\n' +
                   '    ${transformedBody}\n' +
                   '  end)\n' +
                   'end';
        }
        
        // Fallback if we couldn't determine the target object
        return null;
    }
    
    /**
     * Transform Reflect.fields loop body to idiomatic Elixir
     */
    private function transformReflectFieldsBody(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        switch (expr.expr) {
            case TBlock(exprs):
                var statements = [];
                for (e in exprs) {
                    var stmt = transformReflectFieldStatement(e, targetObject, fieldVar);
                    if (stmt != null && stmt != "") {
                        statements.push(stmt);
                    }
                }
                return statements.join("\n    ");
            case _:
                return transformReflectFieldStatement(expr, targetObject, fieldVar);
        }
    }
    
    /**
     * Transform individual statements in Reflect.fields loop
     */
    private function transformReflectFieldStatement(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        switch (expr.expr) {
            case TCall(e, args):
                switch (e.expr) {
                    case TField(obj, fa):
                        var objStr = compileExpression(obj);
                        switch (fa) {
                            case FStatic(_, cf):
                                var methodName = cf.get().name;
                                if (objStr == "Reflect") {
                                    if (methodName == "setField" && args.length >= 3) {
                                        // Reflect.setField(target, field, value)
                                        var target = compileExpression(args[0]);
                                        var field = compileExpression(args[1]);
                                        var value = compileExpression(args[2]);
                                        
                                        // Replace array access with field variable
                                        if (field.contains("Enum.at")) {
                                            field = NamingHelper.toSnakeCase(fieldVar);
                                        }
                                        
                                        return 'Map.put(${target}, ${field}, ${value})';
                                    } else if (methodName == "field" && args.length >= 2) {
                                        // Reflect.field(source, field)
                                        var source = compileExpression(args[0]);
                                        var field = compileExpression(args[1]);
                                        
                                        // Replace array access with field variable
                                        if (field.contains("Enum.at")) {
                                            field = NamingHelper.toSnakeCase(fieldVar);
                                        }
                                        
                                        return 'Map.get(${source}, ${field})';
                                    }
                                }
                            case _:
                        }
                    case _:
                }
                // Default compilation for other calls
                return compileExpression(expr);
                
            case TBinop(OpAssign, e1, e2):
                // Handle assignments like: endpointConfig[field] = config[field]
                var left = compileExpression(e1);
                var right = transformReflectFieldStatement(e2, targetObject, fieldVar);
                return '${left} = ${right}';
                
            case TVar(v, init):
                // Skip counter variable declarations like: field = Enum.at(g, g)
                var varName = getOriginalVarName(v);
                if (varName == "field" || varName.contains("field")) {
                    return ""; // Skip this, we get field from the Enum.each parameter
                }
                if (init != null) {
                    var value = compileExpression(init);
                    return '${NamingHelper.toSnakeCase(varName)} = ${value}';
                }
                return "";
                
            case _:
                return compileExpression(expr);
        }
    }
    
    /**
     * Optimize range-based loops to use Enum.reduce with proper range syntax
     */
    private function optimizeRangeLoop(ebody: TypedExpr): String {
        // For range-based loops, we know the pattern: for (i in start...end) { sum += i; }
        // This should become: Enum.reduce(start..end, sum, fn i, acc -> acc + i end)
        
        // Extract the accumulator variable from the outer scope (not the loop body)
        var bodyAnalysis = analyzeRangeLoopBody(ebody);
        
        if (bodyAnalysis.hasSimpleAccumulator) {
            // Simple accumulation pattern: sum += i
            return '(\n' +
                   '  {${bodyAnalysis.accumulator}} = Enum.reduce(_g.._g1, ${bodyAnalysis.accumulator}, fn i, acc ->\n' +
                   '    acc + i\n' +
                   '  end)\n' +
                   ')';
        } else {
            // Complex loop body - use Enum.each and track state manually
            var transformedBody = transformComplexLoopBody(ebody);
            return '(\n' +
                   '  Enum.each(_g.._g1, fn i ->\n' +
                   '    ${transformedBody}\n' +
                   '  end)\n' +
                   ')';
        }
    }
    
    /**
     * Optimize array-based loops to use appropriate Enum functions
     */
    private function optimizeArrayLoop(arrayExpr: String, ebody: TypedExpr): String {
        var bodyAnalysis = analyzeLoopBody(ebody);
        
        // Extract actual loop variable name from the AST
        var loopVar = extractLoopVariableFromBody(ebody);
        if (loopVar == null) loopVar = "item"; // Default fallback
        
        // For counting patterns, try to extract the variable used in condition
        if (bodyAnalysis.hasCountPattern && bodyAnalysis.condition != null) {
            var conditionVar = extractVariableFromCondition(bodyAnalysis.condition);
            if (conditionVar != null) loopVar = conditionVar;
        }
        
        // Dispatch to appropriate pattern generator based on analysis
        // Higher priority patterns checked first
        
        // 1. Check if this is a find pattern (early return)
        if (bodyAnalysis.hasEarlyReturn) {
            return generateEnumFindPattern(arrayExpr, loopVar, ebody);
        }
        
        // 2. Check for filtering pattern BEFORE mapping (filter has higher priority!)
        if (bodyAnalysis.hasFilterPattern && bodyAnalysis.conditionExpr != null) {
            return generateEnumFilterPattern(arrayExpr, loopVar, bodyAnalysis.conditionExpr);
        }
        
        // 3. Check for mapping pattern (array transformation) - Lower priority than filtering
        if (bodyAnalysis.hasMapPattern) {
            return generateEnumMapPattern(arrayExpr, loopVar, ebody);
        }
        
        // 4. Check for counting pattern (lower priority since loops may have increments)
        if (bodyAnalysis.hasCountPattern && bodyAnalysis.conditionExpr != null) {
            return generateEnumCountPattern(arrayExpr, loopVar, bodyAnalysis.conditionExpr);
        }
        
        // 5. Check for simple numeric accumulation
        if (bodyAnalysis.hasSimpleAccumulator) {
            return '(\n' +
                   '  {${bodyAnalysis.accumulator}} = Enum.reduce(${arrayExpr}, ${bodyAnalysis.accumulator}, fn ${loopVar}, acc ->\n' +
                   '    acc + ${loopVar}\n' +
                   '  end)\n' +
                   ')';
        } 
        
        // 6. Default to Enum.each for side effects
        var transformedBody = transformComplexLoopBody(ebody);
        return '(\n' +
               '  Enum.each(${arrayExpr}, fn ${loopVar} ->\n' +
               '    ${transformedBody}\n' +
               '  end)\n' +
               ')';
    }
    
    /**
     * Analyze loop body to extract patterns for optimization
     */
    private function analyzeLoopBody(ebody: TypedExpr): {
        hasSimpleAccumulator: Bool,
        hasEarlyReturn: Bool,
        hasCountPattern: Bool,
        hasFilterPattern: Bool,
        hasMapPattern: Bool,
        accumulator: String,
        loopVar: String,
        isAddition: Bool,
        condition: String,
        conditionExpr: Null<TypedExpr>
    } {
        // Default analysis result
        var result = {
            hasSimpleAccumulator: false,
            hasEarlyReturn: false,
            hasCountPattern: false,
            hasFilterPattern: false,
            hasMapPattern: false,
            accumulator: "sum",
            loopVar: "item", 
            isAddition: false,
            condition: "",
            conditionExpr: null
        };
        
        // Look for early returns (find patterns)
        result.hasEarlyReturn = hasReturnStatement(ebody);
        
        // Analyze AST structure for different patterns
        analyzeLoopBodyAST(ebody, result);
        
        // Look for simple accumulation patterns in the body (fallback)
        var bodyStr = compileExpression(ebody);
        if (bodyStr == null) return result;
        
        // Check for += pattern: sum += i (numeric accumulation)
        var addPattern = ~/(\w+)\s*=\s*\1\s*\+\s*(\w+)/;
        if (addPattern.match(bodyStr)) {
            result.hasSimpleAccumulator = true;
            result.accumulator = addPattern.matched(1);
            result.loopVar = addPattern.matched(2);
            result.isAddition = true;
        }
        
        return result;
    }
    
    /**
     * Analyze loop body AST to detect specific patterns
     */
    private function analyzeLoopBodyAST(expr: TypedExpr, result: Dynamic): Void {
        switch (expr.expr) {
            case TBlock(exprs):
                for (e in exprs) {
                    analyzeLoopBodyAST(e, result);
                }
                
            case TIf(econd, eif, _):
                // Check for filtering pattern: if (condition) array.push(item)
                // or counting pattern: if (condition) count++
                var condition = compileExpression(econd);
                
                // Helper function to check for push pattern
                function checkForPush(e: TypedExpr): Bool {
                    switch (e.expr) {
                        case TCall({expr: TField(_, FInstance(_, _, cf))}, _):
                            if (cf.get().name == "push") {
                                return true;
                            }
                        case TBlock(exprs):
                            for (expr in exprs) {
                                if (checkForPush(expr)) return true;
                            }
                        case _:
                    }
                    return false;
                }
                
                // Check if this is a filter pattern (has push call)
                if (checkForPush(eif)) {
                    result.hasFilterPattern = true;
                    result.conditionExpr = econd;
                } else {
                    // Check for counting patterns
                    switch (eif.expr) {
                        case TUnop(OpIncrement, _, {expr: TLocal(v)}):
                            // Found count++ pattern (direct)
                            result.hasCountPattern = true;
                            result.accumulator = getOriginalVarName(v);
                            result.condition = condition;
                            result.conditionExpr = econd;
                        case TBlock(blockExprs):
                            // Check for count++ inside block
                            for (blockExpr in blockExprs) {
                                switch (blockExpr.expr) {
                                    case TUnop(OpIncrement, _, {expr: TLocal(v)}):
                                        // Found count++ pattern in block
                                        result.hasCountPattern = true;
                                        result.accumulator = getOriginalVarName(v);
                                        result.condition = condition;
                                        result.conditionExpr = econd;
                                    case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, _, _)}):
                                        // Found count = count + 1 pattern in block
                                        result.hasCountPattern = true;
                                        result.accumulator = getOriginalVarName(v);
                                        result.condition = condition;
                                        result.conditionExpr = econd;
                                    case _:
                                }
                            }
                        case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, _, _)}):
                            // Found count = count + 1 pattern (direct)
                            result.hasCountPattern = true;
                            result.accumulator = getOriginalVarName(v);
                            result.condition = condition;
                            result.conditionExpr = econd;
                        case _:
                    }
                }
                
            case TVar(v, init):
                // Check for new variable declarations (potential filtering/mapping)
                if (init != null) {
                    switch (init.expr) {
                        case TArray(e1, e2):
                            // Array access - potential mapping
                            result.hasMapPattern = true;
                        case _:
                    }
                }
                
            case TUnop(OpIncrement, false, {expr: TLocal(v)}):
                // Direct increment outside condition - simple counting
                result.hasCountPattern = true;
                result.accumulator = getOriginalVarName(v);
                
            case _:
        }
    }
    
    /**
     * Extract loop variable name from AST by finding TLocal references
     */
    private function extractLoopVariableFromBody(expr: TypedExpr): Null<String> {
        switch (expr.expr) {
            case TLocal(v):
                // Check if this is an array access pattern indicating iteration variable
                var originalName = getOriginalVarName(v);
                if (originalName != "_g" && originalName != "_g1" && originalName != "_g2") {
                    return originalName;
                }
                
            case TBlock(exprs):
                // Look through block for variable references
                for (e in exprs) {
                    var result = extractLoopVariableFromBody(e);
                    if (result != null) return result;
                }
                
            case TIf(econd, eif, eelse):
                // Check condition and branches
                var result = extractLoopVariableFromBody(econd);
                if (result != null) return result;
                result = extractLoopVariableFromBody(eif);
                if (result != null) return result;
                if (eelse != null) {
                    result = extractLoopVariableFromBody(eelse);
                    if (result != null) return result;
                }
                
            case TReturn(e) if (e != null):
                return extractLoopVariableFromBody(e);
                
            case TField(e, fa):
                // Look for patterns like todo.id
                return extractLoopVariableFromBody(e);
                
            case TBinop(op, e1, e2):
                // Check both operands
                var result = extractLoopVariableFromBody(e1);
                if (result != null) return result;
                return extractLoopVariableFromBody(e2);
                
            case _:
                // Continue searching in nested expressions
        }
        return null;
    }
    
    /**
     * Check if expression contains return statements
     */
    private function hasReturnStatement(expr: TypedExpr): Bool {
        switch (expr.expr) {
            case TReturn(_):
                return true;
            case TBlock(exprs):
                for (e in exprs) {
                    if (hasReturnStatement(e)) return true;
                }
            case TIf(_, eif, eelse):
                if (hasReturnStatement(eif)) return true;
                if (eelse != null && hasReturnStatement(eelse)) return true;
            case _:
        }
        return false;
    }
    
    /**
     * Check if an expression will generate multiple statements when compiled
     * This is critical for determining if-statement syntax (inline vs block)
     */
    private function containsMultipleStatements(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TBlock(exprs):
                // CRITICAL FIX: A block with multiple expressions ALWAYS needs block syntax
                // This catches desugared for-loops that become multiple statements
                if (exprs.length > 1) return true;
                // Even single expression blocks might contain complex statements
                if (exprs.length == 1) return containsMultipleStatements(exprs[0]);
                return false;
                
            case TWhile(_, _, _):
                // While loops always generate multiple statements (Y combinator pattern)
                return true;
                
            case TFor(_, _, _):
                // For loops generate complex Enum operations
                return true;
                
            case TIf(_, eif, eelse):
                // Nested if statements might need block syntax
                if (containsMultipleStatements(eif)) return true;
                if (eelse != null && containsMultipleStatements(eelse)) return true;
                return false;
                
            case TSwitch(_, _, _):
                // Switch/case always needs multiple lines
                return true;
                
            case TTry(_, _):
                // Try/catch blocks need multiple lines
                return true;
                
            case TVar(_, init):
                // Variable declarations followed by usage would be multiple statements
                // but a single TVar is just one statement
                return false;
                
            case TBinop(OpAssign, e1, _):
                // Check if this is a complex assignment that might expand
                switch (e1.expr) {
                    case TField(_, _):
                        // Field assignments might expand to struct updates
                        return false; // Single assignment is still one statement
                    case _:
                        return false;
                }
                
            case _:
                // Most other expressions are single statements
                return false;
        }
    }
    
    /**
     * Debug helper: Check if expression contains TFor patterns
     */
    private function checkForTForInExpression(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TFor(_, _, _):
                return true;
            case TBlock(exprs):
                for (e in exprs) {
                    if (checkForTForInExpression(e)) return true;
                }
                return false;
            case TIf(_, eif, eelse):
                if (checkForTForInExpression(eif)) return true;
                if (eelse != null && checkForTForInExpression(eelse)) return true;
                return false;
            case _:
                return false;
        }
    }
    
    /**
     * Debug helper: Check if expression contains Reflect.fields usage
     */
    private function checkForReflectFieldsInExpression(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TCall(e, _):
                // Simplified detection - just check if it's a call that might be Reflect.fields
                var callStr = compileExpression(e);
                return callStr.contains("Reflect.fields");
            case TBlock(exprs):
                for (e in exprs) {
                    if (checkForReflectFieldsInExpression(e)) return true;
                }
                return false;
            case TIf(_, eif, eelse):
                if (checkForReflectFieldsInExpression(eif)) return true;
                if (eelse != null && checkForReflectFieldsInExpression(eelse)) return true;
                return false;
            case TFor(_, iter, _):
                // Check if the iterator uses Reflect.fields
                if (checkForReflectFieldsInExpression(iter)) return true;
                return false;
            case _:
                return false;
        }
    }
    
    /**
     * Check if expression contains TWhile nodes that generate Y combinator patterns
     * 
     * This function recursively scans the AST to detect TWhile expressions that
     * will generate complex multi-line Y combinator patterns requiring block syntax.
     */
    private function containsTWhileExpression(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TWhile(_, _, _):
                // Found a TWhile - this will generate Y combinator pattern
                return true;
                
            case TBlock(exprs):
                // Recursively check all expressions in the block
                for (e in exprs) {
                    if (containsTWhileExpression(e)) return true;
                }
                return false;
                
            case TIf(_, eif, eelse):
                // Check both branches of if-statement
                if (containsTWhileExpression(eif)) return true;
                if (eelse != null && containsTWhileExpression(eelse)) return true;
                return false;
                
            case TFor(_, _, ebody):
                // For loops might contain while loops in their body
                return containsTWhileExpression(ebody);
                
            case TSwitch(_, cases, defaultCase):
                // Check all switch cases
                for (c in cases) {
                    if (containsTWhileExpression(c.expr)) return true;
                }
                if (defaultCase != null && containsTWhileExpression(defaultCase)) return true;
                return false;
                
            case TTry(etry, catches):
                // Check try block
                if (containsTWhileExpression(etry)) return true;
                // Check catch blocks
                for (c in catches) {
                    if (containsTWhileExpression(c.expr)) return true;
                }
                return false;
                
            case TFunction(func):
                // Check function body
                return containsTWhileExpression(func.expr);
                
            case TCall(e, args):
                // Check function expression and arguments
                if (containsTWhileExpression(e)) return true;
                for (arg in args) {
                    if (containsTWhileExpression(arg)) return true;
                }
                return false;
                
            case TBinop(_, e1, e2):
                // Check both operands
                return containsTWhileExpression(e1) || containsTWhileExpression(e2);
                
            case TUnop(_, _, e):
                // Check operand
                return containsTWhileExpression(e);
                
            case TArray(e1, e2):
                // Check array and index expressions
                return containsTWhileExpression(e1) || containsTWhileExpression(e2);
                
            case TArrayDecl(exprs):
                // Check all array elements
                for (e in exprs) {
                    if (containsTWhileExpression(e)) return true;
                }
                return false;
                
            case TField(e, _):
                // Check field access target
                return containsTWhileExpression(e);
                
            case TVar(_, init):
                // Check variable initialization
                return init != null ? containsTWhileExpression(init) : false;
                
            case _:
                // All other expression types don't contain TWhile
                return false;
        }
    }
    
    /**
     * Generate Enum.find pattern for early return loops
     */
    private function generateEnumFindPattern(arrayExpr: String, loopVar: String, ebody: TypedExpr): String {
        // Set loop context to enable aggressive variable substitution
        var previousContext = isInLoopContext;
        isInLoopContext = true;
        
        // Extract the condition from the if statement
        var condition = extractConditionFromReturn(ebody);
        if (condition != null) {
            // Generate Enum.find for simple cases
            // Restore previous loop context
            isInLoopContext = previousContext;
            return 'Enum.find(${arrayExpr}, fn ${loopVar} -> ${condition} end)';
        }
        
        // Fallback to reduce_while for complex cases
        var result = '(\n' +
               '  Enum.reduce_while(${arrayExpr}, nil, fn ${loopVar}, _acc ->\n' +
               '    ${transformFindLoopBody(ebody, loopVar)}\n' +
               '  end)\n' +
               ')';
        
        // Restore previous loop context
        isInLoopContext = previousContext;
        return result;
    }
    
    /**
     * Extract condition from return statement in loop body
     */
    private function extractConditionFromReturn(expr: TypedExpr): Null<String> {
        switch (expr.expr) {
            case TBlock(exprs):
                for (e in exprs) {
                    var result = extractConditionFromReturn(e);
                    if (result != null) return result;
                }
            case TIf(econd, eif, _):
                switch (eif.expr) {
                    case TReturn(_):
                        return compileExpression(econd);
                    case _:
                }
            case _:
        }
        return null;
    }
    
    /**
     * Transform loop body for find patterns with reduce_while
     */
    private function transformFindLoopBody(expr: TypedExpr, loopVar: String): String {
        switch (expr.expr) {
            case TBlock(exprs):
                var result = "";
                for (e in exprs) {
                    switch (e.expr) {
                        case TIf(econd, eif, _):
                            var condition = compileExpression(econd);
                            // Check what's inside the eif (then branch)
                            switch (eif.expr) {
                                case TReturn(retExpr):
                                    var returnValue = retExpr != null ? compileExpression(retExpr) : loopVar;
                                    result += 'if ${condition} do\n' +
                                             '      {:halt, ${returnValue}}\n' +
                                             '    else\n' +
                                             '      {:cont, nil}\n' +
                                             '    end';
                                case TBlock(blockExprs):
                                    // Handle block containing return
                                    for (blockExpr in blockExprs) {
                                        switch (blockExpr.expr) {
                                            case TReturn(retExpr):
                                                var returnValue = retExpr != null ? compileExpression(retExpr) : loopVar;
                                                result += 'if ${condition} do\n' +
                                                         '      {:halt, ${returnValue}}\n' +
                                                         '    else\n' +
                                                         '      {:cont, nil}\n' +
                                                         '    end';
                                            case _:
                                        }
                                    }
                                case _:
                            }
                        case _:
                    }
                }
                return result;
            case TIf(econd, eif, _):
                // Handle direct if statement (not wrapped in block)
                var condition = compileExpression(econd);
                switch (eif.expr) {
                    case TReturn(retExpr):
                        var returnValue = retExpr != null ? compileExpression(retExpr) : loopVar;
                        return 'if ${condition} do\n' +
                               '      {:halt, ${returnValue}}\n' +
                               '    else\n' +
                               '      {:cont, nil}\n' +
                               '    end';
                    case _:
                }
            case _:
        }
        return '# Complex loop body transformation needed';
    }
    
    /**
     * Generate Enum.count pattern for conditional counting
     */
    private function generateEnumCountPattern(arrayExpr: String, loopVar: String, conditionExpr: TypedExpr): String {
        // Convert the loop variable name to snake_case for Elixir
        var targetVar = NamingHelper.toSnakeCase(loopVar);
        
        // Find what TVar the condition expression actually references
        var referencedTVar = findFirstLocalTVar(conditionExpr);
        
        // If the condition references a variable, use TVar-based substitution
        var condition: String;
        if (referencedTVar != null) {
            condition = compileExpressionWithTVarSubstitution(conditionExpr, referencedTVar, targetVar);
        } else {
            condition = compileExpression(conditionExpr);
        }
        
        return 'Enum.count(${arrayExpr}, fn ${targetVar} -> ${condition} end)';
    }
    
    /**
     * Find the first local variable referenced in an expression
     */
    private function findFirstLocalVariable(expr: TypedExpr): Null<String> {
        switch (expr.expr) {
            case TLocal(v):
                var varName = getOriginalVarName(v);
                // Skip system variables
                if (!isSystemVariable(varName)) {
                    return varName;
                }
                
            case TField(e, fa):
                // For field access like "v.id", find the base variable
                return findFirstLocalVariable(e);
                
            case TBinop(op, e1, e2):
                // Check both sides, return the first non-system variable found
                var left = findFirstLocalVariable(e1);
                if (left != null) return left;
                return findFirstLocalVariable(e2);
                
            case TUnop(op, postFix, e):
                return findFirstLocalVariable(e);
                
            case TParenthesis(e):
                return findFirstLocalVariable(e);
                
            case TCall(e, args):
                // Check the function call and its arguments
                var result = findFirstLocalVariable(e);
                if (result != null) return result;
                for (arg in args) {
                    result = findFirstLocalVariable(arg);
                    if (result != null) return result;
                }
                
            case _:
                // Other expression types don't contain local variables we care about
        }
        return null;
    }
    
    /**
     * Find the first local TVar referenced in an expression
     * This is more robust than string-based matching as it uses object identity
     */
    private function findFirstLocalTVar(expr: TypedExpr): Null<TVar> {
        switch (expr.expr) {
            case TLocal(v):
                var varName = getOriginalVarName(v);
                // Skip system variables
                if (!isSystemVariable(varName)) {
                    return v;
                }
                
            case TField(e, fa):
                // For field access like "v.id", find the base variable
                return findFirstLocalTVar(e);
                
            case TBinop(op, e1, e2):
                // Check both sides, return the first non-system variable found
                var left = findFirstLocalTVar(e1);
                if (left != null) return left;
                return findFirstLocalTVar(e2);
                
            case TUnop(op, postFix, e):
                return findFirstLocalTVar(e);
                
            case TParenthesis(e):
                return findFirstLocalTVar(e);
                
            case TCall(e, args):
                // Check the function call and its arguments
                var result = findFirstLocalTVar(e);
                if (result != null) return result;
                for (arg in args) {
                    result = findFirstLocalTVar(arg);
                    if (result != null) return result;
                }
                
            case _:
                // Other expression types don't contain local variables we care about
        }
        return null;
    }
    
    /**
     * Generate Enum.filter pattern for filtering arrays
     */
    private function generateEnumFilterPattern(arrayExpr: String, loopVar: String, conditionExpr: TypedExpr): String {
        // Convert the loop variable name to snake_case for Elixir
        var targetVar = NamingHelper.toSnakeCase(loopVar);
        
        // Find what TVar the condition expression actually references
        var referencedTVar = findFirstLocalTVar(conditionExpr);
        
        // If the condition references a variable, use TVar-based substitution
        var condition: String;
        if (referencedTVar != null) {
            condition = compileExpressionWithTVarSubstitution(conditionExpr, referencedTVar, targetVar);
        } else {
            condition = compileExpression(conditionExpr);
        }
        
        return 'Enum.filter(${arrayExpr}, fn ${targetVar} -> ${condition} end)';
    }
    
    /**
     * Generate Enum.map pattern for transforming arrays
     */
    private function generateEnumMapPattern(arrayExpr: String, loopVar: String, ebody: TypedExpr): String {
        // Convert the loop variable name to snake_case for Elixir
        var targetVar = NamingHelper.toSnakeCase(loopVar);
        
        // Find what TVar the body expression actually references
        var referencedTVar = findFirstLocalTVar(ebody);
        
        // If the body references a variable, use TVar-based substitution
        var transformation: String;
        if (referencedTVar != null) {
            transformation = compileExpressionWithTVarSubstitution(ebody, referencedTVar, targetVar);
        } else {
            transformation = compileExpression(ebody);
        }
        
        return 'Enum.map(${arrayExpr}, fn ${targetVar} -> ${transformation} end)';
    }
    
    /**
     * Find the loop variable by looking for patterns like "v.field" where v is the loop variable
     */
    private function findFirstTLocalInExpression(expr: TypedExpr): Null<TVar> {
        // Look for TField patterns first (like v.id, v.completed) which indicate loop variables
        var fieldVar = findTLocalFromFieldAccess(expr);
        if (fieldVar != null) return fieldVar;
        
        // Fallback to first TLocal found
        return findFirstTLocalInExpressionRecursive(expr);
    }

    /**
     * Find TLocal from field access patterns (e.g., v.id -> return v)
     */
    private function findTLocalFromFieldAccess(expr: TypedExpr): Null<TVar> {
        switch (expr.expr) {
            case TField(e, fa):
                switch (e.expr) {
                    case TLocal(v):
                        var varName = getOriginalVarName(v);
                        if (varName != "_g" && varName != "_g1" && varName != "_g2" && 
                            !varName.startsWith("temp_") && !varName.startsWith("_this")) {
                            return v;
                        }
                    case _:
                        // Not a TLocal field access
                }
            case TBlock(exprs):
                for (e in exprs) {
                    var result = findTLocalFromFieldAccess(e);
                    if (result != null) return result;
                }
            case TBinop(_, e1, e2):
                var result = findTLocalFromFieldAccess(e1);
                if (result != null) return result;
                return findTLocalFromFieldAccess(e2);
            case TIf(econd, eif, eelse):
                var result = findTLocalFromFieldAccess(econd);
                if (result != null) return result;
                result = findTLocalFromFieldAccess(eif);
                if (result != null) return result;
                if (eelse != null) {
                    result = findTLocalFromFieldAccess(eelse);
                    if (result != null) return result;
                }
            case TCall(e, args):
                var result = findTLocalFromFieldAccess(e);
                if (result != null) return result;
                for (arg in args) {
                    result = findTLocalFromFieldAccess(arg);
                    if (result != null) return result;
                }
            case TParenthesis(e):
                return findTLocalFromFieldAccess(e);
            case _:
                // Other expression types
        }
        return null;
    }

    /**
     * Find the first TLocal variable in an expression recursively
     */
    private function findFirstTLocalInExpressionRecursive(expr: TypedExpr): Null<TVar> {
        switch (expr.expr) {
            case TLocal(v):
                // Skip compiler-generated variables
                var varName = getOriginalVarName(v);
                if (varName != "_g" && varName != "_g1" && varName != "_g2" && 
                    !varName.startsWith("temp_") && !varName.startsWith("_this")) {
                    return v;
                }
            case TBlock(exprs):
                // Look through block expressions
                for (e in exprs) {
                    var result = findFirstTLocalInExpressionRecursive(e);
                    if (result != null) return result;
                }
            case TBinop(_, e1, e2):
                // Check both operands
                var result = findFirstTLocalInExpressionRecursive(e1);
                if (result != null) return result;
                return findFirstTLocalInExpressionRecursive(e2);
            case TField(e, fa):
                // Look in the base expression (e.g., for "v.id", check "v")
                return findFirstTLocalInExpressionRecursive(e);
            case TCall(e, args):
                // Check function and arguments
                var result = findFirstTLocalInExpressionRecursive(e);
                if (result != null) return result;
                for (arg in args) {
                    result = findFirstTLocalInExpressionRecursive(arg);
                    if (result != null) return result;
                }
            case TIf(econd, eif, eelse):
                // Check condition and branches
                var result = findFirstTLocalInExpressionRecursive(econd);
                if (result != null) return result;
                result = findFirstTLocalInExpressionRecursive(eif);
                if (result != null) return result;
                if (eelse != null) {
                    result = findFirstTLocalInExpressionRecursive(eelse);
                    if (result != null) return result;
                }
            case TArray(e1, e2):
                // Check array and index
                var result = findFirstTLocalInExpressionRecursive(e1);
                if (result != null) return result;
                return findFirstTLocalInExpressionRecursive(e2);
            case TParenthesis(e):
                // Look inside parentheses
                return findFirstTLocalInExpressionRecursive(e);
            case _:
                // Other expression types don't contain variables
        }
        return null;
    }

    /**
     * Extract transformation logic from mapping body (TVar-based version)
     */
    private function extractTransformationFromBodyWithTVar(expr: TypedExpr, sourceTVar: TVar, targetVarName: String): String {
        switch (expr.expr) {
            case TBlock(exprs):
                // Look for the actual transformation in the loop body
                for (e in exprs) {
                    switch (e.expr) {
                        case TCall(eobj, args) if (args.length > 0):
                            // This is likely _g.push(transformation) or similar
                            // Check if it's an array push operation
                            switch (eobj.expr) {
                                case TField(_, fa):
                                    // Extract and compile the transformation with variable mapping
                                    return compileExpressionWithTVarSubstitution(args[0], sourceTVar, targetVarName);
                                case _:
                            }
                        case TBinop(OpAssign, eleft, eright):
                            // Assignment pattern like _g = _g ++ [transformation]
                            // Look for list concatenation patterns
                            switch (eright.expr) {
                                case TBinop(OpAdd, _, etransform):
                                    // _g = _g ++ [transformation] pattern
                                    return compileExpressionWithTVarSubstitution(etransform, sourceTVar, targetVarName);
                                case _:
                                    return compileExpressionWithTVarSubstitution(eright, sourceTVar, targetVarName);
                            }
                        case TIf(econd, eif, eelse):
                            // Conditional transformation
                            var condition = compileExpressionWithTVarSubstitution(econd, sourceTVar, targetVarName);
                            var thenValue = compileExpressionWithTVarSubstitution(eif, sourceTVar, targetVarName);
                            var elseValue = eelse != null ? compileExpressionWithTVarSubstitution(eelse, sourceTVar, targetVarName) : targetVarName;
                            return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
                        case _:
                            // Keep looking through other expressions
                    }
                }
            case TIf(econd, eif, eelse):
                // Direct conditional transformation
                var condition = compileExpressionWithTVarSubstitution(econd, sourceTVar, targetVarName);
                var thenValue = compileExpressionWithTVarSubstitution(eif, sourceTVar, targetVarName);
                var elseValue = eelse != null ? compileExpressionWithTVarSubstitution(eelse, sourceTVar, targetVarName) : targetVarName;
                return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
            case _:
                // Try to compile the expression directly with variable mapping
                return compileExpressionWithTVarSubstitution(expr, sourceTVar, targetVarName);
        }
        return targetVarName; // Fallback: no transformation
    }

    /**
     * Extract transformation logic from mapping body (string-based version)
     */
    private function extractTransformationFromBody(expr: TypedExpr, sourceVar: String, targetVar: String): String {
        
        switch (expr.expr) {
            case TBlock(exprs):
                // Look for the actual transformation in the loop body
                for (e in exprs) {
                    switch (e.expr) {
                        case TCall(eobj, args) if (args.length > 0):
                            // This is likely _g.push(transformation) or similar
                            // Check if it's an array push operation
                            switch (eobj.expr) {
                                case TField(_, fa):
                                    // Extract and compile the transformation with variable mapping
                                    return compileExpressionWithVarMapping(args[0], sourceVar, targetVar);
                                case _:
                            }
                        case TBinop(OpAssign, eleft, eright):
                            // Assignment pattern like _g = _g ++ [transformation]
                            // Look for list concatenation patterns
                            switch (eright.expr) {
                                case TBinop(OpAdd, _, etransform):
                                    // _g = _g ++ [transformation] pattern
                                    return compileExpressionWithVarMapping(etransform, sourceVar, targetVar);
                                case _:
                                    return compileExpressionWithVarMapping(eright, sourceVar, targetVar);
                            }
                        case TIf(econd, eif, eelse):
                            // Conditional transformation
                            var condition = compileExpressionWithVarMapping(econd, sourceVar, targetVar);
                            var thenValue = compileExpressionWithVarMapping(eif, sourceVar, targetVar);
                            var elseValue = eelse != null ? compileExpressionWithVarMapping(eelse, sourceVar, targetVar) : targetVar;
                            return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
                        case _:
                            // Keep looking through other expressions
                    }
                }
            case TIf(econd, eif, eelse):
                // Direct conditional transformation
                var condition = compileExpressionWithVarMapping(econd, sourceVar, targetVar);
                var thenValue = compileExpressionWithVarMapping(eif, sourceVar, targetVar);
                var elseValue = eelse != null ? compileExpressionWithVarMapping(eelse, sourceVar, targetVar) : targetVar;
                return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
            case _:
                // Try to compile the expression directly with variable mapping
                return compileExpressionWithVarMapping(expr, sourceVar, targetVar);
        }
        return targetVar; // Fallback: no transformation
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
        // Simplified: Always use aggressive substitution for consistency
        // This ensures all TLocal variables are properly replaced regardless of the source variable
        return compileExpressionWithAggressiveSubstitution(expr, targetVar);
    }
    
    /**
     * Helper function to determine if a variable name represents a system/internal variable
     * that should not be substituted in loop contexts
     */
    private function isSystemVariable(varName: String): Bool {
        if (varName == null || varName == "") return true;
        
        // System prefixes
        if (varName.startsWith("_g") || varName.startsWith("temp_") || varName.startsWith("_this")) {
            return true;
        }
        
        // Function parameters that should not be substituted in loop contexts
        if (varName == "transform" || varName == "callback" || varName == "fn" || varName == "func" || 
            varName == "predicate" || varName == "mapper" || varName == "filter" || varName == "reduce") {
            return true;
        }
        
        // Note: Variable "v" is often used by Haxe for lambda parameters and should be substituted
        // Don't treat "v" as a system variable in loop contexts
        
        // Known system variables
        return varName == "updated_todo" || varName == "count" || varName == "result";
    }
    
    /**
     * Helper function to determine if a variable should be substituted in loop contexts
     * @param varName The variable name to check
     * @param sourceVar The specific source variable we're looking for (null for aggressive mode)
     * @param isAggressiveMode Whether to substitute any non-system variable
     */
    private function shouldSubstituteVariable(varName: String, sourceVar: String = null, isAggressiveMode: Bool = false): Bool {
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
        switch (expr.expr) {
            case TLocal(v):
                var varName = getOriginalVarName(v);
                // Use helper function for clean, maintainable variable substitution logic
                if (shouldSubstituteVariable(varName, null, true)) {
                    return targetVar;
                }
                return compileExpression(expr);
                
            case TField(e, fa):
                // Handle field access with aggressive substitution
                var obj = compileExpressionWithAggressiveSubstitution(e, targetVar);
                var fieldName = getFieldName(fa);
                return '${obj}.${fieldName}';
                
            case TUnop(op, postFix, e):
                // Handle unary operations with aggressive substitution
                var inner = compileExpressionWithAggressiveSubstitution(e, targetVar);
                // Generate the unary operation inline
                switch (op) {
                    case OpNot: return '!${inner}';
                    case OpNeg: return '-${inner}';
                    case OpIncrement: return '${inner} + 1';
                    case OpDecrement: return '${inner} - 1';
                    case _: return compileExpression(expr);
                }
                
            case TBinop(op, e1, e2):
                // Handle binary operations with aggressive substitution
                var left = compileExpressionWithAggressiveSubstitution(e1, targetVar);
                var right = compileExpressionWithAggressiveSubstitution(e2, targetVar);
                return '${left} ${compileBinop(op)} ${right}';
                
            case TCall(e, args):
                // Handle method calls with aggressive substitution
                var obj = compileExpressionWithAggressiveSubstitution(e, targetVar);
                var compiledArgs = args.map(arg -> compileExpressionWithAggressiveSubstitution(arg, targetVar));
                return '${obj}(${compiledArgs.join(", ")})';
                
            case TParenthesis(e):
                // Handle parenthesized expressions
                return "(" + compileExpressionWithAggressiveSubstitution(e, targetVar) + ")";
                
            case _:
                // For other expression types, use regular compilation
                return compileExpression(expr);
        }
    }

    /**
     * Simple approach: Always substitute all TLocal variables with the target variable
     * This replaces the complex __AGGRESSIVE__ marker system with a straightforward solution
     */
    private function extractTransformationFromBodyWithAggressiveSubstitution(expr: TypedExpr, targetVar: String): String {
        // Simply compile the expression with aggressive substitution
        // All TLocal variables will be replaced with the target variable
        return compileExpressionWithAggressiveSubstitution(expr, targetVar);
    }
    
    /**
     * Compile expression with variable substitution using TVar object comparison
     */
    private function compileExpressionWithTVarSubstitution(expr: TypedExpr, sourceTVar: TVar, targetVarName: String): String {
        switch (expr.expr) {
            case TLocal(v):
                // Debug output to understand what variables we're dealing with
                var varName = getOriginalVarName(v);
                var sourceVarName = getOriginalVarName(sourceTVar);
                // TVar-based variable identification for reliable lambda parameter substitution
                
                // Enhanced matching: try exact object match first, then fallback to more permissive matching
                if (v == sourceTVar) {
                    // Exact object match - this is definitely the same variable
                    // Exact TVar match - replace with target variable name
                    return targetVarName;
                }
                
                // Fallback: check if this is likely the same logical variable
                // If both have the same original name, they're likely the same logical variable
                if (varName == sourceVarName && varName != null && varName != "") {
                    // Name-based fallback match - same variable name
                    return targetVarName;
                }
                
                // Use helper function for aggressive substitution as fallback
                if (shouldSubstituteVariable(varName, null, true)) {
                    // Aggressive fallback - pattern-based substitution
                    return targetVarName;
                }
                
                // Not a match - compile normally
                // No match found - compile variable normally
                return compileExpression(expr);
            case TBinop(op, e1, e2):
                // Handle assignment operations specially - we want the right-hand side value, not the assignment
                if (op == OpAssign) {
                    // For assignments in ternary contexts, return just the right-hand side value
                    return compileExpressionWithTVarSubstitution(e2, sourceTVar, targetVarName);
                }
                
                // Recursively substitute in binary operations with type awareness
                if (op == OpAdd) {
                    // Check if this is string concatenation
                    var e1IsString = isStringType(e1.t);
                    var e2IsString = isStringType(e2.t);
                    var isStringConcat = e1IsString || e2IsString;
                    
                    if (isStringConcat) {
                        var left = compileExpressionWithTVarSubstitution(e1, sourceTVar, targetVarName);
                        var right = compileExpressionWithTVarSubstitution(e2, sourceTVar, targetVarName);
                        
                        // Convert non-string operands to strings
                        if (!e1IsString && e2IsString) {
                            left = convertToString(e1, left);
                        } else if (e1IsString && !e2IsString) {
                            right = convertToString(e2, right);
                        }
                        
                        return '${left} <> ${right}';
                    }
                }
                
                // For non-string addition or other operators
                var left = compileExpressionWithTVarSubstitution(e1, sourceTVar, targetVarName);
                var right = compileExpressionWithTVarSubstitution(e2, sourceTVar, targetVarName);
                return '${left} ${compileBinop(op)} ${right}';
            case TField(e, fa):
                // Handle field access on substituted variables
                // Handle field access with variable substitution
                var obj = compileExpressionWithTVarSubstitution(e, sourceTVar, targetVarName);
                var fieldName = getFieldName(fa);
                // Field access on substituted variable
                return '${obj}.${fieldName}';
            case TCall(e, args):
                // Handle method calls with substitution
                var obj = compileExpressionWithTVarSubstitution(e, sourceTVar, targetVarName);
                var compiledArgs = args.map(arg -> compileExpressionWithTVarSubstitution(arg, sourceTVar, targetVarName));
                return '${obj}(${compiledArgs.join(", ")})';
            case TArray(e1, e2):
                // Handle array access with substitution
                var arr = compileExpressionWithTVarSubstitution(e1, sourceTVar, targetVarName);
                var index = compileExpressionWithTVarSubstitution(e2, sourceTVar, targetVarName);
                return 'Enum.at(${arr}, ${index})';
            case TConst(c):
                // Constants don't need substitution
                return compileTConstant(c);
            case TIf(econd, eif, eelse):
                // Handle conditionals with substitution
                var condition = compileExpressionWithTVarSubstitution(econd, sourceTVar, targetVarName);
                var thenValue = compileExpressionWithTVarSubstitution(eif, sourceTVar, targetVarName);
                var elseValue = eelse != null ? compileExpressionWithTVarSubstitution(eelse, sourceTVar, targetVarName) : targetVarName;
                return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
            case TBlock(exprs):
                // Handle blocks with substitution
                var compiledExprs = exprs.map(e -> compileExpressionWithTVarSubstitution(e, sourceTVar, targetVarName));
                return compiledExprs.join('\n');
            case TParenthesis(e):
                // Handle parenthesized expressions with substitution
                return "(" + compileExpressionWithTVarSubstitution(e, sourceTVar, targetVarName) + ")";
            case TUnop(op, postFix, e):
                // Handle unary operations with substitution (like !variable)
                // Handle unary operations with variable substitution
                var operand = compileExpressionWithTVarSubstitution(e, sourceTVar, targetVarName);
                
                // Compile unary operator inline (from main compileExpression logic)
                var result = switch (op) {
                    case OpIncrement: '${operand} + 1';
                    case OpDecrement: '${operand} - 1'; 
                    case OpNot: '!${operand}';
                    case OpNeg: '-${operand}';
                    case OpNegBits: 'bnot(${operand})';
                    case _: operand;
                };
                
                // Unary operation with substituted operand
                return result;
            case _:
                // For other cases, fall back to regular compilation
                return compileExpression(expr);
        }
    }


    /**
     * Compile while loop with variable renamings applied
     * This handles variable collisions in desugared loop code
     */
    private function compileWhileLoopWithRenamings(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool, renamings: Map<String, String>): String {
        // Extract variables that are modified in the loop
        var modifiedVars = extractModifiedVariables(ebody);
        
        // Apply renamings to the modified variables list
        var renamedModifiedVars = modifiedVars.map(v -> {
            var originalName = v.name;
            if (renamings.exists(originalName)) {
                // Create a new VarInfo with renamed name
                {name: renamings.get(originalName), type: v.type};
            } else {
                v;
            }
        });
        
        // Create a mapping for Y combinator state variables
        // When we have renamed variables, we need to ensure all references
        // within the loop body use the renamed versions consistently
        var loopRenamings = new Map<String, String>();
        for (key => value in renamings) {
            loopRenamings.set(key, value);
        }
        
        // Also ensure any variables that appear in the condition or body
        // but aren't explicitly renamed get proper mapping
        function ensureVariableMapping(expr: TypedExpr): Void {
            switch (expr.expr) {
                case TLocal(v):
                    var varName = getOriginalVarName(v);
                    // If this variable isn't already mapped and looks like a temp variable
                    if (!loopRenamings.exists(varName)) {
                        // Check if this is a plain 'g' that should map to a renamed variable
                        if (varName == "g") {
                            // Look for _g_counter or _g_array in our renamings
                            if (renamings.exists("_g")) {
                                var renamedG = renamings.get("_g");
                                // If _g was renamed to _g_counter, map g to _g_counter too
                                loopRenamings.set("g", renamedG);
                            } else {
                                // Check if we have any _g variants
                                for (key => value in renamings) {
                                    if (key.startsWith("_g") && value.indexOf("counter") >= 0) {
                                        // Map plain g to the counter variable
                                        loopRenamings.set("g", value);
                                        break;
                                    }
                                }
                            }
                        } else if (varName.startsWith("_g") || varName.startsWith("g")) {
                            // Check if we have a renamed version with suffix
                            for (renamed in renamedModifiedVars) {
                                if (renamed.name.startsWith(varName)) {
                                    loopRenamings.set(varName, renamed.name);
                                    break;
                                }
                            }
                        }
                    }
                case TField(e, _):
                    ensureVariableMapping(e);
                case TCall(e, el):
                    ensureVariableMapping(e);
                    for (arg in el) ensureVariableMapping(arg);
                case TBinop(_, e1, e2):
                    ensureVariableMapping(e1);
                    ensureVariableMapping(e2);
                case TIf(econd, eif, eelse):
                    ensureVariableMapping(econd);
                    ensureVariableMapping(eif);
                    if (eelse != null) ensureVariableMapping(eelse);
                case TBlock(el):
                    for (e in el) ensureVariableMapping(e);
                case _:
            }
        }
        
        // Ensure all variables in the condition and body are properly mapped
        ensureVariableMapping(econd);
        ensureVariableMapping(ebody);
        
        // Compile condition with the complete renamings
        var condition = compileExpressionWithRenaming(econd, loopRenamings);
        
        // Compile the loop body with the complete renamings
        var bodyWithRenamings = compileExpressionWithRenaming(ebody, loopRenamings);
        
        if (normalWhile) {
            // while (condition) { body }
            if (renamedModifiedVars.length > 0) {
                // Convert variable names to snake_case for consistency
                var stateVarsInit = renamedModifiedVars.map(v -> {
                    var snakeName = NamingHelper.toSnakeCase(v.name);
                    return snakeName;
                });
                var stateVars = stateVarsInit.join(", ");
                
                // Generate initial values - use nil for all loop variables
                var initialValues = renamedModifiedVars.map(v -> {
                    return "nil";
                }).join(", ");
                
                // Use Y combinator pattern for the loop
                return '(\n' +
                       '  loop_helper = fn loop_fn, {${stateVars}} ->\n' +
                       '    if ${condition} do\n' +
                       '      try do\n' +
                       '        ${bodyWithRenamings}\n' +
                       '        loop_fn.(loop_fn, {${stateVars}})\n' +
                       '      catch\n' +
                       '        :break -> {${stateVars}}\n' +
                       '        :continue -> loop_fn.(loop_fn, {${stateVars}})\n' +
                       '      end\n' +
                       '    else\n' +
                       '      {${stateVars}}\n' +
                       '    end\n' +
                       '  end\n' +
                       '  {${stateVars}} = try do\n' +
                       '    loop_helper.(loop_helper, {${initialValues}})\n' +
                       '  catch\n' +
                       '    :break -> {${initialValues}}\n' +
                       '  end\n' +
                       ')';
            } else {
                // No mutable state - simpler recursive pattern
                return '(\n' +
                       '  loop_helper = fn loop_fn ->\n' +
                       '    if ${condition} do\n' +
                       '      ${bodyWithRenamings}\n' +
                       '      loop_fn.()\n' +
                       '    else\n' +
                       '      nil\n' +
                       '    end\n' +
                       '  end\n' +
                       '  loop_helper.(loop_helper)\n' +
                       ')';
            }
        } else {
            // do-while pattern (not commonly used in the codebase)
            // Use the standard while loop compilation with renamings
            return compileWhileLoop(econd, ebody, normalWhile);
        }
    }
    
    /**
     * Compile expression with multiple variable renamings applied
     * This is used to handle variable collisions in desugared loop code
     */
    private function compileExpressionWithRenaming(expr: TypedExpr, renamings: Map<String, String>): String {
        if (renamings == null || !renamings.keys().hasNext()) {
            // No renamings - compile normally
            return compileExpression(expr);
        }
        
        switch (expr.expr) {
            case TLocal(v):
                var varName = getOriginalVarName(v);
                // Check if this variable needs renaming
                if (renamings.exists(varName)) {
                    return renamings.get(varName);
                }
                // Not renamed - compile normally
                return compileExpression(expr);
                
            case TVar(v, init):
                var varName = getOriginalVarName(v);
                // Check if this variable declaration needs renaming
                if (renamings.exists(varName)) {
                    var newName = renamings.get(varName);
                    if (init != null) {
                        var compiledInit = compileExpressionWithRenaming(init, renamings);
                        return '${newName} = ${compiledInit}';
                    } else {
                        return '${newName} = nil';
                    }
                }
                // Not renamed - but still need to apply renamings to the init expression
                if (init != null) {
                    var compiledInit = compileExpressionWithRenaming(init, renamings);
                    return '${varName} = ${compiledInit}';
                } else {
                    return '${varName} = nil';
                }
                
            case TBinop(op, e1, e2):
                // Recursively apply renamings to both sides
                var left = compileExpressionWithRenaming(e1, renamings);
                var right = compileExpressionWithRenaming(e2, renamings);
                
                // Handle the operator
                return switch (op) {
                    case OpAdd: '${left} ++ ${right}'; // Array concatenation in desugared loops
                    case OpAssign: '${left} = ${right}';
                    case OpEq: '${left} == ${right}';
                    case OpNotEq: '${left} != ${right}';
                    case OpLt: '${left} < ${right}';
                    case OpLte: '${left} <= ${right}';
                    case OpGt: '${left} > ${right}';
                    case OpGte: '${left} >= ${right}';
                    case _: compileExpression(expr); // Fall back for complex operators
                };
                
            case TField(e, fa):
                // Apply renamings to the object being accessed
                var obj = compileExpressionWithRenaming(e, renamings);
                
                // Handle field access
                switch (fa) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf):
                        var fieldName = cf.get().name;
                        // Check if this is a special array property like 'length'
                        if (fieldName == "length") {
                            // In Elixir, use Enum.count for array length
                            return 'Enum.count(${obj})';
                        }
                        return '${obj}.${fieldName}';
                    case FDynamic(s):
                        return '${obj}.${s}';
                    case FClosure(_, cf):
                        var fieldName = cf.get().name;
                        return '${obj}.${fieldName}';
                    case FEnum(_, ef):
                        return ef.name;
                }
                
            case TCall(e, el):
                // Check if this is a function reference pattern (e.g., &Module.function/arity)
                var isCapture = false;
                switch (e.expr) {
                    case TField(_, FStatic(_, cf)):
                        // Check if this looks like a function capture attempt
                        // In the problematic code, we see &Reflect.fields/1(config)
                        // This should be just Reflect.fields(config)
                        isCapture = false; // We don't generate captures in this context
                    case _:
                }
                
                // Apply renamings to function and arguments
                var func = compileExpressionWithRenaming(e, renamings);
                var args = el.map(arg -> compileExpressionWithRenaming(arg, renamings));
                return '${func}(${args.join(", ")})';
                
            case TIf(econd, eif, eelse):
                var cond = compileExpressionWithRenaming(econd, renamings);
                var ifExpr = compileExpressionWithRenaming(eif, renamings);
                var elseExpr = eelse != null ? compileExpressionWithRenaming(eelse, renamings) : "nil";
                return 'if ${cond}, do: ${ifExpr}, else: ${elseExpr}';
                
            case TBlock(el):
                // Recursively compile block with renamings
                var statements = el.map(e -> compileExpressionWithRenaming(e, renamings));
                return statements.join("\n");
                
            case TWhile(econd, e, normalWhile):
                // Apply renamings within while loop by creating a modified version of the loop
                // We need to compile the while loop with renamed variables
                return compileWhileLoopWithRenamings(econd, e, normalWhile, renamings);
                
            case _:
                // For other expression types, use normal compilation
                // This is safe because the renamings are only for local variables
                return compileExpression(expr);
        }
    }
    
    /**
     * Compile expression with variable substitution (string-based version)
     */
    private function compileExpressionWithSubstitution(expr: TypedExpr, sourceVar: String, targetVar: String): String {
        switch (expr.expr) {
            case TLocal(v):
                var varName = getOriginalVarName(v);
                // Use helper function for consistent substitution logic
                if (shouldSubstituteVariable(varName, sourceVar, false)) {
                    // Variable substitution successful - replace with lambda parameter
                    return targetVar;
                }
                // Not a match - compile normally
                return compileExpression(expr);
            case TBinop(op, e1, e2):
                // Handle assignment operations specially - we want the right-hand side value, not the assignment
                if (op == OpAssign) {
                    // For assignments in ternary contexts, return just the right-hand side value
                    return compileExpressionWithSubstitution(e2, sourceVar, targetVar);
                }
                
                // Recursively substitute in binary operations with type awareness
                if (op == OpAdd) {
                    // Check if this is string concatenation
                    var e1IsString = isStringType(e1.t);
                    var e2IsString = isStringType(e2.t);
                    var isStringConcat = e1IsString || e2IsString;
                    
                    if (isStringConcat) {
                        var left = compileExpressionWithSubstitution(e1, sourceVar, targetVar);
                        var right = compileExpressionWithSubstitution(e2, sourceVar, targetVar);
                        
                        // Convert non-string operands to strings
                        if (!e1IsString && e2IsString) {
                            left = convertToString(e1, left);
                        } else if (e1IsString && !e2IsString) {
                            right = convertToString(e2, right);
                        }
                        
                        return '${left} <> ${right}';
                    }
                }
                
                // For non-string addition or other operators
                var left = compileExpressionWithSubstitution(e1, sourceVar, targetVar);
                var right = compileExpressionWithSubstitution(e2, sourceVar, targetVar);
                return '${left} ${compileBinop(op)} ${right}';
            case TField(e, fa):
                // Handle field access on substituted variables
                var obj = compileExpressionWithSubstitution(e, sourceVar, targetVar);
                var fieldName = getFieldName(fa);
                return '${obj}.${fieldName}';
            case TCall(e, args):
                // Handle method calls with substitution using a custom approach
                // We need to compile the method call properly while ensuring argument substitution
                
                // First, check if this is a simple static method call like UserRepository.find(id)
                switch (e.expr) {
                    case TField(obj, field):
                        // This is a method call like UserRepository.find(id)
                        var objStr = compileExpression(obj);
                        var methodName = getFieldName(field);
                        var substitutedArgs = args.map(arg -> compileExpressionWithSubstitution(arg, sourceVar, targetVar));
                        return '${objStr}.${methodName}(${substitutedArgs.join(", ")})';
                    default:
                        // For other types of calls, fall back to regular compilation with argument substitution
                        var compiledCall = compileExpression(e);
                        var substitutedArgs = args.map(arg -> compileExpressionWithSubstitution(arg, sourceVar, targetVar));
                        return '${compiledCall}(${substitutedArgs.join(", ")})';
                }
            case TArray(e1, e2):
                // Handle array access with substitution
                var arr = compileExpressionWithSubstitution(e1, sourceVar, targetVar);
                var index = compileExpressionWithSubstitution(e2, sourceVar, targetVar);
                return 'Enum.at(${arr}, ${index})';
            case TConst(c):
                // Constants don't need substitution
                return compileTConstant(c);
            case TIf(econd, eif, eelse):
                // Handle conditionals with substitution
                var condition = compileExpressionWithSubstitution(econd, sourceVar, targetVar);
                var thenValue = compileExpressionWithSubstitution(eif, sourceVar, targetVar);
                var elseValue = eelse != null ? compileExpressionWithSubstitution(eelse, sourceVar, targetVar) : targetVar;
                return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
            case TBlock(exprs):
                // Handle blocks with substitution
                var compiledExprs = exprs.map(e -> compileExpressionWithSubstitution(e, sourceVar, targetVar));
                return compiledExprs.join('\n');
            case TParenthesis(e):
                // Handle parenthesized expressions with substitution
                return "(" + compileExpressionWithSubstitution(e, sourceVar, targetVar) + ")";
            case _:
                // For other cases, fall back to regular compilation
                return compileExpression(expr);
        }
    }
    
    /**
     * Extract variable name from condition string
     */
    private function extractVariableFromCondition(condition: String): Null<String> {
        // Look for patterns like "todo.completed", "!todo.completed", "todo.id == id" etc.
        var varPattern = ~/\(?(\w+)\./; // Match variable before dot
        if (varPattern.match(condition)) {
            return varPattern.matched(1);
        }
        return null;
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
        var result = {
            hasSimpleAccumulator: true,  // Assume simple for now
            accumulator: "sum",
            loopVar: "i", 
            isAddition: true
        };
        
        // For range loops, we can make educated guesses based on common patterns
        // Most range loops are simple accumulation: for (i in start...end) { sum += i; }
        return result;
    }
    
    /**
     * Transform complex loop bodies that can't be simplified to Enum.reduce
     */
    private function transformComplexLoopBody(ebody: TypedExpr): String {
        // For now, compile the body as-is but replace iterator references
        var bodyStr = compileExpression(ebody);
        if (bodyStr == null) return "";
        
        // Replace references to _g with the loop variable
        bodyStr = StringTools.replace(bodyStr, "_g", "i");
        
        return bodyStr;
    }
    
    /**
     * Compile a while loop to idiomatic Elixir recursive function
     * Generates proper tail-recursive patterns that handle mutable state correctly
     */
    private function compileWhileLoop(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        // First check if this is an array-building pattern that wasn't optimized
        var arrayBuildPattern = detectArrayBuildingPattern(ebody);
        if (arrayBuildPattern != null) {
            return compileArrayBuildingLoop(econd, ebody, arrayBuildPattern);
        }
        
        // Extract variables that are modified in the loop
        var modifiedVars = extractModifiedVariables(ebody);
        var condition = compileExpression(econd);
        
        // Transform the loop body to handle mutations functionally
        var transformedBody = transformLoopBodyMutations(ebody, modifiedVars, normalWhile, condition);
        
        if (normalWhile) {
            // while (condition) { body }
            if (modifiedVars.length > 0) {
                // Convert variable names to snake_case for consistency
                var stateVarsInit = modifiedVars.map(v -> {
                    var snakeName = NamingHelper.toSnakeCase(v.name);
                    return snakeName;
                });
                var stateVars = stateVarsInit.join(", ");
                
                // Generate initial values - use nil for all loop variables
                var initialValues = modifiedVars.map(v -> {
                    return "nil";
                }).join(", ");
                
                // Use a simple recursive pattern that avoids scoping issues
                // by passing the function as a parameter (Y combinator style)
                return '(\n' +
                       '  loop_helper = fn loop_fn, {${stateVars}} ->\n' +
                       '    if ${condition} do\n' +
                       '      try do\n' +
                       '        ${transformedBody}\n' +
                       '        loop_fn.(loop_fn, {${stateVars}})\n' +
                       '      catch\n' +
                       '        :break -> {${stateVars}}\n' +
                       '        :continue -> loop_fn.(loop_fn, {${stateVars}})\n' +
                       '      end\n' +
                       '    else\n' +
                       '      {${stateVars}}\n' +
                       '    end\n' +
                       '  end\n' +
                       '  {${stateVars}} = try do\n' +
                       '    loop_helper.(loop_helper, {${initialValues}})\n' +
                       '  catch\n' +
                       '    :break -> {${initialValues}}\n' +
                       '  end\n' +
                       ')';
            } else {
                // Simple loop without state - use Y combinator pattern
                var body = compileExpression(ebody);
                return '(\n' +
                       '  loop_helper = fn loop_fn ->\n' +
                       '    if ${condition} do\n' +
                       '      try do\n' +
                       '        ${body}\n' +
                       '        loop_fn.(loop_fn)\n' +
                       '      catch\n' +
                       '        :break -> nil\n' +
                       '        :continue -> loop_fn.(loop_fn)\n' +
                       '      end\n' +
                       '    else\n' +
                       '      nil\n' +
                       '    end\n' +
                       '  end\n' +
                       '  try do\n' +
                       '    loop_helper.(loop_helper)\n' +
                       '  catch\n' +
                       '    :break -> nil\n' +
                       '  end\n' +
                       ')';
            }
        } else {
            // do { body } while (condition)
            if (modifiedVars.length > 0) {
                // Convert variable names to snake_case for consistency
                var stateVarsInit = modifiedVars.map(v -> {
                    var snakeName = NamingHelper.toSnakeCase(v.name);
                    return snakeName;
                });
                var stateVars = stateVarsInit.join(", ");
                
                // Generate initial values
                var initialValues = modifiedVars.map(v -> {
                    return "nil";
                }).join(", ");
                
                // For do-while, execute body once then use recursive pattern
                return '(\n' +
                       '  {${stateVars}} = {${initialValues}}\n' +
                       '  ${transformedBody}\n' +
                       '  loop_helper = fn loop_fn, {${stateVars}} ->\n' +
                       '    if ${condition} do\n' +
                       '      ${transformedBody}\n' +
                       '      loop_fn.(loop_fn, {${stateVars}})\n' +
                       '    else\n' +
                       '      {${stateVars}}\n' +
                       '    end\n' +
                       '  end\n' +
                       '  {${stateVars}} = loop_helper.(loop_helper, {${stateVars}})\n' +
                       ')';
            } else {
                var body = compileExpression(ebody);
                return '(\n' +
                       '  ${body}\n' +
                       '  loop_helper = fn loop_fn ->\n' +
                       '    if ${condition} do\n' +
                       '      ${body}\n' +
                       '      loop_fn.(loop_fn)\n' +
                       '    else\n' +
                       '      nil\n' +
                       '    end\n' +
                       '  end\n' +
                       '  loop_helper.(loop_helper)\n' +
                       ')';
            }
        }
    }
    
    /**
     * Detect if a loop body is building an array (common desugared pattern)
     * Returns info about the pattern if detected, null otherwise
     */
    private function detectArrayBuildingPattern(ebody: TypedExpr): Null<{indexVar: String, accumVar: String, arrayExpr: String}> {
        // Look for patterns like:
        // _g = 0;
        // _g1 = [];
        // while (_g < array.length) {
        //     var item = array[_g];
        //     _g++;
        //     _g1 = _g1 ++ [transform(item)];
        // }
        
        var indexVar: String = null;
        var accumVar: String = null;
        var arrayExpr: String = null;
        
        function checkExpr(expr: TypedExpr): Bool {
            switch (expr.expr) {
                case TBlock(exprs):
                    for (e in exprs) {
                        if (checkExpr(e)) return true;
                    }
                case TBinop(OpAssign, e1, e2):
                    // Look for array concatenation pattern: var = var ++ [...]
                    switch (e1.expr) {
                        case TLocal(v):
                            var varName = getOriginalVarName(v);
                            switch (e2.expr) {
                                case TBinop(OpAdd, e3, e4):
                                    // Check if this is array concatenation
                                    switch (e3.expr) {
                                        case TLocal(v2) if (getOriginalVarName(v2) == varName):
                                            // Found pattern: var = var ++ something
                                            // Check if the right side is an array
                                            switch (e4.expr) {
                                                case TArrayDecl(_):
                                                    accumVar = varName;
                                                    return true;
                                                case _:
                                            }
                                        case _:
                                    }
                                case _:
                            }
                        case _:
                    }
                case TUnop(OpIncrement, _, e):
                    // Look for index increment
                    switch (e.expr) {
                        case TLocal(v):
                            indexVar = getOriginalVarName(v);
                        case _:
                    }
                case _:
            }
            return false;
        }
        
        if (checkExpr(ebody) && indexVar != null && accumVar != null && indexVar != accumVar) {
            // Detected array building pattern with separate index and accumulator
            return {
                indexVar: indexVar,
                accumVar: accumVar,
                arrayExpr: arrayExpr
            };
        }
        
        return null;
    }
    
    /**
     * Compile an array-building loop pattern to idiomatic Elixir
     */
    private function compileArrayBuildingLoop(econd: TypedExpr, ebody: TypedExpr, pattern: {indexVar: String, accumVar: String, arrayExpr: String}): String {
        // Extract the array expression from the condition
        var condStr = compileExpression(econd);
        var arrayExpr = "";
        
        // Try to extract array from condition patterns like "_g < array.length"
        var arrayPattern1 = ~/^\(?([^<]+)\s*<\s*(.+?)\.length\)?$/;
        var arrayPattern2 = ~/^\(?([^<]+)\s*<\s*length\(([^)]+)\)\)?$/;
        
        if (arrayPattern1.match(condStr)) {
            arrayExpr = arrayPattern1.matched(2);
        } else if (arrayPattern2.match(condStr)) {
            arrayExpr = arrayPattern2.matched(2);
        }
        
        if (arrayExpr == "") {
            // Fallback to generic compilation if we can't extract the array
            return compileWhileLoopGeneric(econd, ebody, true);
        }
        
        // Extract the transformation from the loop body
        var transformation = extractArrayTransformation(ebody, pattern.indexVar, pattern.accumVar);
        
        if (transformation != null) {
            // Generate Enum.map pattern
            var snakeAccumVar = NamingHelper.toSnakeCase(pattern.accumVar);
            return '${snakeAccumVar} = Enum.map(${arrayExpr}, fn item -> ${transformation} end)';
        } else {
            // Fallback to generic compilation
            return compileWhileLoopGeneric(econd, ebody, true);
        }
    }
    
    /**
     * Extract the transformation applied to array elements
     */
    private function extractArrayTransformation(ebody: TypedExpr, indexVar: String, accumVar: String): Null<String> {
        // Look for the transformation in patterns like: _g1 = _g1 ++ [transform(item)]
        
        function findTransform(expr: TypedExpr): Null<String> {
            switch (expr.expr) {
                case TBlock(exprs):
                    for (e in exprs) {
                        var result = findTransform(e);
                        if (result != null) return result;
                    }
                case TBinop(OpAssign, e1, e2):
                    switch (e1.expr) {
                        case TLocal(v) if (getOriginalVarName(v) == accumVar):
                            // Found assignment to accumulator
                            switch (e2.expr) {
                                case TBinop(OpAdd, _, e4):
                                    // Extract what's being added
                                    switch (e4.expr) {
                                        case TArrayDecl(items) if (items.length == 1):
                                            // Single item being added
                                            return compileExpression(items[0]);
                                        case _:
                                    }
                                case _:
                            }
                        case _:
                    }
                case _:
            }
            return null;
        }
        
        return findTransform(ebody);
    }
    
    /**
     * Fallback generic while loop compilation
     */
    private function compileWhileLoopGeneric(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        // Revert to the original implementation for cases we can't optimize
        var modifiedVars = extractModifiedVariables(ebody);
        var condition = compileExpression(econd);
        var transformedBody = transformLoopBodyMutations(ebody, modifiedVars, normalWhile, condition);
        
        if (modifiedVars.length > 0) {
            var stateVarsInit = modifiedVars.map(v -> {
                var snakeName = NamingHelper.toSnakeCase(v.name);
                return snakeName;
            });
            var stateVars = stateVarsInit.join(", ");
            var initialValues = modifiedVars.map(v -> "nil").join(", ");
            
            return '(\n' +
                   '  loop_helper = fn loop_fn, {${stateVars}} ->\n' +
                   '    if ${condition} do\n' +
                   '      try do\n' +
                   '        ${transformedBody}\n' +
                   '        loop_fn.(loop_fn, {${stateVars}})\n' +
                   '      catch\n' +
                   '        :break -> {${stateVars}}\n' +
                   '        :continue -> loop_fn.(loop_fn, {${stateVars}})\n' +
                   '      end\n' +
                   '    else\n' +
                   '      {${stateVars}}\n' +
                   '    end\n' +
                   '  end\n' +
                   '  {${stateVars}} = try do\n' +
                   '    loop_helper.(loop_helper, {${initialValues}})\n' +
                   '  catch\n' +
                   '    :break -> {${initialValues}}\n' +
                   '  end\n' +
                   ')';
        } else {
            var body = compileExpression(ebody);
            return '(\n' +
                   '  loop_helper = fn loop_fn ->\n' +
                   '    if ${condition} do\n' +
                   '      try do\n' +
                   '        ${body}\n' +
                   '        loop_fn.(loop_fn)\n' +
                   '      catch\n' +
                   '        :break -> nil\n' +
                   '        :continue -> loop_fn.(loop_fn)\n' +
                   '      end\n' +
                   '    else\n' +
                   '      nil\n' +
                   '    end\n' +
                   '  end\n' +
                   '  try do\n' +
                   '    loop_helper.(loop_helper)\n' +
                   '  catch\n' +
                   '    :break -> nil\n' +
                   '  end\n' +
                   ')';
        }
    }
    
    /**
     * Extract variables that are modified within a loop body
     */
    private function extractModifiedVariables(expr: TypedExpr): Array<{name: String, type: String}> {
        var modifiedVars: Array<{name: String, type: String}> = [];
        
        function analyzeExpr(e: TypedExpr): Void {
            switch (e.expr) {
                case TBinop(OpAssign, e1, e2):
                    // Variable assignment: x = value
                    switch (e1.expr) {
                        case TLocal(v):
                            modifiedVars.push({name: getOriginalVarName(v), type: "local"});
                        case _:
                    }
                case TBinop(OpAssignOp(_), e1, e2):
                    // Compound assignment: x += value, x *= value, etc.
                    switch (e1.expr) {
                        case TLocal(v):
                            modifiedVars.push({name: getOriginalVarName(v), type: "local"});
                        case _:
                    }
                case TUnop(OpIncrement | OpDecrement, _, e1):
                    // Increment/decrement: x++, ++x, x--, --x
                    switch (e1.expr) {
                        case TLocal(v):
                            modifiedVars.push({name: getOriginalVarName(v), type: "local"});
                        case _:
                    }
                case TBlock(exprs):
                    for (expr in exprs) analyzeExpr(expr);
                case TIf(_, ifExpr, elseExpr):
                    analyzeExpr(ifExpr);
                    if (elseExpr != null) analyzeExpr(elseExpr);
                case _:
                    // Recursively analyze nested expressions if needed
            }
        }
        
        analyzeExpr(expr);
        
        // Remove duplicates
        var uniqueVars: Array<{name: String, type: String}> = [];
        var seen = new Map<String, Bool>();
        for (v in modifiedVars) {
            if (!seen.exists(v.name)) {
                uniqueVars.push(v);
                seen.set(v.name, true);
            }
        }
        
        return uniqueVars;
    }
    
    /**
     * Transform loop body to handle mutations functionally by returning updated state
     */
    private function transformLoopBodyMutations(expr: TypedExpr, modifiedVars: Array<{name: String, type: String}>, normalWhile: Bool, condition: String): String {
        // We need to transform the body so that mutations become value updates
        // and the function returns the new state tuple
        
        if (modifiedVars.length == 0) {
            return compileExpression(expr);
        }
        
        // Track variable updates as we compile the expression
        var updates = new Map<String, String>();
        var compiledBody = compileExpressionWithMutationTracking(expr, updates);
        
        // Generate the return statement with updated values - convert to snake_case for consistency
        var stateVars = modifiedVars.map(v -> {
            var snakeName = NamingHelper.toSnakeCase(v.name);
            return updates.exists(v.name) ? updates.get(v.name) : snakeName;
        }).join(", ");
        
        if (normalWhile) {
            // For while loops, we need to be careful about variable naming
            // Check if we're mistakenly using the same variable for different purposes
            var hasArrayBuilding = compiledBody.indexOf("++") > -1 && compiledBody.indexOf("[") > -1;
            if (hasArrayBuilding) {
                // This might be an array building pattern - need special handling
                // Don't duplicate the recursive call if it's already in the body
                if (compiledBody.indexOf("loop_fn.(") > -1) {
                    return compiledBody;
                }
            }
            // For while loops, just call recursively with updated state
            return '${compiledBody}\n      loop_fn.({${stateVars}})';
        } else {
            // For do-while loops, check condition after executing body
            return '${compiledBody}\n    if ${condition}, do: loop_fn.({${stateVars}}), else: {${stateVars}}';
        }
    }
    
    /**
     * Compile expression while tracking variable mutations
     */
    private function compileExpressionWithMutationTracking(expr: TypedExpr, updates: Map<String, String>): String {
        return switch (expr.expr) {
            case TBlock(exprs):
                var results = [];
                
                // Check for array building pattern initialization
                var hasArrayInit = false;
                var arrayVar = "";
                for (e in exprs) {
                    switch (e.expr) {
                        case TVar(v, init):
                            // Check if this is array initialization
                            if (init != null) {
                                switch (init.expr) {
                                    case TArrayDecl([]):
                                        hasArrayInit = true;
                                        arrayVar = getOriginalVarName(v);
                                    case _:
                                }
                            }
                        case _:
                    }
                }
                
                // Process expressions
                for (e in exprs) {
                    var compiled = compileExpressionWithMutationTracking(e, updates);
                    // Skip problematic duplicate initialization
                    if (hasArrayInit && compiled.indexOf(arrayVar + " = 0") > -1) {
                        // Skip this - it's overwriting the array initialization
                        continue;
                    }
                    results.push(compiled);
                }
                results.join("\n      ");
                
            case TBinop(OpAssign, e1, e2):
                // Handle variable assignment
                switch (e1.expr) {
                    case TLocal(v):
                        var originalName = getOriginalVarName(v);
                        var snakeName = NamingHelper.toSnakeCase(originalName);
                        var rightSide = compileExpression(e2);
                        
                        // Check if this is array concatenation
                        if (rightSide.indexOf(snakeName + " ++ [") > -1) {
                            // This is array building - keep the accumulator separate
                            updates.set(originalName, snakeName);
                            rightSide;
                        } else {
                            updates.set(originalName, rightSide);
                            // Generate actual assignment, not just a comment
                            '${snakeName} = ${rightSide}';
                        }
                    case _:
                        compileExpression(expr);
                }
                
            case TBinop(OpAssignOp(innerOp), e1, e2):
                // Handle compound assignment
                switch (e1.expr) {
                    case TLocal(v):
                        var originalName = getOriginalVarName(v);
                        var snakeName = NamingHelper.toSnakeCase(originalName);
                        var rightSide = compileExpression(e2);
                        var opStr = compileBinop(innerOp);
                        
                        // Handle string concatenation special case
                        if (innerOp == OpAdd) {
                            var isStringOp = switch (e1.t) {
                                case TInst(t, _) if (t.get().name == "String"): true;
                                case _: false;
                            };
                            opStr = isStringOp ? "<>" : "+";
                        }
                        
                        var newValue = '${snakeName} ${opStr} ${rightSide}';
                        updates.set(originalName, newValue);
                        // Generate actual assignment, not just a comment
                        '${snakeName} = ${newValue}';
                    case _:
                        compileExpression(expr);
                }
                
            case TUnop(OpIncrement | OpDecrement, postFix, e1):
                // Handle increment/decrement
                switch (e1.expr) {
                    case TLocal(v):
                        var originalName = getOriginalVarName(v);
                        var snakeName = NamingHelper.toSnakeCase(originalName);
                        var op = switch (expr.expr) {
                            case TUnop(OpIncrement, _, _): "+";
                            case TUnop(OpDecrement, _, _): "-";
                            case _: "+";
                        };
                        var newValue = '${snakeName} ${op} 1';
                        updates.set(originalName, newValue);
                        // Generate actual assignment, not just a comment
                        '${snakeName} = ${newValue}';
                    case _:
                        compileExpression(expr);
                }
                
            case TVar(v, init):
                // Handle variable declarations in loop body
                var varName = getOriginalVarName(v);
                var snakeVarName = NamingHelper.toSnakeCase(varName);
                if (init != null) {
                    var initValue = compileExpression(init);
                    '${snakeVarName} = ${initValue}';
                } else {
                    '${snakeVarName} = nil';
                }
                
            case _:
                // For other expressions, compile normally
                compileExpression(expr);
        };
    }
    
    /**
     * Check if a method name is a common array method
     */
    private function isArrayMethod(methodName: String): Bool {
        return switch (methodName) {
            case "join", "push", "pop", "length", "map", "filter", 
                 "concat", "contains", "indexOf", "reduce", "forEach",
                 "find", "findIndex", "slice", "splice", "reverse",
                 "sort", "shift", "unshift", "every", "some",
                 // ArrayTools extension methods
                 "fold", "exists", "any", "foreach", "all", 
                 "take", "drop", "flatMap":
                true;
            case _:
                false;
        };
    }
    
    /**
     * Check if a method name is a MapTools static extension method
     */
    private function isMapMethod(methodName: String): Bool {
        return switch (methodName) {
            case "filter", "map", "mapKeys", "reduce", "any", "all", 
                 "find", "keys", "values", "toArray", "fromArray", 
                 "merge", "isEmpty", "size":
                true;
            case _:
                false;
        };
    }
    
    /**
     * Check if a method name is an OptionTools static extension method
     */
    private function isOptionMethod(methodName: String): Bool {
        return switch (methodName) {
            case "map", "then", "flatMap", "flatten", "filter", "unwrap", 
                 "lazyUnwrap", "or", "lazyOr", "isSome", "isNone", 
                 "all", "values", "toResult", "fromResult", "fromNullable",
                 "toNullable", "toReply", "expect", "some", "none", "apply":
                true;
            case _:
                false;
        };
    }
    
    /**
     * Check if a method name is a ResultTools static extension method
     */
    private function isResultMethod(methodName: String): Bool {
        return switch (methodName) {
            case "map", "flatMap", "bind", "fold", "filter", "isOk", "isError", 
                 "unwrap", "unwrapOr", "unwrapOrElse", "mapError", "bimap",
                 "ok", "error", "sequence", "traverse", "toOption":
                true;
            case _:
                false;
        };
    }
    
    /**
     * Check if an enum type has static extension methods and compile them
     * @param enumType The enum type being called on
     * @param methodName The method name being called
     * @param objStr The compiled object expression
     * @param args The method arguments
     * @return Compiled static extension call or null if not applicable
     */
    private function compileADTStaticExtension(enumType: haxe.macro.Type.EnumType, methodName: String, objStr: String, args: Array<TypedExpr>): Null<String> {
        var toolsModule: String = null;
        var isExtensionMethod: Bool = false;
        
        // Check which ADT type this is and if the method is valid
        if (enumType.module == "haxe.ds.Option" && enumType.name == "Option") {
            toolsModule = "OptionTools";
            isExtensionMethod = isOptionMethod(methodName);
        } else if (enumType.module == "haxe.functional.Result" && enumType.name == "Result") {
            toolsModule = "ResultTools";
            isExtensionMethod = isResultMethod(methodName);
        }
        
        if (toolsModule != null && isExtensionMethod) {
            var compiledArgs = args.map(arg -> compileExpression(arg));
            // Call ToolsModule.method(object, args...) for static extension methods
            return '${toolsModule}.${methodName}(${objStr}${compiledArgs.length > 0 ? ", " + compiledArgs.join(", ") : ""})';
        }
        
        return null;
    }
    
    /**
     * Compile Haxe array method calls to idiomatic Elixir Enum functions.
     * 
     * Transforms common array operations to their Elixir equivalents:
     * - `array.map(fn)` → `Enum.map(array, fn)`
     * - `array.filter(fn)` → `Enum.filter(array, fn)` (with variable substitution)
     * - `array.join(sep)` → `Enum.join(array, sep)`
     * - `array.push(item)` → `array ++ [item]`
     * 
     * Special handling for lambda expressions includes variable substitution to
     * ensure proper parameter naming in generated Elixir functions.
     * 
     * @param objStr The compiled array object expression
     * @param methodName The method being called (e.g., "filter", "map")
     * @param args The method arguments as TypedExpr array
     * @return The compiled Elixir method call
     */
    private function compileArrayMethod(objStr: String, methodName: String, args: Array<TypedExpr>): String {
        // Save current loop context and disable it for argument compilation
        // Array method arguments should not be subject to loop variable substitution
        var previousContext = isInLoopContext;
        isInLoopContext = false;
        var compiledArgs = args.map(arg -> compileExpression(arg));
        isInLoopContext = previousContext;
        
        return switch (methodName) {
            case "join":
                // array.join(separator) → Enum.join(array, separator)
                if (compiledArgs.length > 0) {
                    'Enum.join(${objStr}, ${compiledArgs[0]})';
                } else {
                    'Enum.join(${objStr}, "")';
                }
            case "push":
                // array.push(item) → array ++ [item]
                if (compiledArgs.length > 0) {
                    '${objStr} ++ [${compiledArgs[0]}]';
                } else {
                    objStr;
                }
            case "pop":
                // array.pop() → List.last(array) (note: doesn't modify original)
                'List.last(${objStr})';
            case "shift":
                // array.shift() → hd(array) (gets first element, doesn't modify)
                'hd(${objStr})';
            case "unshift":
                // array.unshift(item) → [item | array]
                if (compiledArgs.length > 0) {
                    '[${compiledArgs[0]} | ${objStr}]';
                } else {
                    objStr;
                }
            case "length":
                // array.length → length(array)
                'length(${objStr})';
            case "copy":
                // array.copy() → array (lists are immutable, so just return the list)
                objStr;
            case "reverse":
                // array.reverse() → Enum.reverse(array)
                'Enum.reverse(${objStr})';
            case "sort":
                // array.sort(compareFn) → Enum.sort(array) or Enum.sort_by(array, fn)
                if (compiledArgs.length > 0) {
                    'Enum.sort(${objStr}, ${compiledArgs[0]})';
                } else {
                    'Enum.sort(${objStr})';
                }
            case "map":
                // array.map(fn) → Enum.map(array, fn)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(this, func, "item");
                                return 'Enum.map(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.map(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.map(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr;
                }
            case "filter":
                // array.filter(fn) → Enum.filter(array, fn)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(this, func, "item");
                                return 'Enum.filter(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.filter(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.filter(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr;
                }
            case "concat":
                // array.concat(other) → array ++ other
                if (compiledArgs.length > 0) {
                    '${objStr} ++ ${compiledArgs[0]}';
                } else {
                    objStr;
                }
            case "contains":
                // array.contains(elem) → Enum.member?(array, elem)
                if (compiledArgs.length > 0) {
                    'Enum.member?(${objStr}, ${compiledArgs[0]})';
                } else {
                    'false';
                }
            case "indexOf":
                // array.indexOf(elem) → Enum.find_index(array, &(&1 == elem))
                if (compiledArgs.length > 0) {
                    'Enum.find_index(${objStr}, &(&1 == ${compiledArgs[0]}))';
                } else {
                    'nil';
                }
            case "reduce", "fold":
                // array.reduce((acc, item) -> acc + item, initial) → Enum.reduce(array, initial, fn item, acc -> acc + item end)
                if (compiledArgs.length >= 2) {
                    // Check if the first argument is a lambda that needs variable substitution
                    if (args.length >= 1) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation for reduce
                                // Note: Haxe uses (acc, item) but Elixir uses (item, acc) parameter order
                                
                                // Enable loop context for lambda body compilation
                                var previousContext = isInLoopContext;
                                isInLoopContext = true;
                                
                                // Extract parameter information with reordering
                                var accParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var itemParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                var elixirItemName = "item";
                                var elixirAccName = "acc";
                                
                                // Apply variable substitution for both parameters
                                var bodyAfterAccSubst = accParamTVar != null ? 
                                    compileExpressionWithTVarSubstitution(func.expr, accParamTVar, elixirAccName) : 
                                    compileExpression(func.expr);
                                
                                // Apply second parameter substitution
                                var compiledBody = bodyAfterAccSubst;
                                if (itemParamTVar != null) {
                                    var originalItemName = getOriginalVarName(itemParamTVar);
                                    compiledBody = compiledBody.replace(originalItemName, elixirItemName);
                                }
                                
                                // Restore previous context
                                isInLoopContext = previousContext;
                                
                                // Elixir's Enum.reduce expects (collection, initial, fn item, acc -> result end)
                                return 'Enum.reduce(${objStr}, ${compiledArgs[1]}, fn ${elixirItemName}, ${elixirAccName} -> ${compiledBody} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.reduce(${objStr}, ${compiledArgs[1]}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.reduce(${objStr}, ${compiledArgs[1]}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr; // Not enough arguments for reduce
                }
            case "find":
                // array.find(predicate) → Enum.find(array, predicate)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(this, func, "item");
                                return 'Enum.find(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.find(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.find(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    'nil';
                }
            case "findIndex":
                // array.findIndex(predicate) → Enum.find_index(array, predicate)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(this, func, "item");
                                return 'Enum.find_index(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.find_index(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.find_index(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    'nil';
                }
            case "exists", "any":
                // array.exists(predicate) → Enum.any?(array, predicate)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(this, func, "item");
                                return 'Enum.any?(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.any?(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.any?(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    'false';
                }
            case "foreach", "all":
                // array.foreach(predicate) → Enum.all?(array, predicate)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(this, func, "item");
                                return 'Enum.all?(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.all?(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.all?(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    'true';
                }
            case "forEach":
                // array.forEach(action) → Enum.each(array, action)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(this, func, "item");
                                return 'Enum.each(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.each(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.each(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    ':ok';
                }
            case "take":
                // array.take(n) → Enum.take(array, n)
                if (compiledArgs.length > 0) {
                    'Enum.take(${objStr}, ${compiledArgs[0]})';
                } else {
                    objStr;
                }
            case "drop":
                // array.drop(n) → Enum.drop(array, n)
                if (compiledArgs.length > 0) {
                    'Enum.drop(${objStr}, ${compiledArgs[0]})';
                } else {
                    objStr;
                }
            case "flatMap":
                // array.flatMap(fn) → Enum.flat_map(array, fn)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(this, func, "item");
                                return 'Enum.flat_map(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.flat_map(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.flat_map(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr;
                }
            case _:
                // Default: try to call as a regular method
                '${objStr}.${methodName}(${compiledArgs.join(", ")})';
        };
    }
    
    /**
     * Compile MapTools static extension methods to idiomatic Elixir Map module calls
     */
    private function compileMapMethod(objStr: String, methodName: String, args: Array<TypedExpr>): String {
        // Save current loop context and disable it for argument compilation
        var previousContext = isInLoopContext;
        isInLoopContext = false;
        var compiledArgs = args.map(arg -> compileExpression(arg));
        isInLoopContext = previousContext;
        
        return switch (methodName) {
            case "filter":
                // map.filter((k, v) -> bool) → Map.filter(map, fn {k, v} -> bool end)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Handle lambda with two parameters: key and value
                                var keyParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[0].v)) : "key";
                                var valueParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[1].v)) : "value";
                                var keyParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var valueParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                
                                // Apply dual variable substitution like in reduce
                                var tempBody = func.expr;
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compileExpression(tempBody);
                                return 'Map.filter(${objStr}, fn {${keyParamName}, ${valueParamName}} -> ${body} end)';
                            case _:
                                return 'Map.filter(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Map.filter(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr;
                }
            case "map":
                // map.map((k, v) -> newV) → Map.new(map, fn {k, v} -> {k, newV} end) 
                if (compiledArgs.length > 0) {
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                var keyParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[0].v)) : "key";
                                var valueParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[1].v)) : "value";
                                var keyParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var valueParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                
                                var tempBody = func.expr;
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compileExpression(tempBody);
                                return 'Map.new(${objStr}, fn {${keyParamName}, ${valueParamName}} -> {${keyParamName}, ${body}} end)';
                            case _:
                                return 'Map.new(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Map.new(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr;
                }
            case "mapKeys":
                // map.mapKeys((k, v) -> newK) → Map.new(map, fn {k, v} -> {newK, v} end)
                if (compiledArgs.length > 0) {
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                var keyParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[0].v)) : "key";
                                var valueParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[1].v)) : "value";
                                var keyParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var valueParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                
                                var tempBody = func.expr;
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compileExpression(tempBody);
                                return 'Map.new(${objStr}, fn {${keyParamName}, ${valueParamName}} -> {${body}, ${valueParamName}} end)';
                            case _:
                                return 'Map.new(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Map.new(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr;
                }
            case "reduce":
                // map.reduce(initial, (acc, k, v) -> newAcc) → Map.fold(map, initial, fn k, v, acc -> newAcc end)
                if (compiledArgs.length >= 2) {
                    if (args.length >= 2) {
                        switch (args[1].expr) {
                            case TFunction(func):
                                // Parameters: acc, key, value in Haxe → key, value, acc in Elixir
                                var accParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[0].v)) : "acc";
                                var keyParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[1].v)) : "key";
                                var valueParamName = func.args.length > 2 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[2].v)) : "value";
                                
                                var accParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var keyParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                var valueParamTVar = func.args.length > 2 ? func.args[2].v : null;
                                
                                var tempBody = func.expr;
                                if (accParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, accParamTVar, accParamName);
                                }
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compileExpression(tempBody);
                                
                                return 'Map.fold(${objStr}, ${compiledArgs[0]}, fn ${keyParamName}, ${valueParamName}, ${accParamName} -> ${body} end)';
                            case _:
                                return 'Map.fold(${objStr}, ${compiledArgs[0]}, ${compiledArgs[1]})';
                        }
                    } else {
                        return 'Map.fold(${objStr}, ${compiledArgs[0]}, ${compiledArgs[1]})';
                    }
                } else {
                    objStr;
                }
            case "any":
                // map.any((k, v) -> bool) → Enum.any?(Map.to_list(map), fn {k, v} -> bool end)
                if (compiledArgs.length > 0) {
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                var keyParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[0].v)) : "key";
                                var valueParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[1].v)) : "value";
                                var keyParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var valueParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                
                                var tempBody = func.expr;
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compileExpression(tempBody);
                                return 'Enum.any?(Map.to_list(${objStr}), fn {${keyParamName}, ${valueParamName}} -> ${body} end)';
                            case _:
                                return 'Enum.any?(Map.to_list(${objStr}), ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.any?(Map.to_list(${objStr}), ${compiledArgs[0]})';
                    }
                } else {
                    'false';
                }
            case "all":
                // map.all((k, v) -> bool) → Enum.all?(Map.to_list(map), fn {k, v} -> bool end)
                if (compiledArgs.length > 0) {
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                var keyParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[0].v)) : "key";
                                var valueParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[1].v)) : "value";
                                var keyParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var valueParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                
                                var tempBody = func.expr;
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compileExpression(tempBody);
                                return 'Enum.all?(Map.to_list(${objStr}), fn {${keyParamName}, ${valueParamName}} -> ${body} end)';
                            case _:
                                return 'Enum.all?(Map.to_list(${objStr}), ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.all?(Map.to_list(${objStr}), ${compiledArgs[0]})';
                    }
                } else {
                    'true';
                }
            case "find":
                // map.find((k, v) -> bool) → Enum.find(Map.to_list(map), fn {k, v} -> bool end)
                if (compiledArgs.length > 0) {
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                var keyParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[0].v)) : "key";
                                var valueParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[1].v)) : "value";
                                var keyParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var valueParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                
                                var tempBody = func.expr;
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compileExpression(tempBody);
                                return 'Enum.find(Map.to_list(${objStr}), fn {${keyParamName}, ${valueParamName}} -> ${body} end)';
                            case _:
                                return 'Enum.find(Map.to_list(${objStr}), ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.find(Map.to_list(${objStr}), ${compiledArgs[0]})';
                    }
                } else {
                    'nil';
                }
            case "keys":
                // map.keys() → Map.keys(map)
                'Map.keys(${objStr})';
            case "values":
                // map.values() → Map.values(map)
                'Map.values(${objStr})';
            case "toArray":
                // map.toArray() → Map.to_list(map)
                'Map.to_list(${objStr})';
            case "fromArray":
                // MapTools.fromArray(pairs) → Map.new(pairs)
                if (compiledArgs.length > 0) {
                    'Map.new(${compiledArgs[0]})';
                } else {
                    'Map.new()';
                }
            case "merge":
                // map.merge(otherMap) → Map.merge(map, otherMap)
                if (compiledArgs.length > 0) {
                    'Map.merge(${objStr}, ${compiledArgs[0]})';
                } else {
                    objStr;
                }
            case "isEmpty":
                // map.isEmpty() → Map.equal?(map, %{})
                'Map.equal?(${objStr}, %{})';
            case "size":
                // map.size() → Map.size(map)
                'Map.size(${objStr})';
            case _:
                // Default: try to call as a regular method
                '${objStr}.${methodName}(${compiledArgs.join(", ")})';
        };
    }
    
    /**
     * Substitute a variable in an expression for MapTools dual/triple parameter support
     */
    private function substituteVariableInExpression(expr: TypedExpr, sourceTVar: TVar, targetVarName: String): TypedExpr {
        return switch (expr.expr) {
            case TLocal(v):
                if (v == sourceTVar) {
                    // Create new expression with substituted variable reference
                    var compiledExpr = compileExpression(expr);
                    var substitutedExpr = compiledExpr.replace(v.name, targetVarName);
                    // Return expression that compiles to the substituted string
                    {expr: TConst(TString(substitutedExpr)), t: expr.t, pos: expr.pos};
                } else {
                    expr;
                }
            case TBinop(op, e1, e2):
                var newE1 = substituteVariableInExpression(e1, sourceTVar, targetVarName);
                var newE2 = substituteVariableInExpression(e2, sourceTVar, targetVarName);
                {expr: TBinop(op, newE1, newE2), t: expr.t, pos: expr.pos};
            case TField(e, fa):
                var newE = substituteVariableInExpression(e, sourceTVar, targetVarName);
                {expr: TField(newE, fa), t: expr.t, pos: expr.pos};
            case TCall(e, args):
                var newE = substituteVariableInExpression(e, sourceTVar, targetVarName);
                var newArgs = args.map(arg -> substituteVariableInExpression(arg, sourceTVar, targetVarName));
                {expr: TCall(newE, newArgs), t: expr.t, pos: expr.pos};
            case _:
                // For other cases, no substitution needed
                expr;
        };
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
    private function compileHxxCall(args: Array<TypedExpr>): String {
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
        if (args.length == 0) return null;
        
        // Try to detect schema from first argument type
        var firstArgType = args[0].t;
        switch (firstArgType) {
            case TInst(t, _):
                var classType = t.get();
                // Check if this is a schema class
                if (classType.meta.has(":schema")) {
                    return classType.name;
                }
            case _:
        }
        
        return null;
    }
    
    /**
     * Get field name from field access
     * Handles @:native annotations on extern methods
     */
    private function getFieldName(fa: FieldAccess): String {
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
        var hasRestart = compiledFields.exists("restart");
        var hasShutdown = compiledFields.exists("shutdown");
        var hasType = compiledFields.exists("type");
        var hasModules = compiledFields.exists("modules");
        
        // If we have explicit restart/shutdown configuration, use traditional map
        if (hasRestart || hasShutdown || hasType || hasModules) {
            return TRADITIONAL_MAP;
        }
        
        // For minimal specs with only id + start, determine if they can use modern format
        var idField = compiledFields.get("id");
        var startField = compiledFields.get("start");
        
        if (idField != null && startField != null) {
            // Check if this looks like a simple start spec (suitable for tuple format)
            if (hasSimpleStartPattern(startField)) {
                return MODERN_TUPLE;
            }
        }
        
        // Default to traditional map format for safety
        return TRADITIONAL_MAP;
    }
    
    /**
     * Check if a start field follows simple patterns suitable for modern tuple format
     */
    private function hasSimpleStartPattern(startField: String): Bool {
        // Look for simple start patterns like {Module, :start_link, [args]}
        // These can be converted to tuple format like {Module, args}
        
        // Check for start_link function calls (standard OTP pattern)
        if (startField.indexOf(":start_link") > -1) {
            return true;
        }
        
        // Check for empty args or simple configuration args
        if (startField.indexOf(", []") > -1 || startField.indexOf("[%{") > -1) {
            return true;
        }
        
        return false;
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
    private function compileChildSpec(fields: Array<{name: String, expr: TypedExpr}>, classType: Null<ClassType>): String {
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
    private function compileSupervisorOptions(fields: Array<{name: String, expr: TypedExpr}>, classType: Null<ClassType>): String {
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
    private function isElixirSyntaxCall(obj: TypedExpr, fieldName: String): Bool {
        switch (obj.expr) {
            case TTypeExpr(moduleType):
                // Check if this is the elixir.Syntax module
                switch (moduleType) {
                    case TClassDecl(c):
                        var classRef = c.get();
                        var fullPath = classRef.pack.join(".") + (classRef.pack.length > 0 ? "." : "") + classRef.name;
                        return fullPath == "elixir.Syntax";
                    case TTypeDecl(t):
                        // Handle typedef case (though elixir.Syntax should be a class)
                        var typeRef = t.get();
                        var fullPath = typeRef.pack.join(".") + (typeRef.pack.length > 0 ? "." : "") + typeRef.name;
                        return fullPath == "elixir.Syntax";
                    case _:
                        return false;
                }
            case _:
                return false;
        }
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
    private function compileElixirSyntaxCall(methodName: String, args: Array<TypedExpr>): String {
        return switch (methodName) {
            case "code":
                // elixir.Syntax.code(code, ...args) → direct injection
                if (args.length == 0) {
                    Context.error("elixir.Syntax.code requires at least one String argument.", Context.currentPos());
                    "";
                } else {
                    // Get the code string from the first argument
                    var codeString = switch (args[0].expr) {
                        case TConst(TString(s)): s;
                        case _: 
                            Context.error("elixir.Syntax.code first parameter must be a constant String.", args[0].pos);
                            "";
                    };
                    
                    // Compile the remaining arguments
                    var compiledArgs = [];
                    for (i in 1...args.length) {
                        compiledArgs.push(compileExpression(args[i]));
                    }
                    
                    // Validate placeholder count matches argument count (js.Syntax pattern)
                    var placeholderCount = 0;
                    ~/{(\d+)}/g.map(codeString, function(ereg) {
                        var num = Std.parseInt(ereg.matched(1));
                        if (num != null && num >= placeholderCount) {
                            placeholderCount = num + 1;
                        }
                        return ereg.matched(0);
                    });
                    
                    if (placeholderCount > compiledArgs.length) {
                        Context.error('elixir.Syntax.code() requires ${placeholderCount} arguments but ${compiledArgs.length} provided', Context.currentPos());
                    }
                    
                    // Replace {N} placeholders with compiled arguments (following js.Syntax pattern)
                    var result = ~/{(\d+)}/g.map(codeString, function(ereg) {
                        var num = Std.parseInt(ereg.matched(1));
                        return (num != null && num < compiledArgs.length) ? compiledArgs[num] : ereg.matched(0);
                    });
                    
                    return result;
                }
                
            case "plainCode":
                // elixir.Syntax.plainCode(code) → direct injection without interpolation
                if (args.length != 1) {
                    Context.error("elixir.Syntax.plainCode requires exactly one String argument.", Context.currentPos());
                    "";
                } else {
                    switch (args[0].expr) {
                        case TConst(TString(s)): s;
                        case _:
                            Context.error("elixir.Syntax.plainCode parameter must be a constant String.", args[0].pos);
                            "";
                    }
                }
                
            case "atom":
                // elixir.Syntax.atom(name) → :name
                if (args.length != 1) {
                    Context.error("elixir.Syntax.atom requires exactly one String argument.", Context.currentPos());
                    "";
                } else {
                    switch (args[0].expr) {
                        case TConst(TString(s)): ':$s';
                        case _:
                            var atomName = compileExpression(args[0]);
                            ':${atomName}';
                    }
                }
                
            case "tuple":
                // elixir.Syntax.tuple(...args) → {arg1, arg2, ...}
                var compiledArgs = args.map(arg -> compileExpression(arg));
                '{${compiledArgs.join(", ")}}';
                
            case "keyword":
                // elixir.Syntax.keyword([key1, value1, key2, value2]) → [key1: value1, key2: value2]
                if (args.length != 1) {
                    Context.error("elixir.Syntax.keyword requires exactly one Array argument.", Context.currentPos());
                    "";
                } else {
                    switch (args[0].expr) {
                        case TArrayDecl(elements):
                            if (elements.length % 2 != 0) {
                                Context.error("elixir.Syntax.keyword array must have an even number of elements (key-value pairs).", args[0].pos);
                                "";
                            } else {
                                var pairs = [];
                                var i = 0;
                                while (i < elements.length) {
                                    var key = compileExpression(elements[i]);
                                    var value = compileExpression(elements[i + 1]);
                                    pairs.push('${key}: ${value}');
                                    i += 2;
                                }
                                '[${pairs.join(", ")}]';
                            }
                        case _:
                            Context.error("elixir.Syntax.keyword parameter must be an array literal.", args[0].pos);
                            "";
                    }
                }
                
            case "map":
                // elixir.Syntax.map([key1, value1, key2, value2]) → %{key1 => value1, key2 => value2}
                if (args.length != 1) {
                    Context.error("elixir.Syntax.map requires exactly one Array argument.", Context.currentPos());
                    "";
                } else {
                    switch (args[0].expr) {
                        case TArrayDecl(elements):
                            if (elements.length % 2 != 0) {
                                Context.error("elixir.Syntax.map array must have an even number of elements (key-value pairs).", args[0].pos);
                                "";
                            } else {
                                var pairs = [];
                                var i = 0;
                                while (i < elements.length) {
                                    var key = compileExpression(elements[i]);
                                    var value = compileExpression(elements[i + 1]);
                                    pairs.push('${key} => ${value}');
                                    i += 2;
                                }
                                '%{${pairs.join(", ")}}';
                            }
                        case _:
                            Context.error("elixir.Syntax.map parameter must be an array literal.", args[0].pos);
                            "";
                    }
                }
                
            case "pipe":
                // elixir.Syntax.pipe(initial, op1, op2, ...) → initial |> op1 |> op2 |> ...
                if (args.length < 2) {
                    Context.error("elixir.Syntax.pipe requires at least two arguments (initial value and one operation).", Context.currentPos());
                    "";
                } else {
                    var initial = compileExpression(args[0]);
                    var operations = [];
                    for (i in 1...args.length) {
                        operations.push(compileExpression(args[i]));
                    }
                    '${initial} |> ${operations.join(" |> ")}';
                }
                
            case "match":
                // elixir.Syntax.match(value, patterns) → case value do patterns end
                if (args.length != 2) {
                    Context.error("elixir.Syntax.match requires exactly two arguments (value and patterns).", Context.currentPos());
                    "";
                } else {
                    var value = compileExpression(args[0]);
                    var patterns = switch (args[1].expr) {
                        case TConst(TString(s)): s;
                        case _:
                            Context.error("elixir.Syntax.match patterns must be a constant String.", args[1].pos);
                            "";
                    };
                    'case ${value} do\n  ${patterns.split("\\n").join("\n  ")}\nend';
                }
                
            case _:
                Context.error('Unknown elixir.Syntax method: ${methodName}', Context.currentPos());
                "";
        };
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
        if (expressions.length < 3) return null;
        
        // Pattern: [TVar(temp, nil), TSwitch(...), TLocal(temp)]
        var first = expressions[0];
        var last = expressions[expressions.length - 1];
        
        
        // Check first: temp_var = nil
        var tempVarName: String = null;
        switch (first.expr) {
            case TVar(tvar, expr):
                var varName = getOriginalVarName(tvar);
                if ((varName.startsWith("temp_") || varName.startsWith("temp")) && (expr == null || isNilExpression(expr))) {
                    tempVarName = varName;
                } else {
                    return null;
                }
            case _:
                return null;
        }
        
        // Check last: return temp_var (can be TLocal or TReturn(TLocal))
        var lastVarName: String = null;
        switch (last.expr) {
            case TLocal(v):
                lastVarName = getOriginalVarName(v);
            case TReturn(expr):
                switch (expr.expr) {
                    case TLocal(v):
                        lastVarName = getOriginalVarName(v);
                    case _:
                }
            case _:
        }
        
        if (lastVarName == tempVarName) {
            // Check if there's a TSwitch or TIf in between (for ternary operators)
            for (i in 1...expressions.length - 1) {
                switch (expressions[i].expr) {
                    case TSwitch(_, _, _):
                        return tempVarName;
                    case TIf(_, _, _):
                        return tempVarName;
                    case _:
                }
            }
        }
        
        return null;
    }
    
    /**
     * Optimize temp variable pattern to idiomatic case expression
     */
    private function optimizeTempVariablePattern(tempVarName: String, expressions: Array<TypedExpr>): String {
        // Find the switch expression or if expression (for ternary operators)
        for (i in 1...expressions.length - 1) {
            switch (expressions[i].expr) {
                case TSwitch(switchExpr, cases, defaultExpr):
                    // Transform the switch to return values directly instead of assignments
                    var originalCaseArmContext = isCompilingCaseArm;
                    isCompilingCaseArm = true;
                    
                    // Compile the switch expression with case arm context
                    var result = compileSwitchExpression(switchExpr, cases, defaultExpr);
                    
                    // Restore original context
                    isCompilingCaseArm = originalCaseArmContext;
                    
                    return result;
                case TIf(condition, thenExpr, elseExpr):
                    // Handle TIf expressions that assign temp variables
                    // Pattern: if (cond), do: temp_var = val1, else: temp_var = val2
                    // Fix: temp_var = if (cond), do: val1, else: val2
                    
                    var conditionCompiled = compileExpression(condition);
                    
                    // Extract actual values from temp variable assignments
                    var thenValue = extractValueFromTempAssignment(thenExpr, tempVarName);
                    var elseValue = extractValueFromTempAssignment(elseExpr, tempVarName);
                    
                    if (thenValue != null && elseValue != null) {
                        // Generate direct ternary expression without temp variables
                        return 'if (${conditionCompiled}), do: ${thenValue}, else: ${elseValue}';
                    } else {
                        // If we can't optimize, ensure proper variable scoping
                        // Declare temp variable before if expression 
                        var originalCaseArmContext = isCompilingCaseArm;
                        isCompilingCaseArm = true;
                        
                        var compiledIf = compileExpression(expressions[i]);
                        
                        // Ensure temp variable is declared properly
                        var result = '${tempVarName} = nil\n${compiledIf}';
                        
                        isCompilingCaseArm = originalCaseArmContext;
                        return result;
                    }
                case _:
            }
        }
        
        // Fallback: compile normally if pattern detection was wrong
        var compiledStatements = [];
        for (expr in expressions) {
            var compiled = compileExpression(expr);
            if (compiled != null && compiled.length > 0) {
                compiledStatements.push(compiled);
            }
        }
        
        var result = compiledStatements.join("\n");
        
        // Post-process to fix temp variable scope issues
        // Pattern: if (cond), do: temp_var = val1, else: temp_var = val2\nvar = temp_var
        // Fix: var = if (cond), do: val1, else: val2
        if (tempVarName != null) {
            result = fixTempVariableScoping(result, tempVarName);
        }
        
        return result;
    }
    
    /**
     * Fix temp variable scoping issues in compiled Elixir code
     * Transforms: if (cond), do: temp_var = val1, else: temp_var = val2\nvar = temp_var
     * Into: var = if (cond), do: val1, else: val2
     */
    private function fixTempVariableScoping(code: String, tempVarName: String): String {
        // Fix the specific JsonPrinter pattern where temp variables are assigned in if expressions
        // Pattern: if (cond), do: temp_var = val1, else: temp_var = val2
        // Next line: var = temp_var  
        // Fix: var = if (cond), do: val1, else: val2
        
        var result = code;
        
        // More flexible regex that handles various whitespace patterns
        // Look for: if (...), do: temp_var = ..., else: temp_var = ...
        // Followed by: variable = temp_var
        var problematicPattern = new EReg(
            'if \\(([^)]+)\\), do: ' + tempVarName + ' = ([^,]+), else: ' + tempVarName + ' = ([^\\n]+)\\s*\\n\\s*([a-zA-Z_][a-zA-Z0-9_]*) = ' + tempVarName,
            'g'
        );
        
        // Apply the transformation
        while (problematicPattern.match(result)) {
            var condition = problematicPattern.matched(1);
            var thenValue = problematicPattern.matched(2);
            var elseValue = problematicPattern.matched(3);
            var targetVar = problematicPattern.matched(4);
            
            var replacement = '${targetVar} = if (${condition}), do: ${thenValue}, else: ${elseValue}';
            result = problematicPattern.replace(result, replacement);
        }
        
        return result;
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
        if (elseBranch == null) return null;
        
        // Check if both branches are assignments to the same variable
        var ifAssignment = getAssignmentVariable(ifBranch);
        var elseAssignment = getAssignmentVariable(elseBranch);
        
        if (ifAssignment != null && elseAssignment != null && ifAssignment == elseAssignment) {
            // Check if it's a temp variable (starts with temp_)
            if (ifAssignment.indexOf("temp_") == 0 || ifAssignment.indexOf("temp") == 0) {
                // Convert to snake_case for consistent naming
                var snakeCaseVarName = NamingHelper.toSnakeCase(ifAssignment);
                return {varName: snakeCaseVarName};
            }
        }
        
        return null;
    }
    
    /**
     * Extract the variable name from an assignment expression
     */
    private function getAssignmentVariable(expr: TypedExpr): Null<String> {
        return switch (expr.expr) {
            case TBinop(OpAssign, lhs, rhs):
                switch (lhs.expr) {
                    case TLocal(v):
                        getOriginalVarName(v);
                    case _:
                        null;
                }
            case _:
                null;
        };
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
        for (i in 0...expressions.length - 1) {
            var currentExpr = expressions[i];
            var nextExpr = expressions[i + 1];
            
            // Check if current expression is TIf with temp variable assignments
            switch (currentExpr.expr) {
                case TIf(_, ifBranch, elseBranch):
                    var tempVarPattern = detectTempVariableAssignmentPattern(ifBranch, elseBranch);
                    if (tempVarPattern != null) {
                        // Check if next expression uses this temp variable
                        switch (nextExpr.expr) {
                            case TBinop(OpAssign, lhs, rhs):
                                var targetVarName = getAssignmentVariable(nextExpr);
                                // Ensure target variable is also in snake_case
                                var targetSnakeCaseName = targetVarName != null ? NamingHelper.toSnakeCase(targetVarName) : null;
                                switch (rhs.expr) {
                                    case TLocal(v):
                                        var rhsVarName = getOriginalVarName(v);
                                        var rhsSnakeCaseName = NamingHelper.toSnakeCase(rhsVarName);
                                        if (rhsSnakeCaseName == tempVarPattern.varName) {
                                            return {
                                                ifIndex: i,
                                                assignIndex: i + 1,
                                                tempVar: tempVarPattern.varName,
                                                targetVar: targetSnakeCaseName
                                            };
                                        }
                                    case _:
                                }
                            case _:
                        }
                    }
                case _:
            }
        }
        
        return null;
    }
    
    /**
     * Optimize temp variable assignment sequence
     */
    private function optimizeTempVariableAssignmentSequence(sequence: {ifIndex: Int, assignIndex: Int, tempVar: String, targetVar: String}, expressions: Array<TypedExpr>): String {
        var ifExpr = expressions[sequence.ifIndex];
        
        // Extract the TIf components
        switch (ifExpr.expr) {
            case TIf(econd, eif, eelse):
                var cond = compileExpression(econd);
                var thenValue = extractAssignmentValue(eif);
                var elseValue = eelse != null ? extractAssignmentValue(eelse) : "nil";
                
                // Generate optimized assignment: target_var = if (cond), do: val1, else: val2
                var optimizedAssignment = '${sequence.targetVar} = if ${cond}, do: ${thenValue}, else: ${elseValue}';
                
                // Compile remaining expressions (skip the TIf and the assignment)
                var remainingExprs = [];
                for (i in 0...expressions.length) {
                    if (i != sequence.ifIndex && i != sequence.assignIndex) {
                        remainingExprs.push(compileExpression(expressions[i]));
                    }
                }
                
                // Combine optimized assignment with remaining expressions
                var allStatements = [optimizedAssignment];
                allStatements = allStatements.concat(remainingExprs);
                
                return allStatements.join("\n");
            case _:
        }
        
        // Fallback - compile normally
        return expressions.map(e -> compileExpression(e)).join("\n");
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
    private function isTypeSafeChildSpecCall(obj: TypedExpr, fieldName: String): Bool {
        // Check if the object is a reference to TypeSafeChildSpec enum
        switch (obj.expr) {
            case TTypeExpr(moduleType):
                switch (moduleType) {
                    case TEnumDecl(enumRef):
                        var enumType = enumRef.get();
                        return enumType.name == "TypeSafeChildSpec" && 
                               enumType.pack.join(".") == "elixir.otp";
                    case _:
                        return false;
                }
            case _:
                return false;
        }
    }
    
    /**
     * Compile TypeSafeChildSpec enum constructor calls directly to ChildSpec format
     */
    private function compileTypeSafeChildSpecCall(fieldName: String, args: Array<TypedExpr>): String {
        var appName = AnnotationSystem.getEffectiveAppName(currentClassType);
        
        return switch (fieldName) {
            case "PubSub":
                if (args.length == 1) {
                    var nameArg = compileExpression(args[0]);
                    // Handle different formats of name argument
                    var cleanName = if (nameArg.indexOf("<>") >= 0) {
                        // For concatenations like 'app_name <> ".PubSub"', keep as-is (already has proper quotes)
                        nameArg;
                    } else {
                        // For simple strings like '"TodoApp.PubSub"', remove quotes for atom format
                        nameArg.split('"').join('');
                    };
                    // Generate modern tuple format for Phoenix.PubSub with atom name
                    '{Phoenix.PubSub, name: ${cleanName}}';
                } else {
                    // Default name based on app - generate as atom
                    '{Phoenix.PubSub, name: ${appName}.PubSub}';
                }
                
            case "Repo":
                // Generate simple module reference
                '${appName}.Repo';
                
            case "Endpoint":
                // Generate simple module reference  
                '${appName}Web.Endpoint';
                
            case "Telemetry":
                // Generate simple module reference
                '${appName}Web.Telemetry';
                
            case _:
                // Fallback to regular enum compilation for unknown constructors
                if (args.length == 0) {
                    ':${NamingHelper.toSnakeCase(fieldName)}';
                } else {
                    var argList = args.map(function(arg) return compileExpression(arg)).join(", ");
                    '{:${NamingHelper.toSnakeCase(fieldName)}, ${argList}}';
                }
        };
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
    
}

#end