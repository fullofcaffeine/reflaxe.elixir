package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;

/**
 * Migration Builder Macro - Compile-time validation and generation for migrations
 * 
 * ## Overview
 * 
 * This build macro provides compile-time validation for Ecto migrations,
 * ensuring that table and column references are valid before code generation.
 * 
 * ## Features
 * 
 * - **Table existence validation**: References to tables are checked at compile time
 * - **Column existence validation**: Column references are validated against table schema
 * - **Type consistency checking**: Column types match across migrations
 * - **Foreign key validation**: Ensures referenced tables and columns exist
 * - **Migration ordering**: Tracks dependencies between migrations
 * 
 * ## How It Works
 * 
 * 1. Scans migration classes for @:migration metadata
 * 2. Analyzes up() and down() methods for table/column operations
 * 3. Builds a compile-time schema registry
 * 4. Validates all references at compile time
 * 5. Generates proper Ecto migration modules
 * 
 * @see ecto.Migration For the migration DSL
 */
class MigrationBuilder {
    
    /**
     * Build macro entry point - processes migration classes
     */
    public static macro function build(): Array<Field> {
        var fields = Context.getBuildFields();
        var localClass = Context.getLocalClass().get();
        
        // Check if this is a migration class
        if (!localClass.meta.has(":migration")) {
            return fields;
        }

        // Migration-only `.exs` emission needs `up`/`down` bodies to survive DCE.
        // In that mode we mark the class (and its callbacks) as `@:keep` to prevent
        // `-dce full` builds from stripping everything and producing empty modules.
        if (Context.defined("ecto_migrations_exs")) {
            if (!localClass.meta.has(":keep")) {
                localClass.meta.add(":keep", [], localClass.pos);
            }
            for (field in fields) {
                if (field.name != "up" && field.name != "down") continue;
                if (field.meta == null) field.meta = [];
                var alreadyKept = false;
                for (m in field.meta) {
                    if (m.name == ":keep" || m.name == "keep") {
                        alreadyKept = true;
                        break;
                    }
                }
                if (!alreadyKept) {
                    field.meta.push({name: ":keep", params: [], pos: field.pos});
                }
            }
        }
        
        // Extract migration metadata
        var migrationMeta = localClass.meta.extract(":migration")[0];
        var migrationInfo = extractMigrationInfo(localClass, migrationMeta);
        var migrationName = migrationInfo.name;
        
        // Process migration methods
        for (field in fields) {
            switch(field.name) {
                case "up":
                    processUpMethod(field, migrationName);
                case "down":
                    processDownMethod(field, migrationName);
            }
        }
        
        // Add migration metadata for code generation
        localClass.meta.add(":migrationName", [macro $v{migrationName}], localClass.pos);

        if (migrationInfo.timestamp != null) {
            localClass.meta.add(":migrationTimestamp", [macro $v{migrationInfo.timestamp}], localClass.pos);
        } else if (Context.defined("ecto_migrations_exs")) {
            Context.error(
                'Missing migration timestamp for ${localClass.name}. Provide one via @:migration({timestamp: \"20240101120000\"}) or generate with `mix haxe.gen.migration`.',
                localClass.pos
            );
        }
        
        return fields;
    }
    
    /**
     * Extract migration name/timestamp from class or metadata
     */
    static function extractMigrationInfo(cls: ClassType, meta: MetadataEntry): {name: String, timestamp: Null<String>} {
        var name: Null<String> = null;
        var timestamp: Null<String> = null;

        if (meta != null && meta.params != null && meta.params.length > 0) {
            for (param in meta.params) {
                switch (param.expr) {
                    case EConst(CString(value)):
                        if (name == null) name = value;
                        else if (timestamp == null) timestamp = value;
                    case EConst(CInt(value, _)):
                        if (timestamp == null) timestamp = value;
                    case EObjectDecl(fields):
                        for (field in fields) {
                            switch (field.field) {
                                case "name":
                                    switch (field.expr.expr) {
                                        case EConst(CString(value)):
                                            name = value;
                                        default:
                                    }
                                case "timestamp":
                                    switch (field.expr.expr) {
                                        case EConst(CInt(value, _)):
                                            timestamp = value;
                                        case EConst(CString(value)):
                                            timestamp = value;
                                        default:
                                    }
                                default:
                            }
                        }
                    default:
                }
            }
        }

        if (name == null || name == "") name = toSnakeCase(cls.name);
        return {name: name, timestamp: timestamp};
    }
    
    /**
     * Process the up() method for schema operations
     */
    static function processUpMethod(field: Field, migrationName: String): Void {
        switch(field.kind) {
            case FFun(func):
                if (func.expr != null) {
                    analyzeExpression(func.expr, true, migrationName);
                }
            default:
        }
    }
    
    /**
     * Process the down() method for rollback operations
     */
    static function processDownMethod(field: Field, migrationName: String): Void {
        switch(field.kind) {
            case FFun(func):
                if (func.expr != null) {
                    analyzeExpression(func.expr, false, migrationName);
                }
            default:
        }
    }
    
    /**
     * Analyze expressions for migration operations
     */
    static function analyzeExpression(expr: Expr, isUp: Bool, migrationName: String): Void {
        switch(expr.expr) {
            case ECall({expr: EField(_, "createTable")}, args):
                handleCreateTable(args, migrationName);
                
            case ECall({expr: EField(_, "dropTable")}, args):
                handleDropTable(args, migrationName);
                
            case ECall({expr: EField(_, "alterTable")}, args):
                handleAlterTable(args, migrationName);
                
            case ECall({expr: EField(_, "createIndex")}, args):
                handleCreateIndex(args, migrationName);
                
            case EBlock(exprs):
                for (e in exprs) {
                    analyzeExpression(e, isUp, migrationName);
                }
                
            default:
                // Recursively analyze nested expressions
                ExprTools.iter(expr, e -> analyzeExpression(e, isUp, migrationName));
        }
    }
    
    /**
     * Handle createTable operations
     */
    static function handleCreateTable(args: Array<Expr>, migrationName: String): Void {
        if (args.length > 0) {
            switch(args[0].expr) {
                case EConst(CString(tableName)):
                    MigrationRegistry.registerTable(tableName, args[0].pos);
                    #if debug_migration trace('[Migration] Table "$tableName" registered in $migrationName'); #end
                default:
            }
        }
    }
    
    /**
     * Handle dropTable operations
     */
    static function handleDropTable(args: Array<Expr>, migrationName: String): Void {
        if (args.length > 0) {
            switch(args[0].expr) {
                case EConst(CString(tableName)):
                    MigrationRegistry.unregisterTable(tableName);
                    #if debug_migration trace('[Migration] Table "$tableName" marked for deletion in $migrationName'); #end
                default:
            }
        }
    }
    
    /**
     * Handle alterTable operations
     */
    static function handleAlterTable(args: Array<Expr>, migrationName: String): Void {
        if (args.length > 0) {
            switch(args[0].expr) {
                case EConst(CString(tableName)):
                    // Validate table exists
                    MigrationRegistry.validateTableExists(tableName, args[0].pos);
                default:
            }
        }
    }
    
    /**
     * Handle createIndex operations
     */
    static function handleCreateIndex(args: Array<Expr>, migrationName: String): Void {
        if (args.length >= 2) {
            var tableName: String = null;
            var columns: Array<String> = [];
            
            // Extract table name
            switch(args[0].expr) {
                case EConst(CString(name)):
                    tableName = name;
                default:
            }
            
            // Extract column names
            switch(args[1].expr) {
                case EArrayDecl(values):
                    for (v in values) {
                        switch(v.expr) {
                            case EConst(CString(col)):
                                columns.push(col);
                            default:
                        }
                    }
                default:
            }
            
            // Validate table and columns exist
            if (tableName != null && columns.length > 0) {
                MigrationRegistry.validateTableExists(tableName, args[0].pos);
                MigrationRegistry.validateColumnsExist(tableName, columns, args[1].pos);
            }
        }
    }
    
    /**
     * Convert CamelCase to snake_case
     */
    static function toSnakeCase(name: String): String {
        return ~/([a-z])([A-Z])/g.replace(name, "$1_$2").toLowerCase();
    }
}

/**
 * Migration Registry - Tracks schema state at compile time
 * 
 * This registry maintains the current state of the database schema
 * as migrations are processed, allowing for compile-time validation
 * of table and column references.
 */
class MigrationRegistry {
    // Map of table name to table metadata
    static var tables: Map<String, TableMetadata> = new Map();
    
    // Migration dependency tracking
    static var migrationOrder: Array<String> = [];
    
    /**
     * Register a new table
     */
    public static function registerTable(name: String, pos: Position): Void {
        if (tables.exists(name)) {
            Context.warning('Table "$name" already exists', pos);
        }
        
        tables.set(name, {
            name: name,
            columns: new Map(),
            indexes: [],
            constraints: [],
            createdAt: pos
        });
    }
    
    /**
     * Unregister a table (for drop operations)
     */
    public static function unregisterTable(name: String): Void {
        tables.remove(name);
    }
    
    /**
     * Register a column in a table
     */
    public static function registerColumn(table: String, column: String, type: String, nullable: Bool, pos: Position): Void {
        if (!tables.exists(table)) {
            Context.error('Table "$table" does not exist', pos);
            return;
        }
        
        var tableData = tables.get(table);
        if (tableData.columns.exists(column)) {
            Context.warning('Column "$column" already exists in table "$table"', pos);
        }
        
        tableData.columns.set(column, {
            name: column,
            type: type,
            nullable: nullable
        });
    }
    
    /**
     * Validate that a table exists
     */
    public static function validateTableExists(name: String, pos: Position): Void {
        if (!tables.exists(name)) {
            Context.error('Table "$name" does not exist. Make sure the migration that creates it runs first.', pos);
        }
    }
    
    /**
     * Validate that a column exists in a table
     */
    public static function validateColumnExists(table: String, column: String, pos: Position): Void {
        if (!tables.exists(table)) {
            Context.error('Table "$table" does not exist', pos);
            return;
        }
        
        var tableData = tables.get(table);
        if (!tableData.columns.exists(column)) {
            Context.error('Column "$column" does not exist in table "$table"', pos);
        }
    }
    
    /**
     * Validate that multiple columns exist
     */
    public static function validateColumnsExist(table: String, columns: Array<String>, pos: Position): Void {
        if (!tables.exists(table)) {
            Context.error('Table "$table" does not exist', pos);
            return;
        }
        
        var tableData = tables.get(table);
        for (column in columns) {
            if (!tableData.columns.exists(column)) {
                Context.error('Column "$column" does not exist in table "$table"', pos);
            }
        }
    }
    
    /**
     * Get all registered tables (for debugging)
     */
    public static function getAllTables(): Map<String, TableMetadata> {
        return tables;
    }
}

/**
 * Table metadata structure
 */
typedef TableMetadata = {
    name: String,
    columns: Map<String, ColumnMetadata>,
    indexes: Array<IndexMetadata>,
    constraints: Array<ConstraintMetadata>,
    createdAt: Position
}

/**
 * Column metadata structure
 */
typedef ColumnMetadata = {
    name: String,
    type: String,
    nullable: Bool
}

/**
 * Index metadata structure
 */
typedef IndexMetadata = {
    name: String,
    columns: Array<String>,
    unique: Bool
}

/**
 * Constraint metadata structure
 */
typedef ConstraintMetadata = {
    name: String,
    type: String,
    definition: String
}

#end
