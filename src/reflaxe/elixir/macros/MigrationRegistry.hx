package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * Column information
 */
typedef ColumnInfo = {
    var name: String;
    var type: String;  // String representation of the ColumnType
    var nullable: Bool;
    var sourcePos: Position;  // Where this column was defined
}

/**
 * Table schema information
 */
typedef TableSchema = {
    var name: String;
    var columns: Map<String, ColumnInfo>;
    var sourcePos: Position;  // Where this table was defined (for error messages)
}

/**
 * MigrationRegistry: Compile-time tracking of database schema for validation
 * 
 * WHY: Catch database schema errors at compile-time instead of runtime
 * - Validate that referenced tables exist before generating foreign keys
 * - Ensure indexed columns are actually defined in the table
 * - Prevent typos in table/column names from causing runtime Ecto errors
 * - Provide autocomplete support through typed references
 * 
 * WHAT: A compile-time registry of all tables and columns defined in migrations
 * - Tracks table names and their columns as migrations are compiled
 * - Validates foreign key references point to existing tables
 * - Checks that indexed columns exist in their tables
 * - Provides clear compile errors with suggestions for typos
 * 
 * HOW: Macro-based registration during migration compilation
 * - TableBuilder.createTable() registers new tables
 * - TableBuilder.addColumn() registers columns with their types
 * - Foreign key and index operations validate against the registry
 * - All validation happens at compile-time, zero runtime overhead
 * 
 * ## Example Error Messages
 * 
 * ```
 * Migration.hx:15: Error: Cannot add foreign key to non-existent table "userz"
 * Did you mean "users"? Available tables: [users, posts, comments]
 * 
 * Migration.hx:20: Error: Cannot index non-existent column "emial" in table "users"
 * Did you mean "email"? Available columns: [id, name, email, created_at, updated_at]
 * ```
 */
class MigrationRegistry {
    
    /**
     * Global registry of all tables defined in migrations
     * Static so it persists across macro calls during compilation
     */
    static var tables: Map<String, TableSchema> = new Map();
    
    /**
     * Register a new table in the migration registry
     * 
     * @param name The table name
     * @param pos Source position for error reporting
     */
    public static function registerTable(name: String, pos: Position): Void {
        #if debug_migration_registry
        #if debug_migration trace('[MigrationRegistry] Registering table: $name'); #end
        #end
        
        if (tables.exists(name)) {
            Context.warning('Table "$name" is already defined. Overwriting previous definition.', pos);
        }
        
        tables.set(name, {
            name: name,
            columns: new Map(),
            sourcePos: pos
        });
    }

    /**
     * Unregister a table (e.g. when handling drop operations).
     *
     * This is primarily used by validation macros to keep the registry aligned
     * with the migration's up/down flow during analysis.
     */
    public static function unregisterTable(name: String): Void {
        tables.remove(name);
    }
    
    /**
     * Register a column in a table
     * 
     * @param tableName The table this column belongs to
     * @param columnName The column name
     * @param columnType String representation of the column type
     * @param nullable Whether the column allows nulls
     * @param pos Source position for error reporting
     */
    public static function registerColumn(tableName: String, columnName: String, 
                                         columnType: String, nullable: Bool, pos: Position): Void {
        #if debug_migration_registry
        #if debug_migration trace('[MigrationRegistry] Registering column: $tableName.$columnName ($columnType)'); #end
        #end
        
        if (!tables.exists(tableName)) {
            Context.error('Cannot add column to non-existent table "$tableName"', pos);
            return;
        }
        
        var table = tables.get(tableName);
        if (table.columns.exists(columnName)) {
            Context.warning('Column "$columnName" already exists in table "$tableName"', pos);
        }
        
        table.columns.set(columnName, {
            name: columnName,
            type: columnType,
            nullable: nullable,
            sourcePos: pos
        });
    }
    
    /**
     * Validate that a table exists
     * 
     * @param tableName The table to check
     * @param pos Source position for error reporting
     * @return True if table exists, false otherwise (after reporting error)
     */
    public static function validateTableExists(tableName: String, pos: Position): Bool {
        if (!tables.exists(tableName)) {
            var availableTables = [for (t in tables.keys()) t];
            var suggestion = findClosestMatch(tableName, availableTables);
            
            var errorMsg = 'Table "$tableName" does not exist.';
            if (suggestion != null) {
                errorMsg += ' Did you mean "$suggestion"?';
            }
            if (availableTables.length > 0) {
                errorMsg += ' Available tables: [${availableTables.join(", ")}]';
            } else {
                errorMsg += ' No tables have been defined yet.';
            }
            
            Context.error(errorMsg, pos);
            return false;
        }
        return true;
    }
    
    /**
     * Validate that a column exists in a table
     * 
     * @param tableName The table to check
     * @param columnName The column to check
     * @param pos Source position for error reporting
     * @return True if column exists, false otherwise (after reporting error)
     */
    public static function validateColumnExists(tableName: String, columnName: String, pos: Position): Bool {
        if (!validateTableExists(tableName, pos)) {
            return false;
        }
        
        var table = tables.get(tableName);
        if (!table.columns.exists(columnName)) {
            var availableColumns = [for (c in table.columns.keys()) c];
            var suggestion = findClosestMatch(columnName, availableColumns);
            
            var errorMsg = 'Column "$columnName" does not exist in table "$tableName".';
            if (suggestion != null) {
                errorMsg += ' Did you mean "$suggestion"?';
            }
            if (availableColumns.length > 0) {
                errorMsg += ' Available columns: [${availableColumns.join(", ")}]';
            } else {
                errorMsg += ' No columns have been defined for this table yet.';
            }
            
            Context.error(errorMsg, pos);
            return false;
        }
        return true;
    }
    
    /**
     * Validate that all columns in a list exist in a table
     * 
     * @param tableName The table to check
     * @param columnNames The columns to validate
     * @param pos Source position for error reporting
     * @return True if all columns exist, false otherwise
     */
    public static function validateColumnsExist(tableName: String, columnNames: Array<String>, pos: Position): Bool {
        var allValid = true;
        for (column in columnNames) {
            if (!validateColumnExists(tableName, column, pos)) {
                allValid = false;
            }
        }
        return allValid;
    }
    
    /**
     * Find the closest matching string from a list (for typo suggestions)
     * Uses Levenshtein distance algorithm
     * 
     * @param input The string to match
     * @param candidates List of possible matches
     * @return The closest match if within reasonable distance, null otherwise
     */
    static function findClosestMatch(input: String, candidates: Array<String>): Null<String> {
        if (candidates.length == 0) return null;
        
        var bestMatch: String = null;
        var bestDistance = 999;
        
        for (candidate in candidates) {
            var distance = levenshteinDistance(input.toLowerCase(), candidate.toLowerCase());
            
            // Only suggest if the distance is reasonable (less than half the length)
            if (distance < bestDistance && distance <= Math.ceil(input.length / 2)) {
                bestDistance = distance;
                bestMatch = candidate;
            }
        }
        
        return bestMatch;
    }
    
    /**
     * Calculate Levenshtein distance between two strings
     * (Minimum number of single-character edits required to change one string into another)
     */
    static function levenshteinDistance(s1: String, s2: String): Int {
        var len1 = s1.length;
        var len2 = s2.length;
        
        if (len1 == 0) return len2;
        if (len2 == 0) return len1;
        
        var matrix = [];
        for (i in 0...len1 + 1) {
            matrix[i] = [for (j in 0...len2 + 1) 0];
        }
        
        for (i in 0...len1 + 1) matrix[i][0] = i;
        for (j in 0...len2 + 1) matrix[0][j] = j;
        
        for (i in 1...len1 + 1) {
            for (j in 1...len2 + 1) {
                var cost = (s1.charAt(i - 1) == s2.charAt(j - 1)) ? 0 : 1;
                matrix[i][j] = Math.floor(Math.min(
                    matrix[i - 1][j] + 1,      // deletion
                    Math.min(
                        matrix[i][j - 1] + 1,   // insertion
                        matrix[i - 1][j - 1] + cost  // substitution
                    )
                ));
            }
        }
        
        return matrix[len1][len2];
    }
    
    /**
     * Clear the registry (useful for testing)
     */
    public static function clear(): Void {
        tables = new Map();
    }
    
    /**
     * Get a summary of all registered tables (for debugging)
     */
    public static function getSummary(): String {
        var lines = ['Migration Registry Summary:'];
        for (tableName in tables.keys()) {
            var table = tables.get(tableName);
            lines.push('  Table: $tableName');
            for (column in table.columns) {
                lines.push('    - ${column.name}: ${column.type}${column.nullable ? " (nullable)" : ""}');
            }
        }
        return lines.join('\n');
    }
}
#end
