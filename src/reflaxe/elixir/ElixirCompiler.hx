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
import reflaxe.elixir.helpers.TemplateCompiler;
import reflaxe.elixir.helpers.SchemaCompiler;
import reflaxe.elixir.helpers.ProtocolCompiler;
import reflaxe.elixir.helpers.BehaviorCompiler;
import reflaxe.elixir.helpers.RouterCompiler;
import reflaxe.elixir.helpers.AnnotationSystem;
import reflaxe.elixir.helpers.EctoQueryAdvancedCompiler;
import reflaxe.elixir.helpers.RepositoryCompiler;
import reflaxe.elixir.helpers.EctoErrorReporter;
import reflaxe.elixir.helpers.TypedefCompiler;
import reflaxe.elixir.helpers.LLMDocsGenerator;
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
    
    // Pattern matching and guard compilation helpers
    private var patternMatcher: reflaxe.elixir.helpers.PatternMatcher;
    private var guardCompiler: reflaxe.elixir.helpers.GuardCompiler;
    
    // Source mapping support for debugging and LLM workflows
    private var currentSourceMapWriter: Null<SourceMapWriter> = null;
    private var sourceMapOutputEnabled: Bool = false;
    
    // Parameter mapping system for abstract type implementation methods
    private var currentFunctionParameterMap: Map<String, String> = new Map();
    private var isCompilingAbstractMethod: Bool = false;
    
    // Current class context for app name resolution and other class-specific operations
    private var currentClassType: Null<ClassType> = null;
    
    /**
     * Constructor - Initialize the compiler with type mapping and pattern matching systems
     */
    public function new() {
        super();
        this.typer = new reflaxe.elixir.ElixirTyper();
        this.patternMatcher = new reflaxe.elixir.helpers.PatternMatcher();
        this.guardCompiler = new reflaxe.elixir.helpers.GuardCompiler();
        
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
            // No framework annotation - use default 1:1 mapping
            return haxe.io.Path.join([outputDir, className + fileExtension]);
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
            case _:
                // Unknown annotation - use default 1:1 mapping
                haxe.io.Path.join([outputDir, className + fileExtension]);
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
        var liveViewName = toSnakeCase(className.replace("Live", ""));
        var phoenixPath = '${appName}_web/live/${liveViewName}_live${fileExtension}';
        return haxe.io.Path.join([outputDir, phoenixPath]);
    }
    
    /**
     * Generate Phoenix controller path: UserController → /lib/app_web/controllers/user_controller.ex
     */
    private function generatePhoenixControllerPath(className: String, outputDir: String): String {
        var appName = extractAppName(className);
        var controllerName = toSnakeCase(className);
        var phoenixPath = '${appName}_web/controllers/${controllerName}${fileExtension}';
        return haxe.io.Path.join([outputDir, phoenixPath]);
    }
    
    /**
     * Generate Phoenix schema path: User → /lib/app/schemas/user.ex
     */
    private function generatePhoenixSchemaPath(className: String, outputDir: String): String {
        var appName = extractAppName(className);
        var schemaName = toSnakeCase(className);
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
        return haxe.macro.Context.definedValue("app_name");
        #end
        
        // For TodoLive, TodoAppRouter, etc., we need to infer the app name
        // Special handling for TodoApp project - this should be configurable
        if (className.indexOf("Todo") == 0) {
            return "todo_app";
        }
        
        // Remove common Phoenix suffixes and convert to snake_case
        var appPart = className.replace("Router", "")
                               .replace("Live", "")
                               .replace("Controller", "")
                               .replace("Schema", "");
        
        // Handle special case where class name is just the suffix (e.g., "Router")
        if (appPart == "") {
            appPart = "app"; // Default fallback
        }
        
        return toSnakeCase(appPart);
    }
    
    /**
     * Convert PascalCase to snake_case for Elixir file naming conventions.
     * Examples: TodoApp → todo_app, UserController → user_controller
     */
    private function toSnakeCase(name: String): String {
        if (name == null || name == "") return "";
        
        var result = "";
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (char >= "A" && char <= "Z" && i > 0) {
                result += "_";
            }
            result += char.toLowerCase();
        }
        
        return result;
    }
    
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
     * Set framework-aware output path using Reflaxe's built-in file placement system.
     * 
     * This method detects framework annotations and uses setOutputFileDir() and setOutputFileName()
     * to place files in Phoenix-expected locations BEFORE compilation occurs.
     */
    private function setFrameworkAwareOutputPath(classType: ClassType): Void {
        var className = classType.name;
        var annotationInfo = reflaxe.elixir.helpers.AnnotationSystem.detectAnnotations(classType);
        
        if (annotationInfo.primaryAnnotation == null) {
            // No framework annotation - use default 1:1 mapping
            return;
        }
        
        // Calculate framework-aware file path components
        var appName = extractAppName(className);
        var fileName: String = "";
        var dirPath: String = "";
        
        switch (annotationInfo.primaryAnnotation) {
            case ":router":
                // TodoAppRouter → router.ex in todo_app_web/
                fileName = "router";
                dirPath = appName + "_web";
                
            case ":liveview":
                // UserLive → user_live.ex in app_web/live/
                var liveViewName = toSnakeCase(className.replace("Live", ""));
                fileName = liveViewName + "_live";
                dirPath = appName + "_web/live";
                
            case ":controller":
                // UserController → user_controller.ex in app_web/controllers/
                var controllerName = toSnakeCase(className);
                fileName = controllerName;
                dirPath = appName + "_web/controllers";
                
            case ":schema":
                // User → user.ex in app/schemas/
                var schemaName = toSnakeCase(className);
                fileName = schemaName;
                dirPath = appName + "/schemas";
                
            default:
                // Other annotations use default behavior
                return;
        }
        
        // Set the file output overrides using Reflaxe's built-in system
        setOutputFileName(fileName);
        setOutputFileDir(dirPath);
    }
    
    /**
     * Required override for GenericCompiler - implements class compilation
     * @param classType The Haxe class type
     * @param varFields Class variables
     * @param funcFields Class functions
     * @return Generated Elixir module string
     */
    public function compileClassImpl(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<String> {
        if (classType == null) return null;
        
        // Skip standard library classes that shouldn't generate Elixir modules
        if (isStandardLibraryClass(classType.name)) {
            #if debug
            trace('Skipping standard library class: ${classType.name}');
            #end
            return null;
        }
        
        // Store current class context for use in expression compilation
        this.currentClassType = classType;
        
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
        
        // Use unified annotation system for detection, validation, and routing
        var annotationResult = reflaxe.elixir.helpers.AnnotationSystem.routeCompilation(classType, varFields, funcFields);
        if (annotationResult != null) {
            // Generate source map for annotated compilation
            if (sourceMapOutputEnabled) {
                finalizeSourceMapWriter();
            }
            return annotationResult;
        }
        
        // Check if this is a LiveView class that should use special compilation
        var annotationInfo = reflaxe.elixir.helpers.AnnotationSystem.detectAnnotations(classType);
        if (annotationInfo.primaryAnnotation == ":liveview") {
            var result = compileLiveViewClass(classType, varFields, funcFields);
            if (sourceMapOutputEnabled) {
                finalizeSourceMapWriter();
            }
            return result;
        }
        
        // Use the enhanced ClassCompiler for proper struct/module generation
        var classCompiler = new reflaxe.elixir.helpers.ClassCompiler(this.typer);
        classCompiler.setCompiler(this);
        
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
        
        // Finalize source mapping for this class
        if (sourceMapOutputEnabled) {
            finalizeSourceMapWriter();
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
        
        // Generate module header using LiveViewCompiler
        var moduleHeader = reflaxe.elixir.LiveViewCompiler.generateModuleHeader(className);
        result.add(moduleHeader);
        
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
        return result.toString();
    }
    
    /**
     * Required override for GenericCompiler - implements enum compilation
     */
    public function compileEnumImpl(enumType: EnumType, options: Array<EnumOptionData>): Null<String> {
        if (enumType == null) return null;
        
        // Use the enhanced EnumCompiler helper for proper type integration
        var enumCompiler = new reflaxe.elixir.helpers.EnumCompiler(this.typer);
        return enumCompiler.compileEnum(enumType, options);
    }
    
    /**
     * Compile expression - required by BaseCompiler (implements abstract method)
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
        if (isBuiltinAbstractType(abstractType.name)) {
            return "";
        }
        
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
        trace('Skipping standalone type alias generation for abstract ${typeName}');
        
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
                
            // Abstract implementation classes (compiler-generated)
            case name if (name.endsWith("_Impl_")):
                true;
                
            // Built-in type classes
            case "Class" | "Enum" | "Type" | "Reflect" | "Std" | "Math":
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
        
        // Comprehensive expression compilation
        return switch (expr.expr) {
            case TConst(constant):
                compileTConstant(constant);
                
            case TLocal(v):
                // Get the original variable name (before Haxe's renaming for shadowing avoidance)
                var originalName = getOriginalVarName(v);
                
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
                            var left = compileExpression(e1);
                            var right = compileExpression(e2);
                            
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
                compileFieldAccess(e, fa);
                
            case TCall(e, el):
                compileMethodCall(e, el);
                
            case TArrayDecl(el):
                "[" + el.map(expr -> compileExpression(expr)).join(", ") + "]";
                
            case TObjectDecl(fields):
                "%{" + fields.map(f -> f.name + ": " + compileExpression(f.expr)).join(", ") + "}";
                
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
                var varName = NamingHelper.toSnakeCase(originalName);
                if (expr != null) {
                    '${varName} = ${compileExpression(expr)}';
                } else {
                    '${varName} = nil';
                }
                
            case TBlock(el):
                if (el.length == 0) {
                    "nil";
                } else if (el.length == 1) {
                    compileExpression(el[0]);
                } else {
                    // For multiple statements, compile each and join with newlines
                    // The last expression is the return value in Elixir
                    var compiledStatements = [];
                    for (i in 0...el.length) {
                        var compiled = compileExpression(el[i]);
                        if (compiled != null && compiled.trim() != "") {
                            compiledStatements.push(compiled);
                        }
                    }
                    compiledStatements.join("\n");
                }
                
            case TIf(econd, eif, eelse):
                var cond = compileExpression(econd);
                var ifExpr = compileExpression(eif);
                var elseExpr = eelse != null ? compileExpression(eelse) : "nil";
                
                // For complex expressions, use multi-line if/else format
                var isComplexIf = ifExpr.contains("\n") || (elseExpr != "nil" && elseExpr.contains("\n"));
                
                if (isComplexIf) {
                    var result = 'if ${cond} do\n';
                    result += ifExpr.split("\n").map(line -> line.length > 0 ? "  " + line : line).join("\n") + "\n";
                    if (eelse != null) {
                        result += 'else\n';
                        result += elseExpr.split("\n").map(line -> line.length > 0 ? "  " + line : line).join("\n") + "\n";
                    }
                    result += 'end';
                    result;
                } else {
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
                // Compile for-in loops to idiomatic Elixir Enum operations
                compileForLoop(tvar, iterExpr, blockExpr);
                
            case TWhile(econd, ebody, normalWhile):
                // Try to detect and optimize common for-in loop patterns
                var optimized = tryOptimizeForInPattern(econd, ebody);
                if (optimized != null) {
                    return optimized;
                }
                
                // Generate idiomatic Elixir recursive loop
                compileWhileLoop(econd, ebody, normalWhile);
                
            case TArray(e1, e2):
                var arrayExpr = compileExpression(e1);
                var indexExpr = compileExpression(e2);
                'Enum.at(${arrayExpr}, ${indexExpr})';
                
            case TNew(c, _, el):
                var className = NamingHelper.getElixirModuleName(c.toString());
                var args = el.map(expr -> compileExpression(expr)).join(", ");
                args.length > 0 ? 
                    '${className}.new(${args})' :
                    '${className}.new()';
                
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
                
            case _:
                "# TODO: Implement expression type: " + expr.expr.getName();
        }
    }
    
    /**
     * Compile switch expression to Elixir case statement with advanced pattern matching
     * Supports enum patterns, guard clauses, binary patterns, and pin operators
     */
    private function compileSwitchExpression(switchExpr: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, defaultExpr: Null<TypedExpr>): String {
        // Use PatternMatcher for advanced pattern compilation
        if (patternMatcher == null) {
            patternMatcher = new reflaxe.elixir.helpers.PatternMatcher();
            patternMatcher.setCompiler(this);
        }
        
        var result = new StringBuf();
        var switchValue = compileExpression(switchExpr);
        
        result.add('case ${switchValue} do\n');
        
        // Process each case with advanced pattern support
        for (caseItem in cases) {
            for (value in caseItem.values) {
                // Use PatternMatcher for all pattern types
                var pattern = patternMatcher.compilePattern(value);
                
                // Check for guard expressions (if the field exists)
                var guardClause = "";
                // Guards are typically embedded in the value patterns in Haxe switch statements
                // We'll need to extract them from the pattern if present
                
                var caseExpr = compileExpression(caseItem.expr);
                result.add('  ${pattern}${guardClause} ->\n');
                result.add('    ${caseExpr}\n');
            }
        }
        
        // Add default case if present
        if (defaultExpr != null) {
            var defaultCode = compileExpression(defaultExpr);
            result.add('  _ ->\n');
            result.add('    ${defaultCode}\n');
        }
        
        result.add('end');
        
        return result.toString();
    }
    
    /**
     * Compile enum constructor pattern for case matching
     */
    private function compileEnumPattern(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TField(_, FEnum(enumType, enumField)):
                // Simple enum pattern: SomeEnum.Option → :option
                var fieldName = NamingHelper.toSnakeCase(enumField.name);
                ':${fieldName}';
                
            case TCall(e, args) if (isEnumFieldAccess(e)):
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
                var paramName = NamingHelper.toSnakeCase(arg.originalName);
                params.push(paramName);
            }
            paramStr = params.join(", ");
        }
        var result = '  @doc "Generated from Haxe ${funcField.field.name}"\n';
        result += '  def ${funcName}(${paramStr}) do\n';
        
        if (funcField.expr != null) {
            // Compile the actual function body  
            var compiledBody = compileExpression(funcField.expr);
            if (compiledBody != null && compiledBody.trim() != "") {
                // Indent the function body properly
                var indentedBody = compiledBody.split("\n").map(line -> line.length > 0 ? "    " + line : line).join("\n");
                result += '${indentedBody}\n';
            } else {
                result += '    # TODO: Implement function body\n';
                result += '    nil\n';
            }
        } else {
            result += '    # TODO: Implement function body\n';
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
            case TThis: "__MODULE__"; // In Elixir, use __MODULE__ for self-reference
            case TSuper: "super"; // Elixir doesn't have super() - would need delegation
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
                    var left = compileExpressionWithTypeAwareness(e1);
                    var right = compileExpressionWithTypeAwareness(e2);
                    
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
        var expr = compileExpression(e);
        
        return switch (fa) {
            case FInstance(classType, _, classFieldRef):
                var fieldName = classFieldRef.get().name;
                
                // Special handling for String properties
                var classTypeName = classType.get().name;
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
                
                // Default field access
                fieldName = NamingHelper.toSnakeCase(fieldName);
                '${expr}.${fieldName}'; // Map access syntax
                
            case FStatic(classType, classFieldRef):
                var cls = classType.get();
                var className = NamingHelper.getElixirModuleName(cls.getNameOrNative());
                var fieldName = classFieldRef.get().name;
                
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
                '&${expr}.${fieldName}/0'; // Function capture syntax
                
            case FEnum(enumType, enumField):
                var enumName = NamingHelper.getElixirModuleName(enumType.get().getNameOrNative());
                var optionName = NamingHelper.toSnakeCase(enumField.name);
                '${enumName}.${optionName}()'; // Enum constructor call
        }
    }
    
    /**
     * Set up parameter mapping for function compilation
     */
    public function setFunctionParameterMapping(args: Array<reflaxe.data.ClassFuncArg>): Void {
        currentFunctionParameterMap.clear();
        isCompilingAbstractMethod = true;
        
        if (args != null) {
            for (i in 0...args.length) {
                var arg = args[i];
                // Try to get the name from tvar if available
                var argName = if (arg.tvar != null) {
                    arg.tvar.name;
                } else {
                    // Fallback to a generated name
                    'param${i}';
                }
                
                currentFunctionParameterMap.set(argName, 'arg${i}');
                
                // Also handle common abstract type parameter patterns
                if (argName == "this") {
                    currentFunctionParameterMap.set("this1", 'arg${i}');
                }
            }
        }
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
                
                // Check if this is a String method call
                switch (obj.t) {
                    case TInst(t, _) if (t.get().name == "String"):
                        return compileStringMethod(objStr, methodName, args);
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
                
                // Check if methodName already contains a module path (from @:native annotation)
                if (methodName.indexOf(".") >= 0) {
                    // Native method with full path - use it directly
                    return '${methodName}(${compiledArgs.join(", ")})';
                } else {
                    // Regular method call - concatenate with object
                    return '${objStr}.${methodName}(${compiledArgs.join(", ")})';
                }
                
            case _:
                // Regular function call
                var compiledArgs = args.map(arg -> compileExpression(arg));
                return compileExpression(e) + "(" + compiledArgs.join(", ") + ")";
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
        // Get the original variable name before Haxe's renaming
        var originalName = getOriginalVarName(tvar);
        var loopVar = NamingHelper.toSnakeCase(originalName);
        var iterableExpr = compileExpression(iterExpr);
        
        // Check if this is a find pattern (early return) - highest priority
        if (hasReturnStatement(blockExpr)) {
            var body = compileExpressionWithSubstitution(blockExpr, originalName, loopVar);
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
        var body = compileExpressionWithSubstitution(blockExpr, originalName, loopVar);
        
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
     * Generate Enum.find pattern for early return loops
     */
    private function generateEnumFindPattern(arrayExpr: String, loopVar: String, ebody: TypedExpr): String {
        // Extract the condition from the if statement
        var condition = extractConditionFromReturn(ebody);
        if (condition != null) {
            // Generate Enum.find for simple cases
            return 'Enum.find(${arrayExpr}, fn ${loopVar} -> ${condition} end)';
        }
        
        // Fallback to reduce_while for complex cases
        return '(\n' +
               '  Enum.reduce_while(${arrayExpr}, nil, fn ${loopVar}, _acc ->\n' +
               '    ${transformFindLoopBody(ebody, loopVar)}\n' +
               '  end)\n' +
               ')';
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
        // Find the source variable in the condition
        var sourceVar = findLoopVariable(conditionExpr);
        
        // Use "item" as the target variable for the lambda parameter
        var actualLoopVar = "item";
        
        // Apply variable substitution to the condition
        var condition = compileExpressionWithVarMapping(conditionExpr, sourceVar, actualLoopVar);
        return 'Enum.count(${arrayExpr}, fn ${actualLoopVar} -> ${condition} end)';
    }
    
    /**
     * Generate Enum.filter pattern for filtering arrays
     */
    private function generateEnumFilterPattern(arrayExpr: String, loopVar: String, conditionExpr: TypedExpr): String {
        // Find the source variable in the condition
        var sourceVar = findLoopVariable(conditionExpr);
        
        // Use "item" as the target variable for the lambda parameter
        var targetVar = "item";
        
        // Apply variable substitution to the condition
        var condition = compileExpressionWithVarMapping(conditionExpr, sourceVar, targetVar);
        
        return 'Enum.filter(${arrayExpr}, fn ${targetVar} -> ${condition} end)';
    }
    
    /**
     * Generate Enum.map pattern for transforming arrays
     */
    private function generateEnumMapPattern(arrayExpr: String, loopVar: String, ebody: TypedExpr): String {
        // Try to find the lambda parameter directly from the body
        var lambdaParam = getLambdaParameterFromBody(ebody);
        
        // Use consistent target variable name for lambda parameter
        var targetVar = "item";
        
        // Extract transformation with proper variable substitution
        var transformation: String;
        if (lambdaParam != null) {
            // Use TVar-based substitution for more accurate variable matching
            transformation = extractTransformationFromBodyWithTVar(ebody, lambdaParam, targetVar);
        } else {
            // Fallback to string-based approach
            var sourceVar = findLoopVariable(ebody);
            transformation = extractTransformationFromBody(ebody, sourceVar, targetVar);
        }
        
        return 'Enum.map(${arrayExpr}, fn ${targetVar} -> ${transformation} end)';
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
        if (sourceVar == null) {
            return compileExpression(expr);
        }
        
        
        // Compile with variable substitution
        return compileExpressionWithSubstitution(expr, sourceVar, targetVar);
    }
    
    /**
     * Find the loop variable being used in an expression
     */
    private function findLoopVariable(expr: TypedExpr): Null<String> {
        var variables = new Map<String, Int>();
        collectVariables(expr, variables);
        
        // Find the most frequently used non-compiler variable
        var bestVar: String = null;
        var bestCount = 0;
        
        for (varName => count in variables) {
            // Skip compiler-generated variables
            if (varName != "_g" && varName != "_g1" && varName != "_g2" && 
                !varName.startsWith("temp_") && !varName.startsWith("_this")) {
                if (count > bestCount) {
                    bestVar = varName;
                    bestCount = count;
                }
            }
        }
        
        return bestVar;
    }
    
    /**
     * Collect all variable names and their usage counts from an expression
     */
    private function collectVariables(expr: TypedExpr, variables: Map<String, Int>): Void {
        switch (expr.expr) {
            case TLocal(v):
                var originalName = getOriginalVarName(v);
                var currentCount = variables.exists(originalName) ? variables.get(originalName) : 0;
                variables.set(originalName, currentCount + 1);
            case TBinop(_, e1, e2):
                collectVariables(e1, variables);
                collectVariables(e2, variables);
            case TField(e, _):
                collectVariables(e, variables);
            case TCall(e, args):
                collectVariables(e, variables);
                for (arg in args) {
                    collectVariables(arg, variables);
                }
            case TArray(e1, e2):
                collectVariables(e1, variables);
                collectVariables(e2, variables);
            case TIf(econd, eif, eelse):
                collectVariables(econd, variables);
                collectVariables(eif, variables);
                if (eelse != null) collectVariables(eelse, variables);
            case TBlock(exprs):
                for (e in exprs) {
                    collectVariables(e, variables);
                }
            case TParenthesis(e):
                // Handle parenthesized expressions
                collectVariables(e, variables);
            case _:
                // Other expression types don't contain variables
        }
    }
    
    /**
     * Compile expression with variable substitution using TVar object comparison
     */
    private function compileExpressionWithTVarSubstitution(expr: TypedExpr, sourceTVar: TVar, targetVarName: String): String {
        switch (expr.expr) {
            case TLocal(v) if (v == sourceTVar):
                // Replace the source variable with target
                return targetVarName;
            case TBinop(op, e1, e2):
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
                var obj = compileExpressionWithTVarSubstitution(e, sourceTVar, targetVarName);
                var fieldName = getFieldName(fa);
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
            case _:
                // For other cases, fall back to regular compilation
                return compileExpression(expr);
        }
    }

    /**
     * Compile expression with variable substitution (string-based version)
     */
    private function compileExpressionWithSubstitution(expr: TypedExpr, sourceVar: String, targetVar: String): String {
        switch (expr.expr) {
            case TLocal(v) if (getOriginalVarName(v) == sourceVar):
                // Replace the source variable with target
                return targetVar;
            case TBinop(op, e1, e2):
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
                // Handle method calls with substitution
                var obj = compileExpressionWithSubstitution(e, sourceVar, targetVar);
                var compiledArgs = args.map(arg -> compileExpressionWithSubstitution(arg, sourceVar, targetVar));
                return '${obj}(${compiledArgs.join(", ")})';
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
        // Extract variables that are modified in the loop
        var modifiedVars = extractModifiedVariables(ebody);
        var condition = compileExpression(econd);
        
        // Transform the loop body to handle mutations functionally
        var transformedBody = transformLoopBodyMutations(ebody, modifiedVars, normalWhile, condition);
        
        if (normalWhile) {
            // while (condition) { body }
            if (modifiedVars.length > 0) {
                var stateVars = modifiedVars.map(v -> v.name).join(", ");
                return '(\n' +
                       '  try do\n' +
                       '    loop_fn = fn {${stateVars}} ->\n' +
                       '      if ${condition} do\n' +
                       '        try do\n' +
                       '          ${transformedBody}\n' +
                       '        catch\n' +
                       '          :break -> {${stateVars}}\n' +
                       '          :continue -> loop_fn.({${stateVars}})\n' +
                       '        end\n' +
                       '      else\n' +
                       '        {${stateVars}}\n' +
                       '      end\n' +
                       '    end\n' +
                       '    loop_fn.({${stateVars}})\n' +
                       '  catch\n' +
                       '    :break -> {${stateVars}}\n' +
                       '  end\n' +
                       ')';
            } else {
                // Simple loop without state - compile normally but use tail recursion
                var body = compileExpression(ebody);
                return '(\n' +
                       '  try do\n' +
                       '    loop_fn = fn ->\n' +
                       '      if ${condition} do\n' +
                       '        try do\n' +
                       '          ${body}\n' +
                       '          loop_fn.()\n' +
                       '        catch\n' +
                       '          :break -> nil\n' +
                       '          :continue -> loop_fn.()\n' +
                       '        end\n' +
                       '      end\n' +
                       '    end\n' +
                       '    loop_fn.()\n' +
                       '  catch\n' +
                       '    :break -> nil\n' +
                       '  end\n' +
                       ')';
            }
        } else {
            // do { body } while (condition)
            if (modifiedVars.length > 0) {
                var stateVars = modifiedVars.map(v -> v.name).join(", ");
                return '(\n' +
                       '  loop_fn = fn {${stateVars}} ->\n' +
                       '    ${transformedBody}\n' +
                       '  end\n' +
                       '  {${stateVars}} = loop_fn.({${stateVars}})\n' +
                       ')';
            } else {
                var body = compileExpression(ebody);
                return '(\n' +
                       '  loop_fn = fn ->\n' +
                       '    ${body}\n' +
                       '    if ${condition}, do: loop_fn.(), else: nil\n' +
                       '  end\n' +
                       '  loop_fn.()\n' +
                       ')';
            }
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
        
        // Generate the return statement with updated values
        var stateVars = modifiedVars.map(v -> {
            return updates.exists(v.name) ? updates.get(v.name) : v.name;
        }).join(", ");
        
        if (normalWhile) {
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
                for (e in exprs) {
                    results.push(compileExpressionWithMutationTracking(e, updates));
                }
                results.join("\n      ");
                
            case TBinop(OpAssign, e1, e2):
                // Handle variable assignment
                switch (e1.expr) {
                    case TLocal(v):
                        var originalName = getOriginalVarName(v);
                        var rightSide = compileExpression(e2);
                        updates.set(originalName, rightSide);
                        '# ${originalName} updated to ${rightSide}';
                    case _:
                        compileExpression(expr);
                }
                
            case TBinop(OpAssignOp(innerOp), e1, e2):
                // Handle compound assignment
                switch (e1.expr) {
                    case TLocal(v):
                        var originalName = getOriginalVarName(v);
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
                        
                        var newValue = '${originalName} ${opStr} ${rightSide}';
                        updates.set(originalName, newValue);
                        '# ${originalName} updated with ${opStr} ${rightSide}';
                    case _:
                        compileExpression(expr);
                }
                
            case TUnop(OpIncrement | OpDecrement, postFix, e1):
                // Handle increment/decrement
                switch (e1.expr) {
                    case TLocal(v):
                        var originalName = getOriginalVarName(v);
                        var op = switch (expr.expr) {
                            case TUnop(OpIncrement, _, _): "+";
                            case TUnop(OpDecrement, _, _): "-";
                            case _: "+";
                        };
                        var newValue = '${originalName} ${op} 1';
                        updates.set(originalName, newValue);
                        '# ${originalName} ${op == "+" ? "incremented" : "decremented"}';
                    case _:
                        compileExpression(expr);
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
                 "sort", "shift", "unshift", "every", "some":
                true;
            case _:
                false;
        };
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
        var compiledArgs = args.map(arg -> compileExpression(arg));
        
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
                    'Enum.map(${objStr}, ${compiledArgs[0]})';
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
                                // Handle lambda with proper variable substitution
                                var paramName = func.args.length > 0 ? NamingHelper.toSnakeCase(getOriginalVarName(func.args[0].v)) : "item";
                                var sourceVar = findLoopVariable(func.expr);
                                var body = compileExpressionWithVarMapping(func.expr, sourceVar, paramName);
                                return 'Enum.filter(${objStr}, fn ${paramName} -> ${body} end)';
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
            case _:
                // Default: try to call as a regular method
                '${objStr}.${methodName}(${compiledArgs.join(", ")})';
        };
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
                return field.name;
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
                return field.name;
            case FDynamic(s): s;
            case FEnum(_, ef): ef.name;
        };
    }
    
}

#end