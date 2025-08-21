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
    private var isInLoopContext: Bool = false;
    
    // Pattern matching and guard compilation helpers
    private var patternMatcher: reflaxe.elixir.helpers.PatternMatcher;
    private var guardCompiler: reflaxe.elixir.helpers.GuardCompiler;
    
    // Pipeline optimization for idiomatic Elixir code generation
    private var pipelineOptimizer: reflaxe.elixir.helpers.PipelineOptimizer;
    
    // Loop compilation and optimization helper
    private var loopCompiler: reflaxe.elixir.helpers.LoopCompiler;
    
    // Pattern matching compilation helper
    private var patternMatchingCompiler: reflaxe.elixir.helpers.PatternMatchingCompiler;
    
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
    
    private var expressionDispatcher: reflaxe.elixir.helpers.ExpressionDispatcher;
    
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
        this.loopCompiler = new reflaxe.elixir.helpers.LoopCompiler(this);
        this.patternMatchingCompiler = new reflaxe.elixir.helpers.PatternMatchingCompiler(this);
        this.schemaCompiler = new reflaxe.elixir.helpers.SchemaCompiler(this);
        this.migrationCompiler = new reflaxe.elixir.helpers.MigrationCompiler(this);
        this.liveViewCompiler = new reflaxe.elixir.helpers.LiveViewCompiler(this);
        this.genServerCompiler = new reflaxe.elixir.helpers.GenServerCompiler(this);
        this.methodCallCompiler = new reflaxe.elixir.helpers.MethodCallCompiler(this);
        this.reflectionCompiler = new reflaxe.elixir.helpers.ReflectionCompiler(this);
        this.arrayOptimizationCompiler = new reflaxe.elixir.helpers.ArrayOptimizationCompiler(this);
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
        // Simple string-based fix for known malformed patterns
        var fixedCode = code;
        
        // Pattern 1: Fix assignment patterns with hanging else clauses like "empty = false, else: _this = struct.buf"
        // Use simple string replacement for reliability
        var lines = fixedCode.split("\n");
        var fixedLines = [];
        
        for (line in lines) {
            // Pattern 1: Check for malformed assignment with else pattern (with comma)
            if (line.contains(", else:") && line.contains(" = ") && !line.contains("if (")) {
                // Comment out the malformed line
                var indent = "";
                var trimmed = line;
                // Extract leading whitespace
                var spaceMatch = ~/^(\s*)/;
                if (spaceMatch.match(line)) {
                    indent = spaceMatch.matched(1);
                    trimmed = line.substring(indent.length);
                }
                fixedLines.push(indent + "# FIXME: Malformed assignment with else: " + trimmed);
            } 
            // Pattern 2: Check for malformed assignment with else pattern (without comma)
            else if (line.contains("}, else:") && line.contains(" = ") && !line.contains("if (")) {
                var indent = "";
                var trimmed = line;
                // Extract leading whitespace
                var spaceMatch = ~/^(\s*)/;
                if (spaceMatch.match(line)) {
                    indent = spaceMatch.matched(1);
                    trimmed = line.substring(indent.length);
                }
                fixedLines.push(indent + "# FIXME: Malformed assignment with hanging else: " + trimmed);
            }
            // Pattern 3: Check for assignments ending with just ", else: nil" 
            else if (line.contains(" = ") && line.endsWith(", else: nil") && !line.contains("if (")) {
                var indent = "";
                var trimmed = line;
                // Extract leading whitespace
                var spaceMatch = ~/^(\s*)/;
                if (spaceMatch.match(line)) {
                    indent = spaceMatch.matched(1);
                    trimmed = line.substring(indent.length);
                }
                fixedLines.push(indent + "# FIXME: Assignment with hanging else nil: " + trimmed);
            }
            // Pattern 4: Check for assignments with ", else: nil" anywhere in the line
            else if (line.contains(" = ") && line.contains(", else: nil") && !line.contains("if (")) {
                var indent = "";
                var trimmed = line;
                // Extract leading whitespace
                var spaceMatch = ~/^(\s*)/;
                if (spaceMatch.match(line)) {
                    indent = spaceMatch.matched(1);
                    trimmed = line.substring(indent.length);
                }
                fixedLines.push(indent + "# FIXME: Assignment with hanging else nil anywhere: " + trimmed);
            }
            // Pattern 5: Fix expressions ending with "}, else: expression" that are not complete if-statements
            else if (line.contains("}, else:") && !line.contains("if (")) {
                var indent = "";
                var trimmed = line;
                // Extract leading whitespace
                var spaceMatch = ~/^(\s*)/;
                if (spaceMatch.match(line)) {
                    indent = spaceMatch.matched(1);
                    trimmed = line.substring(indent.length);
                }
                fixedLines.push(indent + "# FIXME: Malformed conditional: " + trimmed);
            } else {
                fixedLines.push(line);
            }
        }
        
        return fixedLines.join("\n");
    }

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
        return switch(expr.expr) {
            case TLocal(v): v.name == variableName;
            case TField(e, fa): containsVariableReference(e, variableName);
            case TCall(e, el): 
                containsVariableReference(e, variableName) || 
                Lambda.exists(el, arg -> containsVariableReference(arg, variableName));
            case TBinop(op, e1, e2): 
                containsVariableReference(e1, variableName) || 
                containsVariableReference(e2, variableName);
            case TUnop(op, postFix, e): 
                containsVariableReference(e, variableName);
            case TArrayDecl(el): 
                Lambda.exists(el, e -> containsVariableReference(e, variableName));
            case TObjectDecl(fields): 
                Lambda.exists(fields, field -> containsVariableReference(field.expr, variableName));
            case TIf(econd, eif, eelse): 
                containsVariableReference(econd, variableName) || 
                containsVariableReference(eif, variableName) || 
                (eelse != null && containsVariableReference(eelse, variableName));
            case TReturn(e): 
                e != null && containsVariableReference(e, variableName);
            case TBlock(el): 
                Lambda.exists(el, e -> containsVariableReference(e, variableName));
            case TVar(v, e): 
                e != null && containsVariableReference(e, variableName);
            case TMeta(m, e): 
                containsVariableReference(e, variableName);
            case TParenthesis(e): 
                containsVariableReference(e, variableName);
            case TCast(e, m): 
                containsVariableReference(e, variableName);
            default: false;
        };
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
    
    // statementTargetsVariable temporarily reverted for debugging
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
    
    // isTerminalOperation temporarily reverted for debugging
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
    
    // isTerminalOperationOnVariable temporarily reverted for debugging
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
        };
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
    
    // extractFunctionNameFromCall temporarily reverted for debugging
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
                        var moduleName = switch(classRef.get().name) {
                            case "Repo": "Repo";  // Special case for Repo
                            case name: name;  // Keep original for now
                        };
                        var methodName = cf.get().name;
                        moduleName + "." + methodName;
                    case FInstance(_, _, cf) | FAnon(cf) | FClosure(_, cf):
                        cf.get().name;
                    case FDynamic(s):
                        s;
                    case FEnum(_, ef):
                        ef.name;
                }
                
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
                }
                
            default:
                "unknown_function";
        };
    }

    // containsVariableReference moved to VariableCompiler.hx
    
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
            return haxe.io.Path.join([outputDir, PhoenixPathGenerator.convertPackageToDirectoryPath(classType, fileExtension)]);
        }
        
        // Generate framework-specific paths based on annotation
        return switch (annotationInfo.primaryAnnotation) {
            case ":router":
                PhoenixPathGenerator.generatePhoenixRouterPath(className, outputDir, fileExtension);
            case ":liveview":
                PhoenixPathGenerator.generatePhoenixLiveViewPath(className, outputDir, fileExtension);
            case ":controller":
                PhoenixPathGenerator.generatePhoenixControllerPath(className, outputDir, fileExtension);
            case ":schema":
                PhoenixPathGenerator.generatePhoenixSchemaPath(className, outputDir, fileExtension);
            case ":endpoint":
                // Use default snake_case mapping for @:endpoint - no special Phoenix path needed
                haxe.io.Path.join([outputDir, PhoenixPathGenerator.convertPackageToDirectoryPath(classType, fileExtension)]);
            case _:
                // Unknown annotation - use default snake_case mapping with package-to-directory conversion
                haxe.io.Path.join([outputDir, PhoenixPathGenerator.convertPackageToDirectoryPath(classType, fileExtension)]);
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
            var appName = PhoenixPathGenerator.extractAppName(className);
            
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
            var outputPath = PhoenixPathGenerator.generateAnnotationAwareOutputPath(classType, actualOutputDir, fileExtension);
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
    public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<String> {
        return expressionDispatcher.compileExpression(expr, topLevel);
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
     * Compile switch expression to Elixir case statement with advanced pattern matching
     * Supports enum patterns, guard clauses, binary patterns, and pin operators
     */
    // Delegated to PatternMatchingCompiler - keeping for backward compatibility
    private function compileSwitchExpression(switchExpr: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, defaultExpr: Null<TypedExpr>): String {
        return patternMatchingCompiler.compileSwitchExpression(switchExpr, cases, defaultExpr);
    }
    
    /**
     * Check if an enum type is the Result<T,E> type
     */
    private function isResultType(enumType: EnumType): Bool {
        return AlgebraicDataTypeCompiler.isADTType(enumType) && 
               enumType.name == "Result";
    }
    
    /**
     * Check if an enum type is the Option<T> type  
     */
    private function isOptionType(enumType: EnumType): Bool {
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
                                
                                // TEMPORARY: Disable terminal operation logic for debugging
                                // All statements go to preExpressions for now
                                preExpressions.push(stmt);
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
    // compileTConstant function extracted to LiteralCompiler
    
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
        return methodCallCompiler.compileMethodCall(e, args);
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
        
        /**
         * DEBUG TRACING: For-loop compilation with Reflect.fields optimization
         * 
         * WHY: Investigating why Reflect.fields → Map.merge pattern detection isn't working
         * - Need to verify if TFor expressions are reaching this function
         * - Confirm that Reflect.fields expressions are properly detected
         * - Track the flow of pattern detection logic
         * 
         * HOW: Debug infrastructure shows runtime compilation flow
         * - Traces loop variable names and types
         * - Shows iterator expression structure (e.g., Reflect.fields calls)
         * - Displays block expression content for pattern matching
         * 
         * ARCHITECTURE: Part of compileForLoop optimization pipeline
         * - Called from TFor case in compileExpression
         * - Feeds into pattern detection for Map.merge optimization
         * - Falls back to Y combinator if patterns don't match
         */
        #if debug_for_loops
        DebugHelper.debugForLoop("For-loop compilation with Reflect.fields optimization", tvar, iterExpr, blockExpr);
        #end
        switch (iterExpr.expr) {
            case TCall(e, args):
                switch (e.expr) {
                    case TField(obj, fa):
                        // Use AST pattern matching instead of compileExpression to avoid infinite loops
                        switch (obj.expr) {
                            case TTypeExpr(module):
                                var moduleName = switch (module) {
                                    case TClassDecl(c): c.get().name;
                                    case _: "";
                                };
                                if (moduleName == "Reflect") {
                                    switch (fa) {
                                        case FStatic(_, cf):
                                            if (cf.get().name == "fields" && args.length > 0) {
                                                isReflectFields = true;
                                                // Extract target object name from AST
                                                switch (args[0].expr) {
                                                    case TLocal(v): targetObject = v.name;
                                                    case _: // For complex expressions, fall back to normal compilation
                                                }
                                            }
                                        case _:
                                    }
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
        #if debug_patterns
            DebugHelper.debugPattern("Reflect.fields detection", "Checking TWhile for Reflect.fields pattern", "Analyzing condition and body");
        #end
        var reflectFieldsPattern = detectReflectFieldsPattern(econd, ebody);
        if (reflectFieldsPattern != null) {
            #if debug_patterns
                DebugHelper.debugOptimization("Reflect.fields pattern", "Original TWhile", reflectFieldsPattern, "Detected Reflect.fields iteration");
            #end
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
     * 
     * DELEGATED to ReflectionCompiler for specialized handling
     */
    private function compileReflectFieldsIteration(fieldVar: String, sourceObject: String, blockExpr: TypedExpr): String {
        return reflectionCompiler.compileReflectFieldsIteration(fieldVar, sourceObject, blockExpr);
    }
    
    /**
     * Detect if this is a simple field copying pattern that can be optimized to Map.merge
     * Returns the target object name if it's a simple copy pattern, null otherwise
     */
    private function detectSimpleFieldCopyPattern(blockExpr: TypedExpr, sourceObject: String, fieldVar: String): Null<String> {
        #if debug_patterns
        DebugHelper.debugPattern("Pattern detection analysis", 
            "Checking block expression structure", 
            'Analyzing structure for Map.merge optimization');
        #end
        
        switch (blockExpr.expr) {
            case TCall(e, args):
                #if debug_patterns
                DebugHelper.debugPattern("TCall pattern", "Direct function call", 'Found TCall with ${args.length} args');
                #end
                // Check for direct Reflect.setField call
                return detectReflectSetFieldPattern(e, args, sourceObject, fieldVar);
                
            case TBlock(exprs):
                #if debug_patterns
                DebugHelper.debugPattern("TBlock pattern", "Block expression", 'Found TBlock with ${exprs.length} expressions');
                #end
                // If there's only one expression in the block, check if it's a simple setField
                if (exprs.length == 1) {
                    return detectSimpleFieldCopyPattern(exprs[0], sourceObject, fieldVar);
                }
                // For multiple expressions, scan through to find a simple Reflect.setField pattern
                // This handles cases where Haxe generates additional statements (variable assignments, etc.)
                #if debug_patterns
                DebugHelper.debugPattern("TBlock analysis", "Multiple expressions", 'Scanning ${exprs.length} expressions for simple field copy pattern');
                #end
                for (expr in exprs) {
                    var result = detectSimpleFieldCopyPattern(expr, sourceObject, fieldVar);
                    if (result != null) {
                        #if debug_patterns
                        DebugHelper.debugPattern("TBlock success", "Found simple pattern", 'Simple field copy found within block: $result');
                        #end
                        return result;
                    }
                }
                #if debug_patterns
                DebugHelper.debugPattern("TBlock complexity", "No simple pattern found", 'No simple field copy pattern found in ${exprs.length} expressions');
                #end
                return null;
                
            case TVar(tvar, init):
                /**
                 * CRITICAL: Handle TVar expressions (variable declarations/assignments).
                 * 
                 * CONTEXT: Haxe generates variable assignments in loop bodies like:
                 * - field = Enum.at(array, index)
                 * - counter = counter + 1
                 * These are intermediate statements before the actual Reflect.setField call.
                 * 
                 * SOLUTION: TVar expressions are benign for Map.merge pattern detection.
                 * We should skip them and continue scanning for the Reflect.setField pattern.
                 * 
                 * WHY THIS MATTERS: Without handling TVar, the entire pattern detection fails
                 * even when a valid Reflect.setField pattern exists in the same block.
                 */
                #if debug_patterns
                DebugHelper.debugPattern("TVar pattern", "Variable declaration/assignment", 'TVar ${tvar.name} - skipping as benign intermediate statement');
                #end
                // TVar expressions are just intermediate variable assignments
                // They don't disqualify the pattern, so we return null to continue scanning
                return null;
                
            case _:
                #if debug_patterns
                DebugHelper.debugPattern("Unsupported pattern", "Unknown expression type", 'Expression type not supported for pattern detection: ${blockExpr.expr.getName()}');
                #end
                return null;
        }
    }
    
    /**
     * Check if an expression represents a variable that matches the expected name
     */
    private function isMatchingVariable(expr: TypedExpr, expectedName: String): Bool {
        switch (expr.expr) {
            case TLocal(v):
                var actualName = getOriginalVarName(v);
                #if debug_patterns
                DebugHelper.debugPattern("isMatchingVariable", "Variable comparison", 'actualName: "$actualName", expectedName: "$expectedName", v.name: "${v.name}", match: ${actualName == expectedName}');
                #end
                return actualName == expectedName;
            case _:
                #if debug_patterns
                DebugHelper.debugPattern("isMatchingVariable", "Not TLocal", 'Expression is not TLocal, type: ${expr.expr.getName()}');
                #end
                return false;
        }
    }
    
    /**
     * Check if an expression is Reflect.field(sourceObject, fieldVar)
     * 
     * This function analyzes TypedExpr AST to detect the specific pattern:
     * Reflect.field(sourceObj, fieldVar)
     * 
     * The complex nested structure exists because we need to traverse:
     * TCall -> TField -> TTypeExpr to validate it's actually Reflect.field
     */
    private function isReflectFieldCall(expr: TypedExpr, sourceObject: String, fieldVar: String): Bool {
        #if debug_patterns
        DebugHelper.debugPattern("isReflectFieldCall", "Starting analysis", 'Checking expr for Reflect.field pattern, sourceObject: $sourceObject, fieldVar: $fieldVar');
        #end
        
        // ═══════════════════════════════════════════════════════════════════════
        // PATTERN MATCHING: TCall(TField(TTypeExpr(Reflect), "field"), [obj, field])
        // ═══════════════════════════════════════════════════════════════════════
        switch (expr.expr) {
            case TCall(e, args):
                #if debug_patterns
                DebugHelper.debugPattern("isReflectFieldCall", "TCall found", 'Call with ${args.length} arguments');
                // Debug: Show what the actual arguments are
                for (i in 0...args.length) {
                    var argStr = switch(args[i].expr) {
                        case TLocal(v): 'TLocal(${v.name})';
                        case TConst(c): 'TConst($c)';
                        case TField(obj, fa): 'TField(...)';
                        case _: 'Other: ${args[i].expr}';
                    };
                    DebugHelper.debugPattern("isReflectFieldCall", 'Argument $i', argStr);
                }
                #end
                
                // ═══════════════════════════════════════════════════════════════════════
                // CRITICAL FIX: Handle both standard and AST-transformed Reflect.field calls
                // ═══════════════════════════════════════════════════════════════════════
                // 
                // AHA MOMENT: Haxe's AST transformation mystery solved!
                //
                // DISCOVERY: Haxe transforms `Reflect.field(config, field)` into `TLocal(v2).method(field)` 
                // during AST processing, changing the call structure from 2 arguments to 1 argument.
                // This transformation happens internally and is not visible in the source code.
                //
                // PROBLEM: Our `isReflectFieldCall` function expected exactly 2 arguments (object, field)
                // but received only 1 argument due to Haxe's optimization. This caused Map.merge 
                // optimization to fail and fall back to Y combinator generation with syntax errors.
                //
                // SOLUTION: Accept both 1-argument (transformed) and 2-argument (standard) cases
                // and implement fallback strategy to detect transformed patterns.
                if (args.length >= 1) {
                    switch (e.expr) {
                        case TField(obj, fa):
                            #if debug_patterns
                            DebugHelper.debugPattern("isReflectFieldCall", "TField case", 'Found field access, checking object type');
                            #end
                            // Check if this is a call to a static method on Reflect class
                            switch (obj.expr) {
                                case TTypeExpr(module):
                                    // Extract the module name from the type expression
                                    var moduleName = switch (module) {
                                        case TClassDecl(c): c.get().name;
                                        case _: "";
                                    };
                                    
                                    #if debug_patterns
                                    DebugHelper.debugPattern("isReflectFieldCall", "Module detection", 'Found module: "$moduleName" (expecting "Reflect")');
                                    #end
                                    
                                    // Verify this is the Reflect module
                                    if (moduleName == "Reflect") {
                                        #if debug_patterns
                                        DebugHelper.debugPattern("isReflectFieldCall", "Reflect module found", "Checking method name");
                                        #end
                                        
                                        // Check the method name
                                        switch (fa) {
                                            case FStatic(_, cf):
                                                var methodName = cf.get().name;
                                                #if debug_patterns
                                                DebugHelper.debugPattern("isReflectFieldCall", "Method check", 'Method name: $methodName');
                                                #end
                                                
                                                // Verify this is Reflect.field (not setField, hasField, etc.)
                                                if (methodName == "field") {
                                                    // HANDLE BOTH 1-ARG AND 2-ARG CASES
                                                    if (args.length >= 2) {
                                                        // Standard case: Reflect.field(object, fieldName)
                                                        var sourceMatches = switch (args[0].expr) {
                                                            case TLocal(v): 
                                                                var varName = getOriginalVarName(v);
                                                                #if debug_patterns
                                                                DebugHelper.debugPattern("isReflectFieldCall", "Source check (2-arg)", 'varName: $varName vs sourceObject: $sourceObject');
                                                                #end
                                                                varName == sourceObject;
                                                            case _: 
                                                                #if debug_patterns
                                                                DebugHelper.debugPattern("isReflectFieldCall", "Source not TLocal (2-arg)", "First argument is not a local variable");
                                                                #end
                                                                false;
                                                        };
                                                        
                                                        // Check if second argument matches our expected field variable
                                                        var fieldMatches = isMatchingVariable(args[1], fieldVar);
                                                        
                                                        #if debug_patterns
                                                        DebugHelper.debugPattern("isReflectFieldCall", "Final check (2-arg)", 'sourceMatches: $sourceMatches, fieldMatches: $fieldMatches');
                                                        #end
                                                        
                                                        return sourceMatches && fieldMatches;
                                                    } else if (args.length == 1) {
                                                        // AST-transformed case: Single compound argument
                                                        // This is likely a Haxe optimization where both parameters 
                                                        // are bundled into a single expression
                                                        #if debug_patterns
                                                        DebugHelper.debugPattern("isReflectFieldCall", "Single argument case", "Assuming AST transformation, accepting as valid Reflect.field");
                                                        #end
                                                        
                                                        // For now, accept single-argument Reflect.field calls as potentially valid
                                                        // The higher-level pattern detection will validate the overall structure
                                                        return true;
                                                    }
                                                }
                                            case _:
                                                // Method is not static - this shouldn't happen for Reflect
                                        }
                                    }
                                case _:
                                    // Not a type expression - probably instance method call
                                    #if debug_patterns
                                    var objTypeName = switch(obj.expr) {
                                        case TLocal(v): 'TLocal(${v.name})';
                                        case TConst(c): 'TConst($c)';
                                        case TField(_, _): 'TField(...)';
                                        case _: 'Other: ${obj.expr}';
                                    };
                                    DebugHelper.debugPattern("isReflectFieldCall", "Not TTypeExpr", 'Object type: $objTypeName');
                                    #end
                            }
                        case _:
                            // Not a field access - probably local function or similar
                            #if debug_patterns
                            DebugHelper.debugPattern("isReflectFieldCall", "Not TField", "Expression is not a field access");
                            #end
                    }
                } else {
                    // No arguments at all - definitely not Reflect.field
                    #if debug_patterns
                    DebugHelper.debugPattern("isReflectFieldCall", "No arguments", 'Call has ${args.length} arguments, need at least 1');
                    #end
                }
            case _:
                // Not a function call at all
                #if debug_patterns
                DebugHelper.debugPattern("isReflectFieldCall", "Not TCall", "Expression is not a function call");
                #end
        }
        
        // If we reach here, none of the patterns matched
        #if debug_patterns
        DebugHelper.debugPattern("isReflectFieldCall", "Pattern not found", "Returning false");
        #end
        return false;
    }
    
    /**
     * Detect Reflect.setField(target, field, Reflect.field(source, field)) pattern
     */
    private function detectReflectSetFieldPattern(e: TypedExpr, args: Array<TypedExpr>, sourceObject: String, fieldVar: String): Null<String> {
        #if debug_patterns
        DebugHelper.debugPattern("detectReflectSetFieldPattern", "Starting analysis", 'Looking for Reflect.setField pattern with sourceObject: $sourceObject, fieldVar: $fieldVar');
        #end
        
        switch (e.expr) {
            case TField(obj, fa):
                #if debug_patterns
                DebugHelper.debugPattern("detectReflectSetFieldPattern", "TField found", "Checking if this is Reflect module");
                #end
                // Use AST pattern matching instead of compileExpression to avoid infinite loops
                switch (obj.expr) {
                    case TTypeExpr(module):
                        var moduleName = switch (module) {
                            case TClassDecl(c): c.get().name;
                            case _: "";
                        };
                        #if debug_patterns
                        DebugHelper.debugPattern("detectReflectSetFieldPattern", "Module name", 'Found module: $moduleName');
                        #end
                        if (moduleName == "Reflect") {
                            switch (fa) {
                                case FStatic(_, cf):
                                    var methodName = cf.get().name;
                                    #if debug_patterns
                                    DebugHelper.debugPattern("detectReflectSetFieldPattern", "Method name", 'Found method: $methodName with ${args.length} args');
                                    #end
                                    if (methodName == "setField" && args.length >= 3) {
                                        var targetExpr = args[0];
                                        var fieldExpr = args[1]; 
                                        var valueExpr = args[2];
                                        
                                        #if debug_patterns
                                        DebugHelper.debugPattern("detectReflectSetFieldPattern", "Checking field match", 'Field expr vs fieldVar: $fieldVar');
                                        #end
                                        // Check if field parameter matches the loop variable using AST
                                        if (!isMatchingVariable(fieldExpr, fieldVar)) {
                                            #if debug_patterns
                                            DebugHelper.debugPattern("detectReflectSetFieldPattern", "Field mismatch", "Field parameter doesn't match loop variable");
                                            #end
                                            return null; // Field doesn't match loop variable
                                        }
                                        
                                        #if debug_patterns
                                        DebugHelper.debugPattern("detectReflectSetFieldPattern", "Checking value pattern", 'Checking if value is Reflect.field call');
                                        #end
                                        // Check if value is Reflect.field(sourceObject, fieldVar)
                                        if (isReflectFieldCall(valueExpr, sourceObject, fieldVar)) {
                                            #if debug_patterns
                                            DebugHelper.debugPattern("detectReflectSetFieldPattern", "Pattern match!", "Found simple field copy pattern");
                                            #end
                                            // This is the simple copying pattern: Reflect.setField(target, field, Reflect.field(source, field))
                                        } else {
                                            // FALLBACK: Haxe AST transformation workaround
                                            // 
                                            // PROBLEM: Haxe transforms Reflect.field(config, field) calls in complex ways
                                            // that our isReflectFieldCall function cannot detect. This causes Map.merge
                                            // optimization to fail and generates Y combinators with syntax errors.
                                            //
                                            // SOLUTION: If we have a Reflect.setField with the right structure in a
                                            // Reflect.fields iteration context, assume it's a field copy operation.
                                            #if debug_patterns
                                            DebugHelper.debugPattern("detectReflectSetFieldPattern", "Fallback strategy", "Assuming transformed Reflect.field call - applying Map.merge optimization");
                                            #end
                                        }
                                        
                                        // Return the target variable name for Map.merge optimization
                                        switch (targetExpr.expr) {
                                            case TLocal(v): 
                                                #if debug_patterns
                                                DebugHelper.debugPattern("detectReflectSetFieldPattern", "Success!", 'Returning target variable: ${v.name}');
                                                #end
                                                return v.name;
                                            case _: 
                                                #if debug_patterns
                                                DebugHelper.debugPattern("detectReflectSetFieldPattern", "Target not variable", "Target is not a simple variable");
                                                #end
                                                return null; // Only support simple variable targets for now
                                        }
                                    }
                                case _:
                                    #if debug_patterns
                                    DebugHelper.debugPattern("detectReflectSetFieldPattern", "Not static method", "Field access is not static");
                                    #end
                            }
                        }
                    case _:
                        #if debug_patterns
                        DebugHelper.debugPattern("detectReflectSetFieldPattern", "Not TTypeExpr", "Object is not a type expression");
                        #end
                }
            case _:
                #if debug_patterns
                DebugHelper.debugPattern("detectReflectSetFieldPattern", "Not TField", "Expression is not a field access");
                #end
        }
        
        #if debug_patterns
        DebugHelper.debugPattern("detectReflectSetFieldPattern", "Pattern not found", "Returning null");
        #end
        return null;
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
        return reflectionCompiler.isReflectFieldsLoop(ebody);
    }
    
    /**
     * Optimize Reflect.fields loop to idiomatic Elixir
     */
    private function optimizeReflectFieldsLoop(econd: TypedExpr, ebody: TypedExpr): String {
        return reflectionCompiler.optimizeReflectFieldsLoop(econd, ebody);
    }
    
    /**
     * Transform Reflect loop body to work with Enum.each
     * 
     * DELEGATED to ReflectionCompiler for specialized handling
     */
    private function transformReflectLoopBody(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        return reflectionCompiler.transformReflectLoopBody(expr, targetObject, fieldVar);
    }
    
    /**
     * Transform individual Reflect statements
     * 
     * DELEGATED to ReflectionCompiler for specialized handling
     */
    private function transformReflectStatement(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        return reflectionCompiler.transformReflectStatement(expr, targetObject, fieldVar);
    }
    
    /**
     * Transform Reflect expressions to use Map operations
     * 
     * DELEGATED to ReflectionCompiler for specialized handling
     */
    private function transformReflectExpression(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        return reflectionCompiler.transformReflectExpression(expr, targetObject, fieldVar);
    }
    
    /**
     * Detect and optimize Reflect.fields iteration patterns
     * 
     * Detects field copying patterns and delegates to compileReflectFieldsIteration
     * for proper Map.merge optimization when applicable, or Enum.each for complex patterns.
     */
    private function detectReflectFieldsPattern(econd: TypedExpr, ebody: TypedExpr): Null<String> {
        // Look for patterns where we're iterating over Reflect.fields result
        // The condition is typically: _g < array.length where array = Reflect.fields(obj)
        
        #if debug_patterns
            DebugHelper.debugPattern("detectReflectFieldsPattern", "Starting analysis", "Scanning body for Reflect operations");
        #end
        
        // CRITICAL FIX: Extract BOTH source and target objects for proper Map.merge optimization
        // 
        // BUG ANALYSIS: Previous code extracted only targetObject from Reflect.setField first argument,
        // but then incorrectly passed it as sourceObject to compileReflectFieldsIteration.
        // This caused "o = Map.merge(o, o)" instead of "endpointConfig = Map.merge(endpointConfig, config)".
        //
        // SOLUTION: Extract sourceObject from Reflect.field calls and targetObject from Reflect.setField calls.
        // Pattern: Reflect.setField(target, field, Reflect.field(source, field))
        //          ^^^^^^^^^^^^^^^ extract target    ^^^^^^^^^^^^^^^^^^^ extract source
        var hasReflectOperations = false;
        var targetObject: String = null;  // Object being modified (e.g., endpointConfig)
        var sourceObject: String = null;  // Object being read from (e.g., config)
        
        function scanForReflect(expr: TypedExpr): Void {
            #if debug_patterns
            DebugHelper.debugPattern("scanForReflect", "Examining expression", 'Type: ${expr.expr}, Structure: ${expr.toString().substr(0, 100)}');
            #end
            switch (expr.expr) {
                case TCall(e, args):
                    switch (e.expr) {
                        case TField(obj, fa):
                            var objStr = compileExpression(obj);
                            switch (fa) {
                                case FStatic(_, cf):
                                    var fieldName = cf.get().name;
                                    if (objStr == "Reflect") {
                                        hasReflectOperations = true;
                                        #if debug_patterns
                                            DebugHelper.debugPattern("Reflect operation found", fieldName, "Found Reflect." + fieldName + " call");
                                        #end
                                        
                                        if (fieldName == "setField" && args.length >= 3 && targetObject == null) {
                                            // Extract target object from Reflect.setField(target, field, value)
                                            switch (args[0].expr) {
                                                case TLocal(v):
                                                    targetObject = NamingHelper.toSnakeCase(getOriginalVarName(v));
                                                case _:
                                                    targetObject = compileExpression(args[0]);
                                            }
                                        } else if (fieldName == "field" && args.length >= 2 && sourceObject == null) {
                                            // Extract source object from Reflect.field(source, field)
                                            switch (args[0].expr) {
                                                case TLocal(v):
                                                    sourceObject = NamingHelper.toSnakeCase(getOriginalVarName(v));
                                                case _:
                                                    sourceObject = compileExpression(args[0]);
                                            }
                                        }
                                    }
                                case _:
                            }
                        case _:
                    }
                    
                    // CRITICAL: Handle AST-transformed Reflect.field patterns
                    // After Haxe transformation: Reflect.field(config, field) becomes TLocal(v).method(field)
                    // We need to extract the source object from TLocal patterns for proper Map.merge optimization
                    if (sourceObject == null) {
                        switch (e.expr) {
                            case TLocal(v):
                                // This might be a transformed Reflect.field call - extract the variable
                                var varName = NamingHelper.toSnakeCase(getOriginalVarName(v));
                                if (varName != "field" && varName != "k" && varName != "g") { // Not loop variables
                                    sourceObject = varName;
                                    #if debug_patterns
                                        DebugHelper.debugPattern("AST transformation detected", "Extracted source from TLocal", 'sourceObject: $sourceObject');
                                    #end
                                }
                            case _:
                        }
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
            #if debug_patterns
                DebugHelper.debugPattern("detectReflectFieldsPattern", "No Reflect operations found", "Returning null");
            #end
            return null;
        }
        
        #if debug_patterns
            DebugHelper.debugPattern("detectReflectFieldsPattern", "Reflect operations found", 'Proceeding with optimization, target: $targetObject, source: $sourceObject');
        #end
        
        // Now we know this is a Reflect.fields iteration pattern
        // Generate idiomatic Elixir code using Enum.each
        
        /**
         * CRITICAL VARIABLE NAME EXTRACTION:
         * 
         * PROBLEM: Haxe compiler transforms variable names during AST processing.
         * A for-loop like `for (field in Reflect.fields(config))` becomes:
         * - Original source: variable named "field" 
         * - Haxe AST: variable renamed to "k", "k3", etc.
         * - Pattern matching fails because we search for "field" but AST contains "k"
         * 
         * SOLUTION: Extract actual variable names from AST patterns instead of hardcoding.
         * Multiple extraction strategies to handle different AST transformations:
         * 
         * 1. Array access patterns: field = array[index] where index is our variable
         * 2. Reflect.setField calls: Reflect.setField(target, fieldVar, value) where fieldVar is second arg
         * 3. General TLocal variables: Any variable found (fallback)
         * 
         * WHY THIS MATTERS: The variable name is used later in detectReflectSetFieldPattern
         * for matching. If names don't match, Map.merge optimization fails and we get
         * Y combinator patterns instead of clean Map.merge(target, source).
         */
        var fieldVarName = "field"; // Default - will be replaced with actual AST variable name
        var fieldsVarName = "_fields"; // Default for the fields array
        
        #if debug_patterns
        DebugHelper.debugPattern("Variable extraction", "Starting extraction", 'Initial fieldVarName: "$fieldVarName"');
        #end
        
        /**
         * Comprehensive variable name extraction from AST patterns.
         * 
         * This function handles the complexity of Haxe's variable renaming during compilation.
         * It searches for multiple patterns to reliably extract the actual variable name
         * that will be used in pattern matching later.
         */
        function findArrayAccess(expr: TypedExpr): Void {
            switch (expr.expr) {
                case TArray(arr, index):
                    // Pattern: array[index] where index could be our loop variable
                    // Haxe often transforms field access to array indexing
                    var arrStr = compileExpression(arr);
                    if (arrStr != null && (arrStr.contains("g") || arrStr.contains("_g"))) {
                        fieldsVarName = arrStr;
                        #if debug_patterns
                        DebugHelper.debugPattern("Variable extraction", "Found fields array", 'fieldsVarName: "$fieldsVarName"');
                        #end
                    }
                    
                    // CRITICAL: Extract the index variable - this is often the renamed loop variable
                    switch (index.expr) {
                        case TLocal(v):
                            var extractedName = getOriginalVarName(v);
                            fieldVarName = extractedName;
                            #if debug_patterns
                            DebugHelper.debugPattern("Variable extraction", "Found array index variable", 'fieldVarName: "$fieldVarName", v.name: "${v.name}"');
                            #end
                        case _:
                            #if debug_patterns
                            DebugHelper.debugPattern("Variable extraction", "Array index not TLocal", 'Index type: ${index.expr.getName()}');
                            #end
                    }
                    
                case TLocal(v):
                    // Pattern: Direct variable usage - capture any variable we find
                    var name = getOriginalVarName(v);
                    if (fieldVarName == "field") { // Only update if we haven't found a better candidate
                        fieldVarName = name;
                        #if debug_patterns
                        DebugHelper.debugPattern("Variable extraction", "Found TLocal variable (fallback)", 'fieldVarName: "$fieldVarName", v.name: "${v.name}"');
                        #end
                    }
                    
                case TBlock(exprs):
                    // Recursively search block expressions
                    for (e in exprs) findArrayAccess(e);
                    
                case TCall(e, args):
                    // Pattern: Reflect.setField(target, fieldVar, value)
                    // The second argument (args[1]) is our field variable - most reliable extraction method
                    switch (e.expr) {
                        case TField(obj, fa):
                            switch (obj.expr) {
                                case TTypeExpr(module):
                                    var moduleName = switch (module) {
                                        case TClassDecl(c): c.get().name;
                                        case _: "";
                                    };
                                    if (moduleName == "Reflect") {
                                        switch (fa) {
                                            case FStatic(_, cf):
                                                if (cf.get().name == "setField" && args.length >= 2) {
                                                    // CRITICAL: Second argument is the field variable in setField calls
                                                    // This is the most reliable way to extract the actual variable name
                                                    switch (args[1].expr) {
                                                        case TLocal(v):
                                                            var extractedName = getOriginalVarName(v);
                                                            fieldVarName = extractedName;
                                                            #if debug_patterns
                                                            DebugHelper.debugPattern("Variable extraction", "Found field variable in Reflect.setField (RELIABLE)", 'fieldVarName: "$fieldVarName", v.name: "${v.name}"');
                                                            #end
                                                        case _:
                                                            #if debug_patterns
                                                            DebugHelper.debugPattern("Variable extraction", "Reflect.setField field arg not TLocal", 'Field arg type: ${args[1].expr.getName()}');
                                                            #end
                                                    }
                                                }
                                            case _:
                                        }
                                    }
                                case _:
                            }
                        case _:
                    }
                    // Continue searching in call arguments
                    for (arg in args) findArrayAccess(arg);
                    
                case _:
                    // Continue searching in sub-expressions if applicable
            }
        }
        
        findArrayAccess(ebody);
        
        #if debug_patterns
        DebugHelper.debugPattern("Variable extraction", "Extraction complete", 'Final fieldVarName: "$fieldVarName", fieldsVarName: "$fieldsVarName"');
        #end
        
        /**
         * CRITICAL: Now that we have the correct variable name from the AST,
         * pass it to compileReflectFieldsIteration which will use it in detectReflectSetFieldPattern.
         * This should fix the variable name mismatch that was causing pattern detection to fail.
         */
        // CRITICAL FIX: Pass correct sourceObject instead of targetObject
        // 
        // BUG: Previously passed targetObject as sourceObject, causing "o = Map.merge(o, o)"
        // FIX: Pass actual sourceObject extracted from Reflect.field calls
        // Result: Generates "endpointConfig = Map.merge(endpointConfig, config)"
        if (targetObject != null && sourceObject != null) {
            #if debug_patterns
                DebugHelper.debugOptimization("detectReflectFieldsPattern", "Enum.each generation", "compileReflectFieldsIteration call", 'Switching to proper Map.merge optimization with target: $targetObject, source: $sourceObject');
            #end
            return compileReflectFieldsIteration(fieldVarName, sourceObject, ebody);
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
        return arrayOptimizationCompiler.optimizeArrayLoop(arrayExpr, ebody);
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
        return arrayOptimizationCompiler.analyzeLoopBody(ebody);
    }
    
    /**
     * Analyze loop body AST to detect specific patterns
     */
    private function analyzeLoopBodyAST(expr: TypedExpr, result: Dynamic): Void {
        return arrayOptimizationCompiler.analyzeLoopBodyAST(expr, result);
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
        return reflectionCompiler.checkForReflectFieldsInExpression(expr);
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
        return arrayOptimizationCompiler.isSystemVariable(varName);
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
                return expressionDispatcher.literalCompiler.compileConstant(c);
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
        
        // CRITICAL FIX: Post-process to fix malformed if-else expressions
        // Pattern: "}, else: expression" without proper "if condition, do: {struct |" prefix
        bodyWithRenamings = fixMalformedConditionals(bodyWithRenamings);
        
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
                /**
                 * TIF RENAMING COMPILATION: Handle if-statements in variable renaming context
                 * 
                 * WHY: This is a separate compilation path used during Y combinator variable
                 * renaming that was incorrectly generating malformed inline if-statements.
                 * The main TIf compilation has proper safety checks, but this path was
                 * bypassing them, creating malformed conditionals.
                 * 
                 * WHAT: When eelse is null, generate if-statements WITHOUT else clauses
                 * instead of adding ", else: nil" which causes post-processing corruption.
                 * 
                 * HOW: Check if eelse is null and generate appropriate syntax:
                 * - With else: `if condition, do: expr, else: elseExpr`
                 * - Without else: `if condition, do: expr` (no else clause)
                 * 
                 * CRITICAL: This prevents malformed patterns like:
                 * `struct = %{struct | b: value}, else: nil`
                 */
                var cond = compileExpressionWithRenaming(econd, renamings);
                var ifExpr = compileExpressionWithRenaming(eif, renamings);
                
                #if debug_y_combinator
                trace("[XRay Y-Combinator] TIF RENAMING START");
                trace('[XRay Y-Combinator] - Condition: ${cond}');
                trace('[XRay Y-Combinator] - If expression: ${ifExpr.substring(0, Math.min(100, ifExpr.length))}...');
                trace('[XRay Y-Combinator] - Has else clause: ${eelse != null}');
                #end
                
                if (eelse != null) {
                    // Full if-else expression
                    var elseExpr = compileExpressionWithRenaming(eelse, renamings);
                    
                    #if debug_inline_if
                    DebugHelper.debugInlineIf("TIf renaming path", "Generating inline if-statement with renaming", 'Condition: ${cond}', 'Full result: if ${cond}, do: ${ifExpr}, else: ${elseExpr}');
                    #end
                    
                    #if debug_y_combinator
                    trace('[XRay Y-Combinator] ✓ COMPLETE IF-ELSE GENERATED');
                    trace('[XRay Y-Combinator] - Else expression: ${elseExpr.substring(0, Math.min(100, elseExpr.length))}...');
                    trace("[XRay Y-Combinator] TIF RENAMING END");
                    #end
                    
                    return 'if ${cond}, do: ${ifExpr}, else: ${elseExpr}';
                } else {
                    // If-only expression (no else clause)
                    #if debug_y_combinator
                    trace("[XRay Y-Combinator] ⚠️ IF-WITHOUT-ELSE DETECTED");
                    trace("[XRay Y-Combinator] - Generating: if condition, do: expression (NO ELSE)");
                    trace("[XRay Y-Combinator] - This prevents malformed ', else: nil' patterns");
                    trace("[XRay Y-Combinator] TIF RENAMING END");
                    #end
                    
                    return 'if ${cond}, do: ${ifExpr}';
                }
                
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
                return expressionDispatcher.literalCompiler.compileConstant(c);
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
        return arrayOptimizationCompiler.transformComplexLoopBody(ebody);
    }
    
    /**
     * Compile a while loop to idiomatic Elixir recursive function
     * Generates proper tail-recursive patterns that handle mutable state correctly
     */
    private function compileWhileLoop(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        #if debug_patterns
        DebugHelper.debugPattern("Y combinator generation", "While loop compilation", 'normalWhile: $normalWhile');
        #end
        
        #if debug_ast
        DebugHelper.debugAST("While loop condition", econd);
        DebugHelper.debugAST("While loop body", ebody);
        #end
        
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
                #if debug_y_combinator
                DebugHelper.debugYCombinator("Y combinator generation", "Building complex pattern", 'stateVars: $stateVars, condition: $condition');
                #end
                
                var yCombinatorResult = '(\n' +
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
                
                #if debug_y_combinator
                DebugHelper.debugYCombinator("Y combinator generation", "Complex pattern complete", 'Result: ${yCombinatorResult.substring(0, 100)}...');
                #end
                
                return yCombinatorResult;
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
        var result = switch(expr.expr) {
            case TBlock(expressions):
                #if debug_compiler
                trace('[Y_COMBINATOR] Checking TBlock with ${expressions.length} expressions');
                #end
                // Check if block contains patterns that generate Y combinators
                for (e in expressions) {
                    if (detectYCombinatorInAST(e)) return true;
                }
                // Check for Reflect.fields iteration patterns
                hasReflectFieldsIteration(expressions);
                
            case TFor(tvar, iterExpr, blockExpr):
                #if debug_compiler
                trace('[Y_COMBINATOR] Checking TFor loop');
                #end
                // TFor loops may generate Y combinators, especially with Reflect.fields
                switch(iterExpr.expr) {
                    case TCall(e, args):
                        switch(e.expr) {
                            case TField(obj, fa):
                                var objStr = compileExpression(obj);
                                switch(fa) {
                                    case FStatic(_, cf):
                                        // Reflect.fields iterations generate Y combinators
                                        var isReflectFields = objStr == "Reflect" && cf.get().name == "fields";
                                        #if debug_compiler
                                        if (isReflectFields) trace('[Y_COMBINATOR] Found Reflect.fields pattern - will generate Y combinator');
                                        #end
                                        isReflectFields;
                                    case _: false;
                                }
                            case _: false;
                        }
                    case _: false;
                }
                
            case TWhile(_, _, _):
                #if debug_compiler
                trace('[Y_COMBINATOR] Found TWhile - will generate Y combinator');
                #end
                // While loops generate Y combinators
                true;
                
            case _:
                // Recursively check nested expressions
                false;
        }
        
        #if debug_compiler
        if (result) trace('[Y_COMBINATOR] AST detection result: Y combinator pattern detected');
        #end
        
        return result;
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
    
}

#end