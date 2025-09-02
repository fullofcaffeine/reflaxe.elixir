package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.ClassField;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.NameUtils;

/**
 * ModuleBuilder: Responsible for building Elixir module AST nodes from Haxe classes
 * 
 * WHY: Separation of concerns - extract module building logic from the monolithic ElixirASTBuilder
 *      to keep files under 1000 lines and maintain single responsibility principle.
 * 
 * WHAT: Converts Haxe ClassType to Elixir module AST (EDefmodule) with proper metadata
 *       for annotations like @:endpoint, @:liveview, @:schema, @:application, @:phoenixWeb, etc.
 * 
 * HOW: Detects class annotations and sets metadata flags that transformers will use
 *      to apply framework-specific transformations. This builder ONLY builds structure,
 *      never transforms or generates framework-specific code.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only builds module structure
 * - Metadata-Driven: Sets flags for transformers to act upon
 * - Clean Separation: Building vs transformation logic separated
 * - Maintainable Size: Keeps files under 1000 lines
 * - Testable: Can test module building independently
 * 
 * SUPPORTED ANNOTATIONS:
 * - @:endpoint - Phoenix.Endpoint module with web server configuration
 * - @:liveview - Phoenix.LiveView module with mount/handle_event/render
 * - @:schema - Ecto.Schema module with database field definitions
 * - @:application - OTP Application module with supervision tree
 * - @:phoenixWeb - Phoenix Web helper module with DSL macros
 * - @:genserver - GenServer behavior module
 * - @:router - Phoenix.Router module with routing DSL
 * - @:controller - Phoenix.Controller module with action functions
 * 
 * METADATA FIELDS SET:
 * - isEndpoint: Boolean flag for @:endpoint annotation
 * - isLiveView: Boolean flag for @:liveview annotation  
 * - isSchema: Boolean flag for @:schema annotation
 * - isApplication: Boolean flag for @:application annotation
 * - isPhoenixWeb: Boolean flag for @:phoenixWeb annotation
 * - isGenServer: Boolean flag for @:genserver annotation
 * - isRouter: Boolean flag for @:router annotation
 * - isController: Boolean flag for @:controller annotation
 * - appName: String with application name (for endpoint/application)
 * - tableName: String with database table name (for schema)
 * 
 * USAGE:
 * This is called by ElixirCompiler.buildClassAST() when hasSpecialAnnotations() returns true.
 * The metadata set here is consumed by AnnotationTransforms transformation passes.
 * 
 * EDGE CASES:
 * - Class without annotations: Returns regular module body structure
 * - Multiple annotations: First annotation wins (shouldn't happen in practice)
 * - Invalid annotation parameters: Falls back to default values
 */
@:nullSafety(Off)
class ModuleBuilder {
    
    /**
     * Build a module AST from a Haxe class
     * 
     * WHY: Classes need to be converted to Elixir modules with proper structure
     * WHAT: Creates EDefmodule node with metadata for annotations
     * HOW: Extracts class metadata, builds module body, sets transformation flags
     */
    public static function buildClassModule(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        #if debug_module_builder
        trace('[ModuleBuilder] Building module for class: ${classType.name}');
        #end
        
        // Extract module name
        var moduleName = extractModuleName(classType);
        
        // Set current module context for ElixirASTBuilder
        var previousModule = reflaxe.elixir.ast.ElixirASTBuilder.currentModule;
        reflaxe.elixir.ast.ElixirASTBuilder.currentModule = classType.name;
        
        // Create metadata for the module
        var metadata = createModuleMetadata(classType);
        
        // Build module body based on annotations
        var moduleBody = if (metadata.isPhoenixWeb) {
            // For @:phoenixWeb, create minimal structure - transformer will add macros
            buildMinimalBody(classType, varFields, funcFields);
        } else if (metadata.isEndpoint) {
            // For @:endpoint, create minimal structure - transformer will add the rest
            buildMinimalBody(classType, varFields, funcFields);
        } else if (metadata.isController) {
            // For @:controller, build controller action functions
            buildControllerBody(classType, varFields, funcFields);
        } else if (metadata.isLiveView) {
            // For @:liveview, build basic function structure
            buildLiveViewBody(classType, varFields, funcFields);
        } else if (metadata.isSchema) {
            // For @:schema, build schema structure
            buildSchemaBody(classType, varFields, funcFields);
        } else if (metadata.isApplication) {
            // For @:application, build OTP application structure
            buildApplicationBody(classType, varFields, funcFields);
        } else {
            // Regular module
            buildRegularModuleBody(classType, varFields, funcFields);
        }
        
        // Create the module AST with metadata
        var moduleAST = makeASTWithMeta(
            EDefmodule(moduleName, moduleBody),
            metadata,
            null
        );
        
        // Restore previous module context
        reflaxe.elixir.ast.ElixirASTBuilder.currentModule = previousModule;
        
        #if debug_module_builder
        trace('[ModuleBuilder] Built module AST with metadata: ${metadata}');
        #end
        
        return moduleAST;
    }
    
    /**
     * Extract the module name from a class, checking for @:native annotation
     */
    static function extractModuleName(classType: ClassType): String {
        if (classType.meta.has(":native")) {
            var nativeMeta = classType.meta.extract(":native");
            if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                switch(nativeMeta[0].params[0].expr) {
                    case EConst(CString(s, _)):
                        return s;
                    default:
                }
            }
        }
        return classType.name;
    }
    
    /**
     * Create metadata based on class annotations
     * 
     * WHY: Transformers need to know what kind of module this is
     * WHAT: Sets boolean flags and extracts annotation parameters
     * HOW: Checks for known annotations and extracts their parameters
     */
    static function createModuleMetadata(classType: ClassType): ElixirMetadata {
        var metadata: ElixirMetadata = {};
        
        // Check for Phoenix Endpoint
        if (classType.meta.has(":endpoint")) {
            metadata.isEndpoint = true;
            metadata.appName = extractAppName(classType);
            #if debug_module_builder
            trace('[ModuleBuilder] Detected @:endpoint annotation, appName: ${metadata.appName}');
            #end
        }
        
        // Check for Phoenix LiveView
        if (classType.meta.has(":liveview")) {
            metadata.isLiveView = true;
            #if debug_module_builder
            trace('[ModuleBuilder] Detected @:liveview annotation');
            #end
        }
        
        // Check for Ecto Schema
        if (classType.meta.has(":schema")) {
            metadata.isSchema = true;
            metadata.tableName = extractTableName(classType);
            #if debug_module_builder
            trace('[ModuleBuilder] Detected @:schema annotation, table: ${metadata.tableName}');
            #end
        }
        
        // Check for OTP Application
        if (classType.meta.has(":application")) {
            metadata.isApplication = true;
            metadata.appName = extractAppName(classType);
            #if debug_module_builder
            trace('[ModuleBuilder] Detected @:application annotation');
            #end
        }
        
        // Check for GenServer
        if (classType.meta.has(":genserver")) {
            metadata.isGenServer = true;
            #if debug_module_builder
            trace('[ModuleBuilder] Detected @:genserver annotation');
            #end
        }
        
        // Check for Router
        if (classType.meta.has(":router")) {
            metadata.isRouter = true;
            #if debug_module_builder
            trace('[ModuleBuilder] Detected @:router annotation');
            #end
        }
        
        // Check for Controller
        if (classType.meta.has(":controller")) {
            metadata.isController = true;
            metadata.appName = extractAppName(classType);
            #if debug_module_builder
            trace('[ModuleBuilder] Detected @:controller annotation, appName: ${metadata.appName}');
            #end
        }
        
        // Check for PhoenixWeb (supports both @:phoenixWeb and @:phoenixWebModule)
        if (classType.meta.has(":phoenixWeb") || classType.meta.has(":phoenixWebModule")) {
            metadata.isPhoenixWeb = true;
            metadata.appName = extractAppName(classType);
            #if debug_module_builder
            trace('[ModuleBuilder] Detected @:phoenixWeb/@:phoenixWebModule annotation, appName: ${metadata.appName}');
            #end
        }
        
        return metadata;
    }
    
    /**
     * Extract application name from class metadata or derive from module name
     */
    static function extractAppName(classType: ClassType): String {
        if (classType.meta.has(":appName")) {
            var appNameMeta = classType.meta.extract(":appName");
            if (appNameMeta.length > 0 && appNameMeta[0].params != null && appNameMeta[0].params.length > 0) {
                switch(appNameMeta[0].params[0].expr) {
                    case EConst(CString(s, _)):
                        return NameUtils.toSnakeCase(s);
                    default:
                }
            }
        }
        
        // Default: derive from module name
        var moduleName = extractModuleName(classType);
        // Remove "Web" suffix if present for Phoenix conventions
        var appName = moduleName.split("Web")[0];
        return NameUtils.toSnakeCase(appName);
    }
    
    /**
     * Extract table name from @:schema annotation or derive from class name
     */
    static function extractTableName(classType: ClassType): String {
        var schemaMeta = classType.meta.extract(":schema");
        if (schemaMeta.length > 0 && schemaMeta[0].params != null && schemaMeta[0].params.length > 0) {
            switch(schemaMeta[0].params[0].expr) {
                case EConst(CString(s, _)):
                    return s;
                default:
            }
        }
        
        // Default: pluralize snake_case class name
        var className = NameUtils.toSnakeCase(classType.name);
        // Simple pluralization (add 's' - could be improved)
        return className + "s";
    }
    
    /**
     * Build minimal body for modules that will be heavily transformed
     * 
     * WHY: Some modules like @:endpoint need complete transformation
     * WHAT: Creates empty or minimal structure
     * HOW: Returns simple block that transformer will replace
     */
    static function buildMinimalBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        // For endpoint and similar, just create an empty block
        // The transformer will add all the necessary structure
        return makeAST(EBlock([]));
    }
    
    /**
     * Build body for Controller modules
     * 
     * WHY: Phoenix controllers need their action functions compiled with proper signatures
     * WHAT: Builds controller action functions that receive conn and params
     * HOW: Compiles each public function as a controller action
     */
    static function buildControllerBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        #if debug_module_builder
        trace('[ModuleBuilder] Building controller body with ${funcFields.length} functions');
        #end
        
        // Compile all functions (public and private) in controllers
        for (func in funcFields) {
            #if debug_module_builder
            trace('[ModuleBuilder] Checking function: ${func.name}, isPublic: ${func.isPublic}, hasExpr: ${func.expr() != null}');
            #end
            
            if (func.expr() != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                var funcExpr = func.expr();
                
                // Extract parameters and body from the function expression
                switch(funcExpr.expr) {
                    case TFunction(tfunc):
                        var args = [];
                        
                        // Controller actions always take conn and params
                        // The Haxe function should declare these parameters
                        for (arg in tfunc.args) {
                            var paramName = NameUtils.toSnakeCase(arg.v.name);
                            args.push(PVar(paramName));
                        }
                        
                        // Build the function body using ElixirASTBuilder
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr);
                        } else {
                            makeAST(ENil);
                        }
                        
                        // Create the function definition (use defp for private functions)
                        if (func.isPublic) {
                            statements.push(makeAST(EDef(funcName, args, null, body)));
                        } else {
                            statements.push(makeAST(EDefp(funcName, args, null, body)));
                        }
                        
                    default:
                        // Not a function, skip
                }
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build body for LiveView modules
     */
    static function buildLiveViewBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        #if debug_module_builder
        trace('[ModuleBuilder] Building LiveView body with ${funcFields.length} functions');
        #end
        
        // Common Phoenix.Component functions that shouldn't be compiled as local functions
        // These are provided by Phoenix.Component and would conflict if defined locally
        var phoenixComponentFunctions = [
            "assign",
            "assign_multiple", 
            "assign_new",
            "update",
            "get_assign"
        ];
        
        // Add functions (mount, handle_event, render, etc.)
        for (func in funcFields) {
            #if debug_module_builder
            trace('[ModuleBuilder] Checking function: ${func.name}, isPublic: ${func.isPublic}, hasExpr: ${func.expr() != null}');
            #end
            
            // Skip Phoenix.Component placeholder functions
            if (phoenixComponentFunctions.indexOf(func.name) != -1) {
                #if debug_module_builder
                trace('[ModuleBuilder] Skipping Phoenix.Component placeholder function: ${func.name}');
                #end
                continue;
            }
            
            if (func.expr() != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                var funcExpr = func.expr();
                
                // Extract parameters and body from the function expression
                switch(funcExpr.expr) {
                    case TFunction(tfunc):
                        var args = [];
                        
                        // Build parameter patterns for the function
                        for (arg in tfunc.args) {
                            var paramName = NameUtils.toSnakeCase(arg.v.name);
                            args.push(PVar(paramName));
                        }
                        
                        // Build the function body using ElixirASTBuilder
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr);
                        } else {
                            makeAST(ENil);
                        }
                        
                        // Create the function definition (use defp for private functions)
                        if (func.isPublic) {
                            statements.push(makeAST(EDef(funcName, args, null, body)));
                        } else {
                            statements.push(makeAST(EDefp(funcName, args, null, body)));
                        }
                        
                    default:
                        // Not a function, skip
                        #if debug_module_builder
                        trace('[ModuleBuilder] Skipping non-function field: ${func.name}');
                        #end
                }
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build body for Ecto Schema modules
     */
    static function buildSchemaBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        #if debug_module_builder
        trace('[ModuleBuilder] buildSchemaBody called with ${funcFields.length} functions');
        for (func in funcFields) {
            trace('[ModuleBuilder] - Function: ${func.name}, isPublic: ${func.isPublic}, hasExpr: ${func.expr() != null}');
        }
        #end
        
        // Schema structure will be added by transformer
        // Build the changeset and other functions with their actual bodies
        for (func in funcFields) {
            var funcExpr = func.expr();
            if (funcExpr != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                
                // Extract the function body from the TypedExpr
                switch(funcExpr.expr) {
                    case TFunction(tfunc):
                        // Extract arguments
                        var args = [];
                        for (arg in tfunc.args) {
                            var paramName = NameUtils.toSnakeCase(arg.v.name);
                            args.push(PVar(paramName));
                        }
                        
                        // Build the function body using ElixirASTBuilder
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr);
                        } else {
                            makeAST(ENil);
                        }
                        
                        // Create the function definition (use defp for private functions)
                        if (func.isPublic) {
                            statements.push(makeAST(EDef(funcName, args, null, body)));
                        } else {
                            statements.push(makeAST(EDefp(funcName, args, null, body)));
                        }
                        
                    default:
                        // Not a function, skip
                }
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build body for OTP Application modules
     */
    static function buildApplicationBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        // Build actual functions with their bodies
        for (func in funcFields) {
            var funcExpr = func.expr();
            if (funcExpr != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                
                // Extract the function body from the TypedExpr
                switch(funcExpr.expr) {
                    case TFunction(tfunc):
                        // Extract arguments
                        var args = [];
                        for (arg in tfunc.args) {
                            var paramName = NameUtils.toSnakeCase(arg.v.name);
                            args.push(PVar(paramName));
                        }
                        
                        // Build the function body using ElixirASTBuilder
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr);
                        } else {
                            makeAST(ENil);
                        }
                        
                        // Create the function definition (use defp for private functions)
                        if (func.isPublic) {
                            statements.push(makeAST(EDef(funcName, args, null, body)));
                        } else {
                            statements.push(makeAST(EDefp(funcName, args, null, body)));
                        }
                        
                    default:
                        // Not a function, skip
                }
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build body for regular modules (no special annotations)
     */
    static function buildRegularModuleBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        // Add module attributes for fields
        for (field in varFields) {
            var fieldName = NameUtils.toSnakeCase(field.name);
            // For now, just create nil - actual value would come from field.expr()
            statements.push(makeAST(EModuleAttribute(fieldName, makeAST(ENil))));
        }
        
        // Add functions
        for (func in funcFields) {
            if (func.expr() != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                var isPrivate = !func.isPublic;
                
                // Build function (simplified - would use FunctionBuilder)
                if (isPrivate) {
                    statements.push(makeAST(EDefp(funcName, [], null, makeAST(ENil))));
                } else {
                    statements.push(makeAST(EDef(funcName, [], null, makeAST(ENil))));
                }
            }
        }
        
        return makeAST(EBlock(statements));
    }
}

#end