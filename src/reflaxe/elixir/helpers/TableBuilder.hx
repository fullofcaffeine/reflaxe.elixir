package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

/**
 * Table builder class for DSL-style migration creation
 * Provides fluent interface for defining table structure
 */
class TableBuilder {
    public var tableName(default, null): String;
    public var hasIdColumn(default, null): Bool;
    public var hasTimestamps(default, null): Bool;
    
    private var columns: Array<String>;
    private var indexes: Array<String>;
    private var constraints: Array<String>;
    
    public function new(tableName: String) {
        this.tableName = tableName;
        // Initialize all fields in constructor to avoid macro-time issues
        this.hasIdColumn = false;
        this.hasTimestamps = false;
        this.columns = [];
        this.indexes = [];
        this.constraints = [];
    }
    
    /**
     * Add a column to the table
     */
    public function addColumn(name: String, dataType: String, ?options: Dynamic): TableBuilder {
        // Check for special columns
        if (name == "id") {
            hasIdColumn = true;
        }
        
        if (name == "inserted_at" || name == "updated_at") {
            hasTimestamps = true;
        }
        
        var optionsStr = "";
        
        if (options != null) {
            var opts = [];
            var fields = Reflect.fields(options);
            
            for (field in fields) {
                var value = Reflect.field(options, field);
                
                // Handle special option names
                var optName = switch (field) {
                    case "null": "null";
                    case "default": "default";
                    case "primaryKey": "primary_key";
                    default: field;
                };
                
                if (Std.isOfType(value, String)) {
                    opts.push('${optName}: "${value}"');
                } else if (Std.isOfType(value, Bool)) {
                    opts.push('${optName}: ${value}');
                } else {
                    opts.push('${optName}: ${value}');
                }
            }
            
            if (opts.length > 0) {
                optionsStr = ', ${opts.join(", ")}';
            }
        }
        
        columns.push('      add :${name}, :${dataType}${optionsStr}');
        return this;
    }
    
    /**
     * Add an index to the table
     */
    public function addIndex(columnNames: Array<String>, ?options: Dynamic): TableBuilder {
        var columnList = columnNames.map(col -> ':${col}').join(", ");
        
        if (options != null && Reflect.hasField(options, "unique") && Reflect.field(options, "unique") == true) {
            indexes.push('    create unique_index(:${tableName}, [${columnList}])');
        } else {
            indexes.push('    create index(:${tableName}, [${columnList}])');
        }
        
        return this;
    }
    
    /**
     * Add a foreign key constraint
     */
    public function addForeignKey(columnName: String, referencedTable: String, referencedColumn: String = "id"): TableBuilder {
        var newColumns = [];
        
        for (col in columns) {
            newColumns.push(col);
            if (col.indexOf('add :${columnName}') != -1) {
                newColumns.push('      references(:${referencedTable}, column: :${referencedColumn})');
            }
        }
        
        columns = newColumns;
        return this;
    }
    
    /**
     * Add timestamps() to the table
     */
    public function timestamps(): TableBuilder {
        hasTimestamps = true;
        return this;
    }
    
    /**
     * Add a check constraint
     */
    public function addCheckConstraint(condition: String, constraintName: String): TableBuilder {
        constraints.push('    create constraint(:${tableName}, :${constraintName}, check: "${condition}")');
        return this;
    }
    
    /**
     * Get all column definitions
     */
    public function getColumnDefinitions(): Array<String> {
        return columns.copy();
    }
    
    /**
     * Get all index definitions
     */
    public function getIndexDefinitions(): Array<String> {
        return indexes.copy();
    }
    
    /**
     * Get all constraint definitions
     */
    public function getConstraintDefinitions(): Array<String> {
        return constraints.copy();
    }
}

#end