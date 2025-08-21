package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;

using StringTools;
using reflaxe.helpers.NameMetaHelper;

/**
 * Unified annotation detection, validation, and routing system
 * 
 * Provides:
 * - Centralized annotation detection across all compiler helpers
 * - Annotation validation and conflict resolution
 * - Priority-based compilation routing
 * - Comprehensive error reporting for annotation issues
 */
class AnnotationSystem {
    
    /**
     * Global registry for app name discovered during compilation
     * This allows any class to contribute the app name for the entire project
     */
    private static var globalAppNameRegistry: Null<String> = null;
    
    /**
     * All supported annotations in priority order (first match wins)
     */
    public static var SUPPORTED_ANNOTATIONS = [
        ":genserver",        // OTP GenServer - highest priority for behavior classes
        ":controller",       // Phoenix Controller with routing
        ":router",           // Phoenix Router configuration
        ":endpoint",         // Phoenix Endpoint configuration
        ":channel",          // Phoenix Channel for real-time communication
        ":behaviour",        // Elixir Behavior definitions
        ":protocol",         // Elixir Protocol definitions
        ":impl",             // Elixir Protocol implementations
        ":repo",             // Ecto Repository configuration
        ":migration",        // Ecto Migration - database schema changes
        ":template",         // Phoenix HEEx templates
        ":component",         // Phoenix UI Components
        ":schema",           // Ecto Schema definitions
        ":changeset",        // Ecto Changeset validation
        ":liveview",         // Phoenix LiveView components
        ":query",            // Ecto Query DSL (future implementation)
        ":appName"           // Application name configuration (compatible with all)
    ];
    
    /**
     * Mutually exclusive annotation groups
     * Classes cannot have multiple annotations from the same group
     */
    public static var EXCLUSIVE_GROUPS = [
        [":genserver", ":liveview", ":channel"], // Behavior vs Component vs Channel
        [":schema", ":changeset"],               // Data vs Validation
        [":migration", ":schema", ":changeset"]  // Migration vs Runtime
    ];
    
    /**
     * Compatible annotation combinations
     * These annotations can coexist on the same class
     */
    public static var COMPATIBLE_COMBINATIONS = [
        [":liveview", ":template"],    // LiveView can use templates
        [":schema", ":query"],         // Schema can have query methods
        [":changeset", ":query"],      // Changeset can have query methods
        [":appName"]                   // :appName is compatible with any other annotation
    ];
    
    /**
     * Detect all annotations on a class type
     */
    public static function detectAnnotations(classType: ClassType): AnnotationInfo {
        if (classType == null) {
            return {
                annotations: [],
                primaryAnnotation: null,
                hasConflicts: false,
                conflicts: [],
                isSupported: false
            };
        }
        
        var detectedAnnotations = [];
        
        // Check for all supported annotations
        for (annotation in SUPPORTED_ANNOTATIONS) {
            if (classType.meta.has(annotation)) {
                detectedAnnotations.push(annotation);
            }
        }
        
        // Validate annotations
        var conflicts = validateAnnotations(detectedAnnotations);
        var primaryAnnotation = determinePrimaryAnnotation(detectedAnnotations);
        
        return {
            annotations: detectedAnnotations,
            primaryAnnotation: primaryAnnotation,
            hasConflicts: conflicts.length > 0,
            conflicts: conflicts,
            isSupported: detectedAnnotations.length > 0
        };
    }
    
    /**
     * Validate annotation combinations for conflicts
     */
    static function validateAnnotations(annotations: Array<String>): Array<AnnotationConflict> {
        var conflicts = [];
        
        // Check exclusive groups
        for (group in EXCLUSIVE_GROUPS) {
            var foundInGroup = [];
            for (annotation in annotations) {
                if (group.contains(annotation)) {
                    foundInGroup.push(annotation);
                }
            }
            
            if (foundInGroup.length > 1) {
                conflicts.push({
                    type: "exclusive_group",
                    conflicting: foundInGroup,
                    message: 'Annotations ${foundInGroup.join(", ")} cannot be used together - they are mutually exclusive'
                });
            }
        }
        
        // Check for unsupported combinations
        if (annotations.length > 1) {
            var hasValidCombination = false;
            
            // :appName is compatible with everything
            if (annotations.contains(":appName")) {
                hasValidCombination = true;
            } else {
                for (combination in COMPATIBLE_COMBINATIONS) {
                    var matchesAll = true;
                    for (annotation in annotations) {
                        if (!combination.contains(annotation)) {
                            matchesAll = false;
                            break;
                        }
                    }
                    
                    if (matchesAll) {
                        hasValidCombination = true;
                        break;
                    }
                }
                
                // Check if it's a simple single + compatible annotation
                if (!hasValidCombination && annotations.length == 2) {
                    for (combination in COMPATIBLE_COMBINATIONS) {
                        if (combination.contains(annotations[0]) && combination.contains(annotations[1])) {
                            hasValidCombination = true;
                            break;
                        }
                    }
                }
            }
            
            if (!hasValidCombination) {
                conflicts.push({
                    type: "unsupported_combination",
                    conflicting: annotations,
                    message: 'Annotation combination ${annotations.join(", ")} is not supported'
                });
            }
        }
        
        return conflicts;
    }
    
    /**
     * Determine primary annotation based on priority order
     */
    static function determinePrimaryAnnotation(annotations: Array<String>): Null<String> {
        for (annotation in SUPPORTED_ANNOTATIONS) {
            if (annotations.contains(annotation)) {
                return annotation;
            }
        }
        return null;
    }
    
    /**
     * Route to appropriate compiler helper based on primary annotation
     * Returns the compilation result or null if no annotations/default compilation needed
     */
    public static function routeCompilation(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<String> {
        var annotationInfo = detectAnnotations(classType);
        
        // Report conflicts as compilation errors
        if (annotationInfo.hasConflicts) {
            for (conflict in annotationInfo.conflicts) {
                trace("ERROR: " + conflict.message);
                // TODO: Restore Context.error when Context API is fixed
            }
            return null;
        }
        
        // Route to appropriate compiler
        if (annotationInfo.primaryAnnotation == null) {
            return null; // No annotations, use default compilation
        }
        
        return switch (annotationInfo.primaryAnnotation) {
            case ":genserver":
                if (reflaxe.elixir.helpers.OTPCompiler.isGenServerClassType(classType)) {
                    compileGenServerClass(classType, varFields, funcFields);
                } else {
                    trace("ERROR: @:genserver annotation detected but OTPCompiler validation failed");
                    null;
                }
                
            case ":controller":
                if (reflaxe.elixir.helpers.RouterCompiler.isControllerClassType(classType)) {
                    compileControllerClass(classType, varFields, funcFields);
                } else {
                    trace("ERROR: " +"@:controller annotation detected but RouterCompiler validation failed");
                    null;
                }
                
            case ":router":
                if (reflaxe.elixir.helpers.RouterCompiler.isRouterClassType(classType)) {
                    compileRouterClass(classType, varFields, funcFields);
                } else {
                    trace("ERROR: " +"@:router annotation detected but RouterCompiler validation failed");
                    null;
                }
                
            case ":endpoint":
                // Endpoint classes are handled by main ElixirCompiler with framework-aware file placement
                // Return null to let ElixirCompiler handle endpoint compilation
                null;
                
            case ":channel":
                compileChannelClass(classType, varFields, funcFields);
                
            case ":behaviour":
                if (reflaxe.elixir.helpers.BehaviorCompiler.isBehaviorClassType(classType)) {
                    compileBehaviorClass(classType, varFields, funcFields);
                } else {
                    trace("ERROR: " +"@:behaviour annotation detected but BehaviorCompiler validation failed");
                    null;
                }
                
            case ":protocol":
                if (reflaxe.elixir.helpers.ProtocolCompiler.isProtocolClassType(classType)) {
                    compileProtocolClass(classType, varFields, funcFields);
                } else {
                    trace("ERROR: " +"@:protocol annotation detected but ProtocolCompiler validation failed");
                    null;
                }
                
            case ":impl":
                if (reflaxe.elixir.helpers.ProtocolCompiler.isImplClassType(classType)) {
                    compileImplClass(classType, varFields, funcFields);
                } else {
                    trace("ERROR: " +"@:impl annotation detected but ProtocolCompiler validation failed");
                    null;
                }
                
            case ":repo":
                if (reflaxe.elixir.helpers.RepoCompiler.isRepoClass(classType)) {
                    compileRepoClass(classType, varFields, funcFields);
                } else {
                    trace("ERROR: @:repo annotation detected but RepoCompiler validation failed");
                    null;
                }
                
            case ":migration":
                if (reflaxe.elixir.helpers.MigrationDSL.isMigrationClassType(classType)) {
                    compileMigrationClass(classType, varFields, funcFields);
                } else {
                    trace("ERROR: " +"@:migration annotation detected but MigrationDSL validation failed");
                    null;
                }
                
            case ":template":
                if (reflaxe.elixir.helpers.TemplateCompiler.isTemplateClassType(classType)) {
                    compileTemplateClass(classType, varFields, funcFields);
                } else {
                    trace("ERROR: " +"@:template annotation detected but TemplateCompiler validation failed");
                    null;
                }
                
            case ":component":
                compileComponentClass(classType, varFields, funcFields);
                
            case ":schema":
                // Schema compilation is handled directly by ElixirCompiler
                null;
                
            case ":changeset":
                if (reflaxe.elixir.helpers.ChangesetCompiler.isChangesetClassType(classType)) {
                    compileChangesetClass(classType, varFields, funcFields);
                } else {
                    trace("ERROR: " +"@:changeset annotation detected but ChangesetCompiler validation failed");
                    null;
                }
                
            case ":liveview":
                if (reflaxe.elixir.LiveViewCompiler.isLiveViewClassType(classType)) {
                    // Return null to let ElixirCompiler handle LiveView compilation with new architecture
                    null;
                } else {
                    trace("ERROR: " +"@:liveview annotation detected but LiveViewCompiler validation failed");
                    null;
                }
                
            case ":query":
                // Future implementation - for now, warn user
                trace("WARNING: @:query annotation is not yet implemented. Query methods will be compiled as regular functions.");
                null;
                
            case ":appName":
                // @:appName is a configuration annotation, not a compilation target
                // It should be used by other compilers to get app name, but doesn't generate code itself
                null;
                
            default:
                trace('ERROR: Unknown annotation: ${annotationInfo.primaryAnnotation}');
                null;
        };
    }
    
    /**
     * Extract app name from @:appName annotation
     * Searches the class hierarchy for @:appName(value) and returns the value
     */
    public static function getAppName(classType: ClassType): Null<String> {
        if (classType.meta.has(":appName")) {
            // Extract value from @:appName(value) metadata
            var appNameMeta = classType.meta.extract(":appName");
            if (appNameMeta.length > 0) {
                var params = appNameMeta[0].params;
                if (params != null && params.length > 0) {
                    switch (params[0].expr) {
                        case EConst(CString(s, _)):
                            // Register this app name globally for other classes to use
                            globalAppNameRegistry = s;
                            return s;
                        default:
                            trace("WARNING: @:appName annotation must contain a string value. Example: @:appName('MyApp')");
                    }
                } else {
                    trace("WARNING: @:appName annotation requires a value. Example: @:appName('MyApp')");
                }
            }
        }
        
        // Default app name if no annotation found
        return null;
    }
    
    /**
     * Get effective app name - either from annotation or fallback to class name
     */
    public static function getEffectiveAppName(classType: ClassType): String {
        var annotatedName = getAppName(classType);
        if (annotatedName != null) {
            return annotatedName;
        }
        
        // Search for @:appName across all classes in the compilation context
        var globalAppName = getGlobalAppName();
        if (globalAppName != null) {
            return globalAppName;
        }
        
        // Fallback: extract app name from class name (e.g., "TodoApp" from "TodoApp")
        // or use "App" as default
        var className = classType.name;
        if (className.indexOf("App") > 0) {
            return className.split("App")[0] + "App";
        }
        
        return "App"; // Ultimate fallback
    }
    
    /**
     * Get the globally registered app name
     * This returns the app name that was discovered when any class with @:appName was processed
     */
    public static function getGlobalAppName(): Null<String> {
        return globalAppNameRegistry;
    }
    
    /**
     * Generate documentation for annotation usage
     */
    public static function generateAnnotationDocs(): String {
        var result = new StringBuf();
        
        result.add("# Reflaxe.Elixir Annotation Reference\n\n");
        
        result.add("## Supported Annotations\n\n");
        
        for (annotation in SUPPORTED_ANNOTATIONS) {
            result.add('- **${annotation}** - ${getAnnotationDescription(annotation)}\n');
        }
        
        result.add("\n## Annotation Combinations\n\n");
        result.add("### Compatible Combinations:\n");
        for (combination in COMPATIBLE_COMBINATIONS) {
            result.add('- ${combination.join(" + ")}\n');
        }
        
        result.add("\n### Exclusive Groups (mutually exclusive):\n");
        for (group in EXCLUSIVE_GROUPS) {
            result.add('- ${group.join(" | ")} (choose one)\n');
        }
        
        return result.toString();
    }
    
    /**
     * Get human-readable description for annotation
     */
    static function getAnnotationDescription(annotation: String): String {
        return switch (annotation) {
            case ":genserver": "OTP GenServer with lifecycle callbacks";
            case ":router": "Phoenix Router with route definitions";
            case ":endpoint": "Phoenix Endpoint with HTTP configuration";
            case ":protocol": "Elixir protocol for polymorphic dispatch";
            case ":impl": "Protocol implementation for specific types";
            case ":migration": "Ecto database migration with table operations";
            case ":template": "Phoenix HEEx template with component integration";
            case ":schema": "Ecto schema with field definitions and associations";
            case ":changeset": "Ecto changeset with validation pipeline";
            case ":liveview": "Phoenix LiveView with real-time updates";
            case ":component": "Phoenix UI components with type-safe renders";
            case ":query": "Ecto query DSL with type-safe operations";
            case ":appName": "Application name configuration for module naming";
            default: "Unknown annotation";
        };
    }
    
    // Forward declarations for compiler methods (these should be implemented in ElixirCompiler)
    static function compileGenServerClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.helpers.OTPCompiler.getGenServerConfig(classType);
        return reflaxe.elixir.helpers.OTPCompiler.compileFullGenServer({
            className: className,
            initialState: "%{}",
            callMethods: [],
            castMethods: []
        });
    }
    
    static function compileControllerClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        return reflaxe.elixir.helpers.RouterCompiler.compileController(classType);
    }
    
    static function compileRouterClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        return reflaxe.elixir.helpers.RouterCompiler.compileRouter(classType);
    }
    
    static function compileChannelClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        return reflaxe.elixir.helpers.ChannelCompiler.compileChannel(classType, "");
    }
    
    static function compileBehaviorClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        return reflaxe.elixir.helpers.BehaviorCompiler.compileBehavior(classType);
    }
    
    static function compileProtocolClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        return reflaxe.elixir.helpers.ProtocolCompiler.compileProtocol(classType);
    }
    
    static function compileImplClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        return reflaxe.elixir.helpers.ProtocolCompiler.compileImplementation(classType);
    }
    
    static function compileRepoClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.getNameOrNative();
        return reflaxe.elixir.helpers.RepoCompiler.compileRepoModule(classType, className);
    }
    
    static function compileMigrationClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.helpers.MigrationDSL.getMigrationConfig(classType);
        var tableName = config.table != null ? config.table : "default_table";
        
        // Extract columns from class variables
        var columns = varFields.map(field -> '${field.field.name}:string');
        
        return reflaxe.elixir.helpers.MigrationDSL.compileFullMigration({
            className: className,
            timestamp: config.timestamp,
            tableName: tableName,
            columns: columns
        });
    }
    
    static function compileTemplateClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.helpers.TemplateCompiler.getTemplateConfig(classType);
        return reflaxe.elixir.helpers.TemplateCompiler.compileFullTemplate(className, config);
    }
    
    /**
     * Compile Phoenix component class with @:component annotations
     * 
     * Processes functions marked with @:component and generates Phoenix.Component
     * function definitions with proper attr/slot metadata.
     */
    static function compileComponentClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var moduleName = classType.getNameOrNative();
        var result = new StringBuf();
        
        // Generate module header
        result.add('defmodule ${moduleName} do\n');
        result.add('  @moduledoc """\n');
        result.add('  Core UI components for Phoenix applications.\n');
        result.add('  \n');
        result.add('  Generated from Haxe CoreComponents with type safety and consistent styling.\n');
        result.add('  """\n');
        result.add('  use Phoenix.Component\n\n');
        
        // Process each function marked with @:component
        for (funcField in funcFields) {
            if (funcField.field.meta != null && funcField.field.meta.has(":component")) {
                var componentCode = compileComponentFunction(funcField, classType);
                result.add(componentCode);
                result.add('\n');
            }
        }
        
        result.add('end\n');
        return result.toString();
    }
    
    /**
     * Compile individual component function with attr/slot metadata
     */
    static function compileComponentFunction(funcField: ClassFuncData, classType: ClassType): String {
        var funcName = funcField.field.name;
        var result = new StringBuf();
        
        // Extract @:attr and @:slot annotations
        var attributes = extractComponentAttributes(funcField.field.meta);
        var slots = extractComponentSlots(funcField.field.meta);
        
        // Generate attr declarations
        for (attr in attributes) {
            result.add('  attr :${attr.name}, :${attr.type}');
            if (attr.required) {
                result.add(', required: true');
            } else if (attr.defaultValue != null) {
                result.add(', default: ${attr.defaultValue}');
            }
            result.add('\n');
        }
        
        // Generate slot declarations
        for (slot in slots) {
            result.add('  slot :${slot.name}');
            if (slot.required) {
                result.add(', required: true');
            }
            result.add('\n');
        }
        
        // Generate function definition
        result.add('  def ${funcName}(assigns) do\n');
        
        // Extract HXX AST from function body and compile through HxxCompiler
        if (funcField.expr != null) {
            var hxxTemplate = reflaxe.elixir.helpers.HxxCompiler.compileHxxTemplate(funcField.expr);
            result.add('    ${hxxTemplate}\n');
        } else {
            // Fallback if no function body
            result.add('    ~H"""\n    <div></div>\n    """\n');
        }
        result.add('  end\n');
        
        return result.toString();
    }
    
    
    /**
     * Extract @:attr annotations from function metadata
     */
    static function extractComponentAttributes(meta: Null<MetaAccess>): Array<ComponentAttribute> {
        var attributes = [];
        if (meta == null) return attributes;
        
        var attrMeta = meta.extract(":attr");
        for (attr in attrMeta) {
            if (attr.params != null && attr.params.length >= 2) {
                var name = extractStringParam(attr.params[0]);
                var type = extractStringParam(attr.params[1]);
                var options = attr.params.length > 2 ? attr.params[2] : null;
                
                var attribute: ComponentAttribute = {
                    name: name,
                    type: type,
                    required: false,
                    defaultValue: null
                };
                
                // Parse options object
                if (options != null) {
                    switch (options.expr) {
                        case EObjectDecl(fields):
                            for (field in fields) {
                                switch (field.field) {
                                    case "required":
                                        attribute.required = extractBoolParam(field.expr);
                                    case "default":
                                        attribute.defaultValue = extractValueParam(field.expr);
                                }
                            }
                        case _:
                    }
                }
                
                attributes.push(attribute);
            }
        }
        
        return attributes;
    }
    
    /**
     * Extract @:slot annotations from function metadata
     */
    static function extractComponentSlots(meta: Null<MetaAccess>): Array<ComponentSlot> {
        var slots = [];
        if (meta == null) return slots;
        
        var slotMeta = meta.extract(":slot");
        for (slot in slotMeta) {
            if (slot.params != null && slot.params.length >= 1) {
                var name = extractStringParam(slot.params[0]);
                var options = slot.params.length > 1 ? slot.params[1] : null;
                
                var slotDef: ComponentSlot = {
                    name: name,
                    required: false
                };
                
                // Parse options
                if (options != null) {
                    switch (options.expr) {
                        case EObjectDecl(fields):
                            for (field in fields) {
                                if (field.field == "required") {
                                    slotDef.required = extractBoolParam(field.expr);
                                }
                            }
                        case _:
                    }
                }
                
                slots.push(slotDef);
            }
        }
        
        return slots;
    }
    
    /**
     * Helper functions for extracting annotation parameters
     */
    static function extractStringParam(expr: Expr): String {
        return switch (expr.expr) {
            case EConst(CString(s, _)): s;
            case _: "";
        };
    }
    
    static function extractBoolParam(expr: Expr): Bool {
        return switch (expr.expr) {
            case EConst(CIdent("true")): true;
            case EConst(CIdent("false")): false;
            case _: false;
        };
    }
    
    static function extractValueParam(expr: Expr): String {
        return switch (expr.expr) {
            case EConst(CString(s, _)): '"${s}"';
            case EConst(CInt(i)): Std.string(i);
            case EConst(CFloat(f)): f;
            case EConst(CIdent("true")): "true";
            case EConst(CIdent("false")): "false";
            case EConst(CIdent("nil")): "nil";
            case _: "nil";
        };
    }
    
    // Schema compilation delegated to SchemaCompiler instance
    // static function compileSchemaClass removed - handled by ElixirCompiler
    
    static function compileChangesetClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.helpers.ChangesetCompiler.getChangesetConfig(classType);
        return reflaxe.elixir.helpers.ChangesetCompiler.compileFullChangeset(className, config.schema);
    }
    
    static function compileLiveViewClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.LiveViewCompiler.getLiveViewConfig(classType);
        return reflaxe.elixir.LiveViewCompiler.compileFullLiveView(className, config, varFields, funcFields);
    }
}

/**
 * Information about annotations detected on a class
 */
typedef AnnotationInfo = {
    annotations: Array<String>,
    primaryAnnotation: Null<String>,
    hasConflicts: Bool,
    conflicts: Array<AnnotationConflict>,
    isSupported: Bool
}

/**
 * Information about annotation conflicts
 */
typedef AnnotationConflict = {
    type: String,
    conflicting: Array<String>,
    message: String
}

/**
 * Component attribute definition for Phoenix components
 */
typedef ComponentAttribute = {
    name: String,
    type: String,
    required: Bool,
    defaultValue: Null<String>
}

/**
 * Component slot definition for Phoenix components
 */
typedef ComponentSlot = {
    name: String,
    required: Bool
}

#end