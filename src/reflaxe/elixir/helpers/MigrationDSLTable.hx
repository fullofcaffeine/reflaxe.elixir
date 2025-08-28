package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

/**
 * Table building functions for MigrationDSL - Part 2 of split
 * Split to avoid Haxe compiler hang with >153 lines in macro blocks
 */
class MigrationDSLTable {
    
    /**
     * Create a table with columns defined via callback
     */
    public static function createTable(tableName: String, callback: TableBuilder -> Void): String {
        var sanitized = MigrationDSLCore.sanitizeIdentifier(tableName);
        var builder = new TableBuilder(sanitized);
        callback(builder);
        return builder.build();
    }
    
    /**
     * Compile table creation with columns
     */
    public static function compileTableCreation(tableName: String, columns: Array<String>): String {
        var columnDefs = new Array<String>();
        
        for (column in columns) {
            var parts = column.split(":");
            var name = parts[0];
            var type = parts.length > 1 ? parts[1] : "string";
            columnDefs.push('      add :${name}, :${type}');
        }
        
        var sb = new StringBuf();
        sb.add('create table(:${tableName}) do\n');
        sb.add(columnDefs.join('\n'));
        sb.add('\n');
        sb.add('      timestamps()\n');
        sb.add('    end');
        
        return sb.toString();
    }
    
    /**
     * Alter an existing table
     */
    public static function alterTable(tableName: String, callback: TableBuilder -> Void): String {
        var sanitized = MigrationDSLCore.sanitizeIdentifier(tableName);
        var builder = new TableBuilder(sanitized, true);
        callback(builder);
        return builder.build();
    }
    
    /**
     * Drop a table
     */
    public static function dropTable(tableName: String): String {
        var sanitized = MigrationDSLCore.sanitizeIdentifier(tableName);
        return 'drop table(:${sanitized})';
    }
    
    /**
     * Create an index
     */
    public static function createIndex(tableName: String, columns: Array<String>, ?name: String, ?unique: Bool = false): String {
        var sanitized = MigrationDSLCore.sanitizeIdentifier(tableName);
        var columnList = columns.map(function(c) return ':' + MigrationDSLCore.sanitizeIdentifier(c));
        var indexName = name != null ? name : '${sanitized}_${columns.join("_")}_index';
        
        var opts = [];
        if (unique) opts.push("unique: true");
        if (name != null) opts.push('name: "${indexName}"');
        
        var optsStr = opts.length > 0 ? ', ${opts.join(", ")}' : '';
        return 'create index(:${sanitized}, [${columnList.join(", ")}]${optsStr})';
    }
    
    /**
     * Drop an index
     */
    public static function dropIndex(tableName: String, ?columns: Array<String>, ?name: String): String {
        var sanitized = MigrationDSLCore.sanitizeIdentifier(tableName);
        
        if (name != null) {
            return 'drop index(:${sanitized}, name: "${name}")';
        } else if (columns != null) {
            var columnList = columns.map(function(c) return ':' + MigrationDSLCore.sanitizeIdentifier(c));
            return 'drop index(:${sanitized}, [${columnList.join(", ")}])';
        }
        
        return 'drop index(:${sanitized})';
    }
    
    /**
     * Execute raw SQL
     */
    public static function execute(sql: String): String {
        // Escape quotes in SQL
        var escaped = sql.split('"').join('\\"');
        return 'execute "${escaped}"';
    }
}

/**
 * TableBuilder class for fluent API
 * Simplified version to stay under line limit
 */
class TableBuilder {
    var tableName: String;
    var isAlter: Bool;
    var columns: Array<String>;
    var indexes: Array<String>;
    var constraints: Array<String>;
    
    public function new(tableName: String, ?isAlter: Bool = false) {
        this.tableName = tableName;
        this.isAlter = isAlter;
        this.columns = [];
        this.indexes = [];
        this.constraints = [];
    }
    
    public function addColumn(name: String, type: String, ?opts: Dynamic): TableBuilder {
        var sanitizedName = MigrationDSLCore.sanitizeIdentifier(name);
        columns.push('add :${sanitizedName}, :${type}');
        return this;
    }
    
    public function timestamps(): TableBuilder {
        columns.push("timestamps()");
        return this;
    }
    
    public function build(): String {
        var verb = isAlter ? "alter" : "create";
        var sb = new StringBuf();
        sb.add('${verb} table(:${tableName}) do\n');
        for (col in columns) {
            sb.add('      ${col}\n');
        }
        sb.add('    end');
        return sb.toString();
    }
}

#end