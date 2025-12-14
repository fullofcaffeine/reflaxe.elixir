package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * Schema Registrar - Preserves schema metadata through compilation
 * 
 * ## Overview
 * 
 * This build macro was created following Codex's architectural guidance for a hybrid approach:
 * 1. Collects @:changeset functions during macro phase and stores in a registry
 * 2. Automatically adds @:keep to prevent dead code elimination (DCE)
 * 3. Provides deterministic access to schema metadata for code generation
 * 
 * ## Why This Pattern Was Considered
 * 
 * **The Problem**: Functions marked with @:changeset were being eliminated by Haxe's DCE
 * before reaching the Elixir code generator, because from Haxe's perspective these functions
 * appear unused (they're only called from generated Elixir code).
 * 
 * **Codex's Recommendation**: A hybrid registry + @:keep approach would:
 * - **Deterministic generation**: Registry provides explicit list for codegen
 * - **Preserves semantics**: @:keep ensures functions survive DCE
 * - **Scales well**: Automatic @:keep means contributors don't need to remember
 * - **Minimal bloat**: Only targeted methods are kept, not whole modules
 * 
 * ## Why We Chose a Simpler Approach
 * 
 * After implementing this build macro, we discovered:
 * 
 * 1. **Registry complexity not needed**: We don't require centralized metadata access
 *    since the compiler can detect changesets during AST transformation
 * 
 * 2. **Storage API deprecated**: `Context.registerModuleReuseCall` is deprecated in Haxe 4.3+
 *    making cross-module registry storage problematic
 * 
 * 3. **@:keep alone sufficient**: Simply adding @:keep metadata solves the DCE problem
 *    without the overhead of a full registry system
 * 
 * 4. **Simpler is better**: Less code to maintain, fewer failure points, easier to debug
 * 
 * ## Current Status
 * 
 * **This implementation is preserved for reference** but not actively used. Instead:
 * - Users add @:changeset to mark changeset functions
 * - The compiler detects these during AST transformation
 * - If no changeset exists, a basic one is generated
 * - Users can manually add @:keep if needed (or we could automate this)
 * 
 * ## Lessons Learned
 * 
 * 1. **Start simple**: Try the simplest solution first (@:keep) before complex infrastructure
 * 2. **Validate necessity**: Ensure complex patterns are actually needed before implementing
 * 3. **Consider maintenance**: More complex solutions require more maintenance
 * 4. **Check API stability**: Ensure required APIs aren't deprecated
 * 
 * ## Future Considerations
 * 
 * If we need registry functionality in the future (e.g., for cross-schema validation,
 * dependency analysis, or compile-time relationship checking), this implementation
 * provides a solid foundation. For now, the simpler @:keep approach meets our needs.
 * 
 * @see docs/03-compiler-development/preserving-functions-through-dce.md For detailed comparison
 * @see AnnotationTransforms.schemaTransformPass For current schema emission
 * @see ecto.Schema For schema definitions
 */
class SchemaRegistrar {
    
    /**
     * Registry of schema metadata collected during compilation
     * Key: fully qualified class name
     * Value: schema metadata including changesets, fields, associations
     */
    static var schemaRegistry: Map<String, SchemaMetadata> = new Map();
    
    /**
     * Build macro entry point - processes @:schema classes
     * 
     * @return Modified fields with @:keep metadata added
     */
    public static macro function build(): Array<Field> {
        var fields = Context.getBuildFields();
        var localClass = Context.getLocalClass().get();
        
        // Only process classes with @:schema metadata
        if (!localClass.meta.has(":schema")) {
            return fields;
        }
        
        var className = localClass.pack.concat([localClass.name]).join(".");
        var metadata: SchemaMetadata = {
            className: className,
            moduleName: localClass.name,
            tableName: null,
            changesets: [],
            fields: [],
            associations: [],
            hasTimestamps: localClass.meta.has(":timestamps")
        };
        
        // Extract table name from @:schema metadata if provided
        var schemaMeta = localClass.meta.extract(":schema")[0];
        if (schemaMeta != null && schemaMeta.params != null && schemaMeta.params.length > 0) {
            switch(schemaMeta.params[0].expr) {
                case EConst(CString(table)):
                    metadata.tableName = table;
                default:
            }
        }
        
        // Default table name is pluralized snake_case of class name
        if (metadata.tableName == null) {
            metadata.tableName = pluralizeSnakeCase(localClass.name);
        }
        
        // Process fields to collect metadata and add @:keep
        for (field in fields) {
            processField(field, metadata);
        }
        
        // Store in registry for later access during code generation
        schemaRegistry.set(className, metadata);
        
        return fields;
    }
    
    /**
     * Process individual field for metadata collection
     */
    static function processField(field: Field, metadata: SchemaMetadata): Void {
        // Handle @:changeset functions
        if (field.meta != null) {
            for (meta in field.meta) {
                if (meta.name == ":changeset") {
                    // Add @:keep to prevent DCE
                    field.meta.push({
                        name: ":keep",
                        pos: field.pos
                    });
                    
                    // Extract changeset metadata
                    var changesetInfo: ChangesetInfo = {
                        name: field.name,
                        isStatic: field.access.indexOf(AStatic) != -1,
                        params: extractFunctionParams(field)
                    };
                    
                    metadata.changesets.push(changesetInfo);
                }
                
                // Handle @:field annotations
                if (meta.name == ":field") {
                    var fieldInfo: FieldInfo = {
                        name: field.name,
                        type: extractFieldType(field),
                        defaultValue: extractDefaultValue(field),
                        isRequired: !isNullable(field)
                    };
                    
                    metadata.fields.push(fieldInfo);
                }
                
                // Handle @:belongs_to, @:has_many, @:has_one associations
                if (meta.name == ":belongs_to" || meta.name == ":has_many" || meta.name == ":has_one") {
                    var assocInfo: AssociationInfo = {
                        name: field.name,
                        type: meta.name.substr(1), // Remove leading colon
                        targetSchema: extractAssociationType(field),
                        foreignKey: extractForeignKey(meta)
                    };
                    
                    metadata.associations.push(assocInfo);
                }
            }
        }
    }
    
    /**
     * Extract function parameters for changeset metadata
     */
    static function extractFunctionParams(field: Field): Array<{name: String, type: String}> {
        switch(field.kind) {
            case FFun(func):
                return func.args.map(arg -> {
                    name: arg.name,
                    type: typeToString(arg.type)
                });
            default:
                return [];
        }
    }
    
    /**
     * Extract field type from field definition
     */
    static function extractFieldType(field: Field): String {
        switch(field.kind) {
            case FVar(t, _) | FProp(_, _, t, _):
                return typeToString(t);
            default:
                return "String";
        }
    }
    
    /**
     * Extract default value from field definition
     */
    static function extractDefaultValue(field: Field): Null<String> {
        switch(field.kind) {
            case FVar(_, e) | FProp(_, _, _, e):
                if (e != null) {
                    return exprToString(e);
                }
            default:
        }
        return null;
    }
    
    /**
     * Check if field type is nullable
     */
    static function isNullable(field: Field): Bool {
        switch(field.kind) {
            case FVar(t, _) | FProp(_, _, t, _):
                return switch(t) {
                    case TPath(p): p.name == "Null" || p.name == "Option";
                    default: false;
                }
            default:
                return false;
        }
    }
    
    /**
     * Extract association target type
     */
    static function extractAssociationType(field: Field): String {
        switch(field.kind) {
            case FVar(t, _) | FProp(_, _, t, _):
                return switch(t) {
                    case TPath(p): p.name;
                    default: "Unknown";
                }
            default:
                return "Unknown";
        }
    }
    
    /**
     * Extract foreign key from association metadata
     */
    static function extractForeignKey(meta: MetadataEntry): Null<String> {
        if (meta.params != null && meta.params.length > 0) {
            switch(meta.params[0].expr) {
                case EConst(CString(key)):
                    return key;
                default:
            }
        }
        return null;
    }
    
    /**
     * Convert ComplexType to string representation
     */
    static function typeToString(type: Null<ComplexType>): String {
        if (type == null) return "Dynamic";
        
        return switch(type) {
            case TPath(p):
                var base = p.name;
                if (p.params != null && p.params.length > 0) {
                    var paramStrs = p.params.map(param -> switch(param) {
                        case TPType(t): typeToString(t);
                        default: "?";
                    });
                    base + "<" + paramStrs.join(", ") + ">";
                } else {
                    base;
                }
            default:
                "Dynamic";
        }
    }
    
    /**
     * Convert expression to string representation
     */
    static function exprToString(expr: Expr): String {
        return switch(expr.expr) {
            case EConst(c):
                switch(c) {
                    case CInt(v): v;
                    case CFloat(f): f;
                    case CString(s): '"$s"';
                    case CIdent(i): i;
                    case CRegexp(r, opt): '~/$r/$opt';
                }
            case EArrayDecl(values):
                "[" + values.map(exprToString).join(", ") + "]";
            default:
                "null";
        }
    }
    
    /**
     * Convert class name to pluralized snake_case for table name
     */
    static function pluralizeSnakeCase(name: String): String {
        // Convert CamelCase to snake_case
        var snakeCase = ~/([a-z])([A-Z])/g.replace(name, "$1_$2").toLowerCase();
        
        // Simple pluralization rules
        if (StringTools.endsWith(snakeCase, "y")) {
            return snakeCase.substr(0, snakeCase.length - 1) + "ies";
        } else if (StringTools.endsWith(snakeCase, "s") || StringTools.endsWith(snakeCase, "x") || StringTools.endsWith(snakeCase, "ch")) {
            return snakeCase + "es";
        } else {
            return snakeCase + "s";
        }
    }
    
    /**
     * Retrieve metadata for a schema class (called during code generation)
     * 
     * @param className Fully qualified class name
     * @return Schema metadata or null if not found
     */
    public static function getMetadata(className: String): Null<SchemaMetadata> {
        return schemaRegistry.get(className);
    }
    
    /**
     * Get all registered schemas (useful for cross-schema operations)
     * 
     * @return Map of all schema metadata
     */
    public static function getAllSchemas(): Map<String, SchemaMetadata> {
        return schemaRegistry;
    }
}

/**
 * Schema metadata structure
 */
typedef SchemaMetadata = {
    className: String,
    moduleName: String,
    tableName: String,
    changesets: Array<ChangesetInfo>,
    fields: Array<FieldInfo>,
    associations: Array<AssociationInfo>,
    hasTimestamps: Bool
}

/**
 * Changeset function metadata
 */
typedef ChangesetInfo = {
    name: String,
    isStatic: Bool,
    params: Array<{name: String, type: String}>
}

/**
 * Field metadata
 */
typedef FieldInfo = {
    name: String,
    type: String,
    defaultValue: Null<String>,
    isRequired: Bool
}

/**
 * Association metadata
 */
typedef AssociationInfo = {
    name: String,
    type: String, // belongs_to, has_many, has_one
    targetSchema: String,
    foreignKey: Null<String>
}

#end
