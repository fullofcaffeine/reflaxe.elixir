package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.ClassField;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirASTMetadata;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.NameUtils;

/**
 * ModuleBuilder: Responsible for building Elixir module AST nodes from Haxe classes
 * 
 * WHY: Separation of concerns - extract module building logic from the monolithic ElixirASTBuilder
 *      to keep files under 1000 lines and maintain single responsibility principle.
 * 
 * WHAT: Converts Haxe ClassType to Elixir module AST (EDefmodule) with proper metadata
 *       for annotations like @:endpoint, @:liveview, @:schema, @:application, etc.
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
        
        // Create metadata for the module
        var metadata = createModuleMetadata(classType);
        
        // Build module body based on annotations
        var moduleBody = if (metadata.isEndpoint) {
            // For @:endpoint, create minimal structure - transformer will add the rest
            buildMinimalBody(classType, varFields, funcFields);
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
    static function createModuleMetadata(classType: ClassType): ElixirASTMetadata {
        var metadata = new ElixirASTMetadata();
        
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
     * Build body for LiveView modules
     */
    static function buildLiveViewBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        // Add functions (mount, handle_event, render, etc.)
        for (func in funcFields) {
            if (func.expr() != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                // Build function AST (simplified for now)
                // The actual function building would use FunctionBuilder
                statements.push(makeAST(EDef(funcName, [], null, makeAST(ENil))));
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build body for Ecto Schema modules
     */
    static function buildSchemaBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        // Schema structure will be added by transformer
        // Just build the changeset and other functions
        for (func in funcFields) {
            if (func.expr() != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                statements.push(makeAST(EDef(funcName, [], null, makeAST(ENil))));
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build body for OTP Application modules
     */
    static function buildApplicationBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        // Application callbacks will be handled by transformer
        for (func in funcFields) {
            if (func.expr() != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                statements.push(makeAST(EDef(funcName, [], null, makeAST(ENil))));
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
            statements.push(makeAST(EAttribute(fieldName, makeAST(ENil))));
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