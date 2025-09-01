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

import reflaxe.GenericCompiler;
import reflaxe.compiler.TargetCodeInjection;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;  
import reflaxe.data.EnumOptionData;
import reflaxe.output.DataAndFileInfo;
import reflaxe.output.StringOrBytes;
// All helper imports removed - using AST pipeline exclusively
import reflaxe.elixir.ElixirTyper;
import reflaxe.elixir.PhoenixMapper;
import reflaxe.elixir.SourceMapWriter;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.EPattern;

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
    
    // File extension for generated Elixir files
    public var fileExtension: String = ".ex";
    
    // Output directory for generated files (dynamically set by Reflaxe)
    public var outputDirectory: String = "lib/";
    
    // Type mapping system for enhanced enum compilation
    private var typer: reflaxe.elixir.ElixirTyper;
    
    // Context tracking for variable substitution
    public var isInLoopContext: Bool = false;
    
    // NOTE: All helper compilers removed - using AST pipeline exclusively
    
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
     * Constructor - Initialize the compiler with type mapping and pattern matching systems
     */
    public function new() {
        super();
        this.typer = new reflaxe.elixir.ElixirTyper();
        // All helper initializations removed - using AST pipeline exclusively
        
        // Enable source mapping if requested
        this.sourceMapOutputEnabled = Context.defined("source_map_enabled") || Context.defined("source-map") || Context.defined("debug");
        
        // Preprocessors are now configured in CompilerInit.hx to ensure they aren't overridden
        // The configuration was moved because options passed to ReflectCompiler.AddCompiler
        // override anything set in the constructor
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
        if (classType == null) return null;
        
        // Skip standard library classes that shouldn't generate Elixir modules
        if (isStandardLibraryClass(classType.name)) {
            return null;
        }
        
        // Set output file path with snake_case naming
        setUniversalOutputPath(classType.name, classType.pack);
        
        // Store current class context for use in expression compilation
        this.currentClassType = classType;
        
        // Use AST pipeline for class compilation
        var moduleAST = buildClassAST(classType, varFields, funcFields);
        
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
     * Compile expression - required by DirectToStringCompiler (implements abstract method)
     * 
     * WHY: Delegates to ExpressionDispatcher to replace the massive 2,011-line compileElixirExpressionInternal function
     * WHAT: Clean entry point that routes TypedExpr compilation to specialized expression compilers
     * HOW: Uses the dispatcher pattern to maintain clean separation of concerns
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
        // Build AST for the expression
        return reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr);
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
     * Check if a class has special annotations that need framework-specific handling
     */
    function hasSpecialAnnotations(classType: ClassType): Bool {
        return classType.meta.has(":endpoint") ||
               classType.meta.has(":liveview") ||
               classType.meta.has(":schema") ||
               classType.meta.has(":application") ||
               classType.meta.has(":genserver") ||
               classType.meta.has(":router");
    }
    
    /**
     * Build AST for a class (generates Elixir module)
     */
    function buildClassAST(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<reflaxe.elixir.ast.ElixirAST> {
        
        // Skip built-in types that shouldn't generate modules
        if (isBuiltinAbstractType(classType.name) || isStandardLibraryClass(classType.name)) {
            return null;
        }
        
        // Check if this class has special annotations that need ModuleBuilder
        if (hasSpecialAnnotations(classType)) {
            // Use ModuleBuilder for annotation-based modules
            var classFields = classType.fields.get();
            return reflaxe.elixir.ast.builders.ModuleBuilder.buildClassModule(classType, 
                classFields.filter(f -> f.kind.match(FVar(_, _))),
                classFields.filter(f -> f.kind.match(FMethod(_)))
            );
        }
        
        // Get module name - check for @:native annotation first
        var moduleName = classType.name;
        
        // Check if there's a @:native annotation that overrides the module name
        if (classType.meta.has(":native")) {
            var nativeMeta = classType.meta.extract(":native");
            if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                switch(nativeMeta[0].params[0].expr) {
                    case EConst(CString(s, _)):
                        moduleName = s;
                    default:
                        // Keep original name if annotation is malformed
                }
            }
        }
        
        // Skip module generation for invalid Elixir module names (e.g., starting with underscores)
        // Module names in Elixir cannot start with underscores
        if (moduleName.startsWith("_")) {
            return null;
        }
        
        // Build function definitions
        var functions = [];
        for (func in funcFields) {
            if (func.field.expr() == null) continue;
            
            // Build function AST
            // Convert function name to snake_case for idiomatic Elixir
            var funcName = reflaxe.elixir.ast.NameUtils.toSnakeCase(func.field.name);
            
            // Extract the actual function expression to get parameters
            var funcExpr = func.field.expr();
            var args = [];
            var body = null;
            
            // Check if this is a constructor
            var isConstructor = funcName == "new";
            
            // Check if this is an instance method (non-static)
            // Instance methods in Elixir need the instance as the first parameter
            // Constructors don't need this since they create the instance
            if (!func.isStatic && !isConstructor) {
                // Add instance parameter as first argument
                // Use "struct" as the parameter name for regular classes
                // This matches the convention in the generated code
                args.push(EPattern.PVar("struct"));
            }
            
            // Extract additional parameters from the function expression
            switch(funcExpr.expr) {
                case TFunction(tfunc):
                    // Set context flag for ALL class methods to preserve camelCase
                    var previousContext = reflaxe.elixir.ast.ElixirASTBuilder.isInClassMethodContext;
                    reflaxe.elixir.ast.ElixirASTBuilder.isInClassMethodContext = true;
                    
                    // Add the function's actual parameters
                    // AND register them to prevent snake_case conversion in the body
                    for (arg in tfunc.args) {
                        // Convert parameter names to snake_case for Elixir
                        var baseName = reflaxe.elixir.ast.NameUtils.toSnakeCase(arg.v.name);
                        
                        // Check if the parameter is used in the function body
                        // If not, prefix with underscore to follow Elixir conventions
                        // For now, only prefix with underscore if the parameter has the -reflaxe.unused metadata
                        // The isParameterUsedInExpr check is not reliable for all cases yet
                        var elixirParamName = if (arg.v.meta != null && arg.v.meta.has("-reflaxe.unused")) {
                            "_" + baseName;
                        } else {
                            baseName;
                        };
                        
                        args.push(EPattern.PVar(elixirParamName));
                        
                        // Register the mapping from original name to snake_case name
                        // This registration will be used during buildFromTypedExpr
                        var idKey = Std.string(arg.v.id);
                        // Map the parameter ID to its snake_case name
                        reflaxe.elixir.ast.ElixirASTBuilder.tempVarRenameMap.set(idKey, elixirParamName);
                    }
                    
                    // Special handling for constructor body
                    if (isConstructor) {
                        // Constructors need to return a map with instance fields
                        // Extract field assignments from the constructor body
                        var fieldAssignments = [];
                        
                        // Analyze the constructor body to find field assignments
                        switch(tfunc.expr.expr) {
                            case TBlock(exprs):
                                for (expr in exprs) {
                                    switch(expr.expr) {
                                        case TBinop(OpAssign, e1, e2):
                                            // Check if it's a this.field assignment
                                            switch(e1.expr) {
                                                case TField(ethis, fa):
                                                    switch(ethis.expr) {
                                                        case TConst(TThis):
                                                            // This is a this.field assignment
                                                            var fieldName = reflaxe.elixir.ast.ElixirASTBuilder.extractFieldName(fa);
                                                            var value = buildFromTypedExpr(e2);
                                                            fieldAssignments.push({
                                                                key: reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EAtom(fieldName)),
                                                                value: value
                                                            });
                                                        default:
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                }
                            default:
                                // Single expression constructor body
                                switch(tfunc.expr.expr) {
                                    case TBinop(OpAssign, e1, e2):
                                        // Check if it's a this.field assignment
                                        switch(e1.expr) {
                                            case TField(ethis, fa):
                                                switch(ethis.expr) {
                                                    case TConst(TThis):
                                                        var fieldName = reflaxe.elixir.ast.ElixirASTBuilder.extractFieldName(fa);
                                                        var value = buildFromTypedExpr(e2);
                                                        fieldAssignments.push({
                                                            key: reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EAtom(fieldName)),
                                                            value: value
                                                        });
                                                    default:
                                                }
                                            default:
                                        }
                                    default:
                                }
                        }
                        
                        // Create a map with the field assignments
                        body = reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EMap(fieldAssignments));
                    } else {
                        // For regular functions, extract the body directly
                        // For regular functions, we need to handle parameter name mapping
                        // This is especially important for abstract types where parameter names
                        // may have collision-avoidance suffixes
                        
                        // Build a parameter mapping for the function body
                        var paramMapping = new Map<String, String>();
                        for (arg in tfunc.args) {
                            // Map from the original name to the actual parameter name
                            // This handles cases where Haxe adds suffixes like "1" to avoid collisions
                            paramMapping.set(arg.v.name, arg.v.name);
                        }
                        
                        // Special handling for abstract type methods
                        // These often have simple bodies that just return the parameter
                        var needsSpecialHandling = false;
                        
                        // Check if this is likely an abstract type method
                        var className = classType.name;
                        if (className.endsWith("_Impl_") || className.contains("_Impl_")) {
                            // This is an abstract type implementation
                            #if debug_abstract_compilation
                            trace('Abstract method ${funcName} in ${className}, expr: ${tfunc.expr.expr}');
                            #end
                            // Check for simple return patterns
                            switch(tfunc.expr.expr) {
                                case TConst(TThis):
                                    // Returns 'this' - use the first parameter name
                                    if (tfunc.args.length > 0) {
                                        body = reflaxe.elixir.ast.ElixirAST.makeAST(
                                            ElixirASTDef.EVar(tfunc.args[0].v.name)
                                        );
                                        needsSpecialHandling = true;
                                    }
                                case TLocal(v):
                                    // Returns a local variable - check if it's a parameter
                                    for (arg in tfunc.args) {
                                        if (v.name == arg.v.name || v.name == "this") {
                                            body = reflaxe.elixir.ast.ElixirAST.makeAST(
                                                ElixirASTDef.EVar(arg.v.name)
                                            );
                                            needsSpecialHandling = true;
                                            break;
                                        }
                                    }
                                case TBlock(exprs):
                                    // Check if it's a single return statement
                                    if (exprs.length == 1) {
                                        switch(exprs[0].expr) {
                                            case TReturn(retExpr):
                                                // Check what's being returned (if not null)
                                                if (retExpr != null) switch(retExpr.expr) {
                                                    case TLocal(v):
                                                        // Returning a local var - likely the parameter
                                                        // For abstracts, "this" becomes the first parameter
                                                        if (tfunc.args.length > 0 && (v.name == "this" || v.name.startsWith("this"))) {
                                                            body = reflaxe.elixir.ast.ElixirAST.makeAST(
                                                                ElixirASTDef.EVar(tfunc.args[0].v.name)
                                                            );
                                                            needsSpecialHandling = true;
                                                        }
                                                    case TConst(TThis):
                                                        // Direct return of this
                                                        if (tfunc.args.length > 0) {
                                                            body = reflaxe.elixir.ast.ElixirAST.makeAST(
                                                                ElixirASTDef.EVar(tfunc.args[0].v.name)
                                                            );
                                                            needsSpecialHandling = true;
                                                        }
                                                    default:
                                                }
                                            default:
                                        }
                                    }
                                default:
                            }
                        }
                        
                        if (!needsSpecialHandling) {
                            // Re-register parameters RIGHT before building body
                            // Map them to their snake_case names
                            for (arg in tfunc.args) {
                                var idKey = Std.string(arg.v.id);
                                var elixirParamName = reflaxe.elixir.ast.NameUtils.toSnakeCase(arg.v.name);
                                reflaxe.elixir.ast.ElixirASTBuilder.tempVarRenameMap.set(idKey, elixirParamName);
                            }
                            
                            // Set flag to indicate we're in a class method context
                            // This prevents camelCase parameters from being converted to snake_case
                            // This applies to ALL class methods (static and non-static)
                            var previousContext = reflaxe.elixir.ast.ElixirASTBuilder.isInClassMethodContext;
                            reflaxe.elixir.ast.ElixirASTBuilder.isInClassMethodContext = true;
                            
                            body = buildFromTypedExpr(tfunc.expr);
                            
                            // Restore previous context
                            reflaxe.elixir.ast.ElixirASTBuilder.isInClassMethodContext = previousContext;
                        }
                    }
                    // Restore context before handling default case
                    reflaxe.elixir.ast.ElixirASTBuilder.isInClassMethodContext = previousContext;
                default:
                    // Not a function expression, use as-is
                    body = buildFromTypedExpr(funcExpr);
            }
            
            // Use the body we built above
            if (body == null) {
                body = buildFromTypedExpr(funcExpr);
            }
            
            var funcDef = func.field.isPublic 
                ? ElixirASTDef.EDef(funcName, args, null, body)
                : ElixirASTDef.EDefp(funcName, args, null, body);
                
            functions.push(reflaxe.elixir.ast.ElixirAST.makeAST(funcDef));
        }
        
        // Create module AST
        var moduleBody = reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EBlock(functions));
        return reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EDefmodule(moduleName, moduleBody));
    }
    
    /**
     * Helper to build AST from TypedExpr (delegates to builder)
     */
    function buildFromTypedExpr(expr: TypedExpr): reflaxe.elixir.ast.ElixirAST {
        return reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr);
    }
    
    /**
     * Build AST for an enum (generates tagged tuples in Elixir)
     */
    function buildEnumAST(enumType: EnumType, options: Array<EnumOptionData>): Null<reflaxe.elixir.ast.ElixirAST> {
        var NameUtils = reflaxe.elixir.ast.NameUtils;
        
        // Check if this enum has @:elixirIdiomatic metadata
        var isIdiomatic = enumType.meta.has(":elixirIdiomatic");
        
        // In Elixir, enums become modules with functions that return tagged tuples
        var moduleName = enumType.name;
        var functions = [];
        
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
            var atomTag = reflaxe.elixir.ast.ElixirAST.makeAST(ElixirASTDef.EAtom(option.name));
            var tupleElements = [atomTag];
            
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
     * Compile abstract types - generates proper Elixir type aliases and implementation modules
     * Abstract types in Haxe become type aliases in Elixir with implementation modules for operators
     */
    public override function compileAbstractImpl(abstractType: AbstractType): Null<reflaxe.elixir.ast.ElixirAST> {
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
            case "String" | "Array" | "Map" | "Date" | "Math" | "Std": true;
            case "__Int64" | "Int64" | "Int64_Impl_": true; // Haxe Int64 internal types
            case _: false;
        }
    }

    /**
     * Get Elixir type representation from Haxe type
     */
    private function getElixirTypeFromHaxeType(type: Type): String {
        // Basic type mapping - will be handled by AST pipeline
        return "term()";
    }
    
    
    /**
     * Position tracking helper methods for source map generation
     * 
     * WHY: Source maps need systematic position tracking throughout compilation
     * WHAT: Helper methods that abstract source map tracking complexity
     * HOW: Non-invasive tracking that only activates when source mapping is enabled
     */
    
    /**
     * Track the current position in the source Haxe file
     * 
     * This method should be called before generating output for any AST node
     * that has position information. It records the mapping between the current
     * output position and the source position.
     * 
     * Note: This is a no-op when source mapping is disabled, ensuring zero
     * overhead in production builds without source maps.
     * 
     * @param pos The position in the original Haxe source file
     */
    public function trackPosition(pos: Position): Void {
        // Early return for zero overhead when source maps are disabled
        if (!sourceMapOutputEnabled) return;
        
        #if debug_source_mapping_verbose
//         trace('[SourceMapping] trackPosition called with pos: ${pos}');
        #end
        
        if (currentSourceMapWriter != null && pos != null) {
            currentSourceMapWriter.mapPosition(pos);
            #if debug_source_mapping_verbose
//             trace('[SourceMapping] Position tracked successfully');
            #end
        }
    }
    
    /**
     * Track output that has been written to the generated Elixir file
     * 
     * This method should be called after generating any output string to
     * update the current position in the output file. The SourceMapWriter
     * uses this to maintain accurate line and column tracking.
     * 
     * Note: This is a no-op when source mapping is disabled, ensuring zero
     * overhead in production builds without source maps.
     * 
     * @param output The string that was written to the output
     */
    public function trackOutput(output: String): Void {
        // Early return for zero overhead when source maps are disabled
        if (!sourceMapOutputEnabled) return;
        
        if (currentSourceMapWriter != null && output != null) {
            currentSourceMapWriter.stringWritten(output);
        }
    }
    
    /**
     * Combined tracking helper for common pattern: track position then output
     * 
     * Many compilation methods follow the pattern of tracking source position
     * before generating output. This helper combines both operations for
     * convenience and consistency.
     * 
     * Note: Tracking is a no-op when source mapping is disabled, ensuring zero
     * overhead in production builds without source maps.
     * 
     * @param pos The position in the original Haxe source file
     * @param output The string to write to the output
     * @return The output string (for chaining)
     */
    private function trackAndOutput(pos: Position, output: String): String {
        // Only perform tracking when source maps are enabled
        if (sourceMapOutputEnabled) {
            trackPosition(pos);
            trackOutput(output);
        }
        return output;
    }
    
    /**
     * Compile typedef - Returns null to ignore typedefs as BaseCompiler recommends.
     * This prevents generating invalid StdTypes.ex files with @typedoc/@type outside modules.
     * 
     * IMPORTANT: Typedefs are compile-time only type aliases in Haxe and don't generate
     * any runtime code in the target language. They exist purely for type checking
     * during Haxe compilation. This is why this method returns null and doesn't use
     * the AST pipeline - there's nothing to generate.
     * 
     * The AST pipeline (Builder → Transformer → Printer) only processes classes and enums
     * which generate actual runtime code. Typedefs are resolved during compilation and
     * their underlying types are used directly in the generated code.
     * 
     * Example: 
     * typedef StringMap = Map<String, String>; // No .ex file generated
     * The typedef just creates an alias - any usage of StringMap in code will be
     * compiled as if Map<String, String> was used directly.
     */
    public override function compileTypedefImpl(defType: DefType): Null<reflaxe.elixir.ast.ElixirAST> {
        // Typedefs don't generate runtime code in Elixir
        return null;
    }
    
    
    
    
    
    
    
    
    
    /**
     * Check if an enum type is the Result<T,E> type
     */
    public function isResultType(enumType: EnumType): Bool {
        return false && // ADT detection now handled by AST pipeline 
               enumType.name == "Result";
    }
    
    /**
     * Check if an enum type is the Option<T> type  
     */
    public function isOptionType(enumType: EnumType): Bool {
        return false && // ADT detection now handled by AST pipeline 
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
        // COORDINATION: Reset temp variable declarations for each function
        // This ensures variables from one function don't affect another
        
        return ""; // Function compilation now handled by AST pipeline
    }
    
    /**
     * Check if a parameter is used anywhere in an expression
     * Recursively traverses the AST to find references to the parameter
     */
    private static function isParameterUsedInExpr(paramId: Int, expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch(expr.expr) {
            case TLocal(v):
                // Check if this is a reference to our parameter
                if (v.id == paramId) return true;
            case TBlock(exprs):
                for (e in exprs) {
                    if (isParameterUsedInExpr(paramId, e)) return true;
                }
            case TBinop(_, e1, e2):
                return isParameterUsedInExpr(paramId, e1) || isParameterUsedInExpr(paramId, e2);
            case TField(e, _):
                return isParameterUsedInExpr(paramId, e);
            case TCall(e, el):
                if (isParameterUsedInExpr(paramId, e)) return true;
                for (arg in el) {
                    if (isParameterUsedInExpr(paramId, arg)) return true;
                }
            case TIf(econd, ethen, eelse):
                if (isParameterUsedInExpr(paramId, econd)) return true;
                if (isParameterUsedInExpr(paramId, ethen)) return true;
                if (eelse != null && isParameterUsedInExpr(paramId, eelse)) return true;
            case TSwitch(e, cases, edef):
                if (isParameterUsedInExpr(paramId, e)) return true;
                for (c in cases) {
                    if (isParameterUsedInExpr(paramId, c.expr)) return true;
                }
                if (edef != null && isParameterUsedInExpr(paramId, edef)) return true;
            case TReturn(e):
                if (e != null) return isParameterUsedInExpr(paramId, e);
            case TUnop(_, _, e):
                return isParameterUsedInExpr(paramId, e);
            case TFunction(tfunc):
                return isParameterUsedInExpr(paramId, tfunc.expr);
            case TVar(_, e):
                if (e != null) return isParameterUsedInExpr(paramId, e);
            case TFor(v, e1, e2):
                // Don't check the loop variable itself, but check the iterator and body
                return isParameterUsedInExpr(paramId, e1) || isParameterUsedInExpr(paramId, e2);
            case TWhile(econd, e, _):
                return isParameterUsedInExpr(paramId, econd) || isParameterUsedInExpr(paramId, e);
            case TTry(e, catches):
                if (isParameterUsedInExpr(paramId, e)) return true;
                for (c in catches) {
                    if (isParameterUsedInExpr(paramId, c.expr)) return true;
                }
            case TArrayDecl(el):
                for (e in el) {
                    if (isParameterUsedInExpr(paramId, e)) return true;
                }
            case TObjectDecl(fields):
                for (f in fields) {
                    if (isParameterUsedInExpr(paramId, f.expr)) return true;
                }
            case TParenthesis(e):
                return isParameterUsedInExpr(paramId, e);
            case TCast(e, _):
                return isParameterUsedInExpr(paramId, e);
            case TMeta(_, e):
                return isParameterUsedInExpr(paramId, e);
            default:
                // For other cases, assume not used
        }
        return false;
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
            case TField(_, FEnum(_, enumField)): reflaxe.elixir.ast.NameUtils.toSnakeCase(enumField.name);
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
        // Reset array desugaring tracking for new function
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
                var snakeCaseName = reflaxe.elixir.ast.NameUtils.toSnakeCase(originalName);
                currentFunctionParameterMap.set(originalName, snakeCaseName);
                
                // Also handle common abstract type parameter patterns
                if (originalName == "this") {
                    currentFunctionParameterMap.set("this1", snakeCaseName);
                }
            }
        }
    }
    
    
    /**
     * Check if a TLocal variable represents a function being passed as a reference
     * 
     * WHY: We need to distinguish between local variables and function references
     *      to generate proper Elixir syntax (&Module.function/arity vs variable_name)
     * 
     * WHAT: Determines if a TVar is actually a function reference that needs & syntax
     * 
     * HOW: Check if the variable's TYPE is TFun, NOT just if it shares a name with
     *      a static method. Local variables can have the same names as methods!
     * 
     * CRITICAL FIX: A local variable named "changeset" is NOT a reference to
     *               Todo.changeset just because they share a name. Only generate
     *               function reference syntax when the variable TYPE is TFun.
     * 
     * @param v The TVar representing the local variable
     * @param originalName The original name of the variable
     * @return true if this is a function reference, false otherwise
     */
    public function isFunctionReference(v: TVar, originalName: String): Bool {
        // ONLY check the variable's type - don't look for static methods with same name!
        // A local variable "changeset" is NOT a reference to a static method "changeset"
        switch (v.t) {
            case TFun(_, _):
                // This variable's TYPE is a function - it's a function reference
                // trace('[XRay ElixirCompiler] Variable ${originalName} has TFun type - IS a function reference');
                return true;
            case _:
                // NOT a function type - it's just a regular variable
                // Even if there's a static method with the same name, this is still just a variable!
                // trace('[XRay ElixirCompiler] Variable ${originalName} does NOT have TFun type - NOT a function reference');
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
     * Compile expression with aggressive substitution for all likely loop variables
     * Used when normal loop variable detection fails
     */

    /**
     * Simple approach: Always substitute all TLocal variables with the target variable
     * This replaces the complex __AGGRESSIVE__ marker system with a straightforward solution
     */
    private function extractTransformationFromBodyWithAggressiveSubstitution(expr: TypedExpr, targetVar: String): String {
        return ""; // Variable substitution now handled by AST pipeline
    }
    
    /**
     * Compile expression with variable substitution using TVar object comparison
     */


    /**
     * Compile while loop with variable renamings applied (DELEGATED)
     * This handles variable collisions in desugared loop code
     */
    private function compileWhileLoopWithRenamings(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool, renamings: Map<String, String>): String {
        return ""; // While loop compilation now handled by AST pipeline
    }
    
    /**
     * Compile expression with multiple variable renamings applied
     * This is used to handle variable collisions in desugared loop code
     */
    
    

    
    
    
    // NOTE: Loop-related methods previously delegated to WhileLoopCompiler have been removed.
    // All loop compilation is now handled internally by UnifiedLoopCompiler and its components.
    // Methods removed: detectArrayBuildingPattern, compileArrayBuildingLoop, extractArrayTransformation,
    // compileWhileLoopGeneric, extractModifiedVariables, transformLoopBodyMutations
    
    
    
    
    
    
    
    
    
    
    
    
    
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
     * Compile supervisor options object to proper Elixir keyword list format
     * Converts from Haxe objects to Elixir keyword lists as expected by Supervisor.start_link
     */
    public function compileSupervisorOptions(fields: Array<{name: String, expr: TypedExpr}>, classType: Null<ClassType>): String {
        // Delegate to OTPCompiler for specialized supervisor options handling
        return ""; // Supervisor options now handled by AST pipeline
    }
    
    /**
    
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
    
    // DEPRECATED: extractFieldUpdate removed - handled by AST pipeline
    
    // DEPRECATED: Temp variable optimization functions removed
    // These were part of the old string-based compilation approach
    // The AST-based pipeline handles temp variables more elegantly
    
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
     * Extract the variable name from an assignment expression
     */
    private function getAssignmentVariable(expr: TypedExpr): Null<String> {
        return null; // Pattern analysis now handled by AST pipeline
    }
    
    // DEPRECATED: extractAssignmentValue and getTargetVariableFromAssignment removed
    // These string-based compilation functions are replaced by AST pipeline
    
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