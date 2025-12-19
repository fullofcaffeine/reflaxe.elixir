package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
import sys.io.File;

/**
 * Macro to synchronize migrations with schema types
 * 
 * Automatically generates or updates schema types based on migration definitions,
 * ensuring type safety between database structure and application code.
 * 
 * ## How It Works
 * 
 * 1. Scans migration files at compile time
 * 2. Extracts table and column definitions
 * 3. Generates or updates corresponding schema types
 * 4. Provides typed field access for queries
 * 
 * ## Usage
 * 
 * ```haxe
 * // In your schema file
 * @:syncWithMigration("CreateTodos")
 * @:schema
 * class Todo {
 *     // Fields will be auto-generated/updated from migration
 * }
 * ```
 * 
 * ## Benefits
 * 
 * - **Single source of truth**: Migrations define the database structure
 * - **Automatic sync**: Schema types update when migrations change
 * - **Type safety**: Compile-time validation of field access
 * - **No manual sync**: Never manually update schemas after migrations
 */
class MigrationSyncMacro {
    
    /**
     * Build macro that syncs schema with migration
     */
    public static macro function build(): Array<Field> {
        var fields = Context.getBuildFields();
        var classType = Context.getLocalClass().get();
        
        // Check for @:syncWithMigration metadata
        var migrationMeta = classType.meta.extract(":syncWithMigration");
        if (migrationMeta.length == 0) {
            return fields; // No sync requested
        }
        
        // Get migration name
        var migrationName = switch(migrationMeta[0].params[0]) {
            case {expr: EConst(CString(s))}: s;
            default: 
                Context.error("@:syncWithMigration requires a migration name", classType.pos);
                return fields;
        };
        
        // Find and parse migration file
        var migrationData = parseMigration(migrationName);
        if (migrationData == null) {
            Context.warning('Migration ${migrationName} not found', classType.pos);
            return fields;
        }
        
        // Generate fields from migration data
        var generatedFields = generateSchemaFields(migrationData);
        
        // Merge with existing fields (preserve custom methods)
        return mergeFields(fields, generatedFields);
    }
    
    /**
     * Parse a migration file to extract table structure
     */
    static function parseMigration(name: String): MigrationData {
        // Look for migration file
        var paths = [
            'src_haxe/server/migrations/${name}.hx',
            'src_haxe/migrations/${name}.hx',
            'migrations/${name}.hx'
        ];
        
        var content: String = null;
        for (path in paths) {
            if (FileSystem.exists(path)) {
                content = File.getContent(path);
                break;
            }
        }
        
        if (content == null) return null;
        
        // Parse migration content
        var data: MigrationData = {
            tableName: null,
            columns: []
        };
        
        // Extract table name from createTable() call
        var tableRegex = ~/createTable\s*\(\s*"([^"]+)"\s*\)/;
        if (tableRegex.match(content)) {
            data.tableName = tableRegex.matched(1);
        }
        
        // Extract column definitions
        var columnRegex = ~/\.addColumn\s*\(\s*"([^"]+)"\s*,\s*([^,\)]+)(?:\s*,\s*(\{[^\}]*\}))?\s*\)/g;
        while (columnRegex.match(content)) {
            var column: ColumnData = {
                name: columnRegex.matched(1),
                type: parseColumnType(columnRegex.matched(2)),
                options: parseColumnOptions(columnRegex.matched(3))
            };
            data.columns.push(column);
            
            // Continue searching
            content = columnRegex.matchedRight();
        }
        
        // Check for timestamps
        if (content.indexOf(".addTimestamps()") > -1) {
            data.columns.push({
                name: "inserted_at",
                type: "DateTime",
                options: {nullable: false}
            });
            data.columns.push({
                name: "updated_at",
                type: "DateTime",
                options: {nullable: false}
            });
        }
        
        return data;
    }
    
    /**
     * Parse column type from migration
     */
    static function parseColumnType(typeStr: String): String {
        typeStr = StringTools.trim(typeStr);
        
        // Map migration types to Haxe types
        return switch(typeStr) {
            case "String()" | "String": "String";
            case "Text": "String";
            case "Integer": "Int";
            case "BigInteger": "haxe.Int64";
            case "Float": "Float";
            case "Boolean": "Bool";
            case "Date" | "DateTime" | "Timestamp": "Date";
            case "UUID": "String";
            case "Json" | "JsonArray": "elixir.types.Term";
            case "Binary": "haxe.io.Bytes";
            default: "elixir.types.Term";
        };
    }
    
    /**
     * Parse column options
     */
    static function parseColumnOptions(optionsStr: String): ColumnOptions {
        if (optionsStr == null) return {};
        
        var options: ColumnOptions = {};
        
        if (optionsStr.indexOf("nullable: false") > -1) {
            options.nullable = false;
        }
        
        if (optionsStr.indexOf("primaryKey: true") > -1) {
            options.primaryKey = true;
        }
        
        // Extract default value
        var defaultRegex = ~/defaultValue:\s*([^,\}]+)/;
        if (defaultRegex.match(optionsStr)) {
            options.defaultValue = defaultRegex.matched(1);
        }
        
        return options;
    }
    
    /**
     * Generate schema fields from migration data
     */
    static function generateSchemaFields(data: MigrationData): Array<Field> {
        var fields: Array<Field> = [];
        
        // Add ID field if not present
        var hasId = false;
        for (col in data.columns) {
            if (col.name == "id") {
                hasId = true;
                break;
            }
        }
        
        if (!hasId) {
            fields.push({
                name: "id",
                pos: Context.currentPos(),
                kind: FVar(macro: Int, null),
                access: [APublic],
                meta: [{name: ":primary_key", pos: Context.currentPos()}]
            });
        }
        
        // Generate fields for each column
        for (col in data.columns) {
            var fieldType = switch(col.type) {
                case "String": macro: String;
                case "Int": macro: Int;
                case "Float": macro: Float;
                case "Bool": macro: Bool;
                case "Date": macro: Date;
                case "haxe.Int64": macro: haxe.Int64;
                case "haxe.io.Bytes": macro: haxe.io.Bytes;
                case "elixir.types.Term": macro: elixir.types.Term;
                default: macro: elixir.types.Term;
            };
            
            // Make nullable if specified
            if (col.options.nullable != false) {
                fieldType = macro: Null<$fieldType>;
            }
            
            var field: Field = {
                name: col.name,
                pos: Context.currentPos(),
                kind: FVar(fieldType, null),
                access: [APublic],
                meta: []
            };
            
            // Add metadata
            if (col.options.primaryKey) {
                field.meta.push({name: ":primary_key", pos: Context.currentPos()});
            }
            
            if (col.options.defaultValue != null) {
                field.meta.push({
                    name: ":default",
                    params: [macro $v{col.options.defaultValue}],
                    pos: Context.currentPos()
                });
            }
            
            fields.push(field);
        }
        
        // Add changeset function
        fields.push({
            name: "changeset",
            pos: Context.currentPos(),
            kind: FFun({
                args: [
                    {name: "params", type: macro: elixir.types.Term}
                ],
                ret: macro: ecto.Changeset<$p{[data.tableName]}, elixir.types.Term>,
                expr: macro {
                    return new ecto.Changeset(this, params);
                }
            }),
            access: [APublic],
            meta: []
        });
        
        return fields;
    }
    
    /**
     * Merge generated fields with existing ones
     */
    static function mergeFields(existing: Array<Field>, generated: Array<Field>): Array<Field> {
        var result: Array<Field> = [];
        var processedNames = new Map<String, Bool>();
        
        // Keep custom methods and non-field members
        for (field in existing) {
            switch(field.kind) {
                case FFun(_):
                    // Keep all functions except changeset (we regenerate that)
                    if (field.name != "changeset") {
                        result.push(field);
                        processedNames.set(field.name, true);
                    }
                default:
                    // Field will be regenerated from migration
            }
        }
        
        // Add all generated fields
        for (field in generated) {
            if (!processedNames.exists(field.name)) {
                result.push(field);
            }
        }
        
        return result;
    }
}

// Type definitions
typedef MigrationData = {
    var tableName: String;
    var columns: Array<ColumnData>;
}

typedef ColumnData = {
    var name: String;
    var type: String;
    var options: ColumnOptions;
}

typedef ColumnOptions = {
    @:optional var nullable: Bool;
    @:optional var primaryKey: Bool;
    @:optional var defaultValue: String;
}

#end
