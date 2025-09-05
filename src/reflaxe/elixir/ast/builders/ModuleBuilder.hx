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
 * - @:presence - Phoenix.Presence module with tracking and listing functions
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
 * - isPresence: Boolean flag for @:presence annotation
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
        } else if (metadata.isPresence) {
            // For @:presence, build regular module body - transformer will add Phoenix.Presence
            buildRegularModuleBody(classType, varFields, funcFields);
        } else if (metadata.isExunit) {
            // For @:exunit, build test module body - transformer will add ExUnit.Case
            buildExUnitBody(classType, varFields, funcFields);
        } else {
            // Regular module
            buildRegularModuleBody(classType, varFields, funcFields);
        }
        
        // Create the module AST with metadata
        #if debug_module_builder
        trace('[ModuleBuilder] About to create module AST with metadata: ${metadata}');
        #end
        var moduleAST = makeASTWithMeta(
            EDefmodule(moduleName, moduleBody),
            metadata,
            null
        );
        
        // Restore previous module context
        reflaxe.elixir.ast.ElixirASTBuilder.currentModule = previousModule;
        
        #if debug_module_builder
        trace('[ModuleBuilder] Created module AST for ${moduleName} with metadata: ${metadata}');
        trace('[ModuleBuilder] Module AST metadata check: ${moduleAST.metadata}');
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
            #end
        }
        
        // Check for Phoenix LiveView
        if (classType.meta.has(":liveview")) {
            metadata.isLiveView = true;
            #if debug_module_builder
            #end
        }
        
        // Check for Ecto Schema
        if (classType.meta.has(":schema")) {
            metadata.isSchema = true;
            metadata.tableName = extractTableName(classType);
            #if debug_module_builder
            #end
        }
        
        // Check for OTP Application
        if (classType.meta.has(":application")) {
            metadata.isApplication = true;
            metadata.appName = extractAppName(classType);
            #if debug_module_builder
            #end
        }
        
        // Check for GenServer
        if (classType.meta.has(":genserver")) {
            metadata.isGenServer = true;
            #if debug_module_builder
            #end
        }
        
        // Check for Router
        if (classType.meta.has(":router")) {
            metadata.isRouter = true;
            #if debug_module_builder
            #end
        }
        
        // Check for Controller
        if (classType.meta.has(":controller")) {
            metadata.isController = true;
            metadata.appName = extractAppName(classType);
            #if debug_module_builder
            #end
        }
        
        // Check for Presence
        if (classType.meta.has(":presence")) {
            metadata.isPresence = true;
            metadata.appName = extractAppName(classType);
        }
        
        // Check for PhoenixWeb (supports both @:phoenixWeb and @:phoenixWebModule)
        if (classType.meta.has(":phoenixWeb") || classType.meta.has(":phoenixWebModule")) {
            metadata.isPhoenixWeb = true;
            metadata.appName = extractAppName(classType);
            #if debug_module_builder
            #end
        }
        
        // Check for ExUnit test module
        if (classType.meta.has(":exunit") || classType.meta.has(":elixir.exunit")) {
            metadata.isExunit = true;
            #if debug_module_builder
            trace('[ModuleBuilder] ✓ Found @:exunit on class: ${classType.name}');
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
        #end
        
        // Compile all functions (public and private) in controllers
        for (func in funcFields) {
            #if debug_module_builder
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
                        // First analyze variable usage for proper underscore prefixing
                        var functionUsageMap = if (tfunc.expr != null) {
                            reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                        } else {
                            null;
                        };
                        
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr, functionUsageMap);
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
            #end
            
            // Skip Phoenix.Component placeholder functions
            if (phoenixComponentFunctions.indexOf(func.name) != -1) {
                #if debug_module_builder
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
                        // First analyze variable usage for proper underscore prefixing
                        var functionUsageMap = if (tfunc.expr != null) {
                            reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                        } else {
                            null;
                        };
                        
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr, functionUsageMap);
                        } else {
                            makeAST(ENil);
                        }
                        
                        // Check if this is a test function
                        var isTestFunction = func.meta.has(":test");
                        #if debug_module_builder
                        trace('[XRay ModuleBuilder] Function ${funcName} has metadata: ${[for (m in func.meta.get()) m.name].join(", ")}');
                        trace('[XRay ModuleBuilder] isTestFunction: $isTestFunction');
                        #end
                        
                        // Create function definition with metadata
                        var funcAst = if (func.isPublic) {
                            makeAST(EDef(funcName, args, null, body));
                        } else {
                            makeAST(EDefp(funcName, args, null, body));
                        }
                        
                        // Add test metadata if this is a test function
                        if (isTestFunction) {
                            var metadata = funcAst.metadata != null ? funcAst.metadata : {};
                            metadata.isTest = true;
                            funcAst = makeASTWithMeta(funcAst.def, metadata, funcAst.pos);
                        }
                        
                        statements.push(funcAst);
                        
                    default:
                        // Not a function, skip
                        #if debug_module_builder
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
        for (func in funcFields) {
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
                        // First analyze variable usage for proper underscore prefixing
                        var functionUsageMap = if (tfunc.expr != null) {
                            reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                        } else {
                            null;
                        };
                        
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr, functionUsageMap);
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
                        // First analyze variable usage for proper underscore prefixing
                        var functionUsageMap = if (tfunc.expr != null) {
                            reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                        } else {
                            null;
                        };
                        
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr, functionUsageMap);
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
            var funcExpr = func.expr();
            if (funcExpr != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                
                // Get usage map for proper parameter naming
                var functionUsageMap = switch(funcExpr.expr) {
                    case TFunction(tfunc) if (tfunc.expr != null):
                        reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                    case _:
                        null;
                };
                
                // Build the entire function using ElixirASTBuilder which handles reserved keywords
                var funcAst = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(funcExpr, functionUsageMap);
                
                // The AST builder returns a function, extract it and wrap in def/defp
                switch(funcAst.def) {
                    case EFn(clauses) if (clauses.length > 0):
                        // Extract the first clause (functions typically have one clause)
                        var clause = clauses[0];
                        // Create the function definition (use defp for private functions)
                        if (func.isPublic) {
                            statements.push(makeAST(EDef(funcName, clause.args, null, clause.body)));
                        } else {
                            statements.push(makeAST(EDefp(funcName, clause.args, null, clause.body)));
                        }
                    case _:
                        // If it's not a function AST, something went wrong, skip it
                }
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build ExUnit test module body
     * 
     * WHY: ExUnit test classes need special structure with test methods marked
     * WHAT: Processes methods and marks @:test methods with metadata
     * HOW: Adds metadata to test functions for transformer to handle
     */
    static function buildExUnitBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        // Add functions with test metadata
        for (func in funcFields) {
            var funcExpr = func.expr();
            if (funcExpr != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                
                // Check if this function has @:test or :elixir.test metadata
                var isTest = false;
                var isSetup = false;
                var isSetupAll = false;
                var isTeardown = false;
                var isTeardownAll = false;
                
                if (func.meta != null && func.meta.has != null) {
                    isTest = func.meta.has(":test") || func.meta.has("test") || func.meta.has(":elixir.test");
                    
                    // Check for setup/teardown metadata added by ExUnitBuilder
                    if (func.meta.has(":elixir.setup") || func.name == "setup") {
                        isSetup = true;
                    } else if (func.meta.has(":elixir.setupAll") || func.name == "setupAll") {
                        isSetupAll = true;
                    } else if (func.meta.has(":elixir.teardown") || func.name == "teardown") {
                        isTeardown = true;
                    } else if (func.meta.has(":elixir.teardownAll") || func.name == "teardownAll") {
                        isTeardownAll = true;
                    }
                }
                
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
                        // First analyze variable usage for proper underscore prefixing
                        var functionUsageMap = if (tfunc.expr != null) {
                            reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                        } else {
                            null;
                        };
                        
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr, functionUsageMap);
                        } else {
                            makeAST(ENil);
                        }
                        
                        // Create the function definition (use defp for private functions)
                        var funcAST = if (func.isPublic) {
                            makeAST(EDef(funcName, args, null, body));
                        } else {
                            makeAST(EDefp(funcName, args, null, body));
                        }
                        
                        // Add appropriate metadata to the AST node
                        var metadata: Dynamic = {};
                        if (isTest) metadata.isTest = true;
                        if (isSetup) metadata.isSetup = true;
                        if (isSetupAll) metadata.isSetupAll = true;
                        if (isTeardown) metadata.isTeardown = true;
                        if (isTeardownAll) metadata.isTeardownAll = true;
                        
                        // Only add metadata if we have any flags set
                        if (isTest || isSetup || isSetupAll || isTeardown || isTeardownAll) {
                            funcAST = makeASTWithMeta(
                                funcAST.def,
                                metadata,
                                funcAST.pos
                            );
                        }
                        
                        statements.push(funcAST);
                        
                    default:
                        // Not a function, skip
                }
            }
        }
        
        // Return the statements block
        return makeAST(EBlock(statements));
    }
}

#end