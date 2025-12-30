package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;

typedef MigrationCallStep = {name: String, args: Array<Expr>, pos: Position};

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
        if (analyzeCallChain(expr, isUp, migrationName)) {
            return;
        }

        switch (expr.expr) {
            case ECall({expr: EField(_, "dropTable")}, args):
                handleDropTable(args, migrationName);
            case ECall({expr: EConst(CIdent("dropTable"))}, args):
                handleDropTable(args, migrationName);

            case ECall({expr: EField(_, "alterTable")}, args):
                handleAlterTable(args, migrationName);
            case ECall({expr: EConst(CIdent("alterTable"))}, args):
                handleAlterTable(args, migrationName);

            case ECall({expr: EField(_, "createIndex")}, args):
                handleCreateIndex(args, migrationName);
            case ECall({expr: EConst(CIdent("createIndex"))}, args):
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

    static function analyzeCallChain(expr: Expr, isUp: Bool, migrationName: String): Bool {
        if (!isUp) return false;

        var steps = extractCallChain(expr);
        if (steps == null || steps.length == 0) return false;

        var base = steps[0];
        if (base.name != "createTable") return false;

        handleCreateTableChain(steps, migrationName);
        return true;
    }

    static function extractCallChain(expr: Expr): Null<Array<MigrationCallStep>> {
        var steps: Array<MigrationCallStep> = [];
        var current = expr;

        while (true) {
            switch (current.expr) {
                case ECall({expr: EField(target, methodName)}, args):
                    steps.push({name: methodName, args: args, pos: current.pos});
                    current = target;
                case ECall({expr: EConst(CIdent(methodName))}, args):
                    // Unqualified calls inside a class body (e.g. `createTable("users")`)
                    // are represented as identifier calls, not `this.createTable(...)`.
                    steps.push({name: methodName, args: args, pos: current.pos});
                    break;
                default:
                    break;
            }
        }

        if (steps.length == 0) return null;
        steps.reverse();
        return steps;
    }

    static function handleCreateTableChain(steps: Array<MigrationCallStep>, migrationName: String): Void {
        var base = steps[0];
        var tableName = (base.args.length > 0) ? extractString(base.args[0]) : null;

        if (tableName == null || tableName == "") {
            if (Context.defined("ecto_migrations_exs")) {
                Context.error("createTable table name must be a string literal in ecto_migrations_exs builds.", base.pos);
            }
            return;
        }

        MigrationRegistry.registerTable(tableName, base.pos);
        // Ecto defaults to an `id` primary key unless explicitly disabled.
        MigrationRegistry.registerColumn(tableName, "id", "integer", false, base.pos);

        for (i in 1...steps.length) {
            var step = steps[i];
            switch (step.name) {
                case "addId":
                    if (Context.defined("ecto_migrations_exs") && step.args.length > 0) {
                        Context.error("addId(...) with custom options is not supported in ecto_migrations_exs builds. Use addId() or a manual Elixir migration.", step.pos);
                    }

                case "addTimestamps":
                    MigrationRegistry.registerColumn(tableName, "inserted_at", "naive_datetime", false, step.pos);
                    MigrationRegistry.registerColumn(tableName, "updated_at", "naive_datetime", false, step.pos);

                case "addColumn":
                    if (step.args.length < 2) {
                        Context.error("addColumn expects at least (name, type).", step.pos);
                        continue;
                    }

                    var columnName = extractString(step.args[0]);
                    if (columnName == null || columnName == "") {
                        if (Context.defined("ecto_migrations_exs")) {
                            Context.error("addColumn column name must be a string literal in ecto_migrations_exs builds.", step.pos);
                        }
                        continue;
                    }

                    var typeName = extractColumnType(step.args[1]);
                    var nullable = (step.args.length >= 3) ? extractNullable(step.args[2]) : false;
                    MigrationRegistry.registerColumn(tableName, columnName, typeName, nullable, step.pos);

                case "addReference" | "addForeignKey":
                    if (step.args.length < 2) {
                        Context.error('${step.name} expects at least (columnName, referencedTable).', step.pos);
                        continue;
                    }

                    var fkColumn = extractString(step.args[0]);
                    var referencedTable = extractString(step.args[1]);

                    if (referencedTable == null || referencedTable == "") {
                        if (Context.defined("ecto_migrations_exs")) {
                            Context.error('${step.name} referencedTable must be a string literal in ecto_migrations_exs builds.', step.pos);
                        }
                    } else {
                        MigrationRegistry.validateTableExists(referencedTable, step.pos);
                    }

                    if (fkColumn == null || fkColumn == "") {
                        if (Context.defined("ecto_migrations_exs")) {
                            Context.error('${step.name} columnName must be a string literal in ecto_migrations_exs builds.', step.pos);
                        }
                    } else {
                        MigrationRegistry.registerColumn(tableName, fkColumn, "references", false, step.pos);
                    }

                case "addIndex" | "addUniqueConstraint":
                    if (step.args.length < 1) {
                        Context.error('${step.name} expects (columns).', step.pos);
                        continue;
                    }

                    var columns = extractStringArray(step.args[0]);
                    MigrationRegistry.validateColumnsExist(tableName, columns, step.pos);

                case "addCheckConstraint":
                    // No schema-level validation; expression is database-specific.

                default:
                    if (Context.defined("ecto_migrations_exs")) {
                        Context.error('Unsupported migration operation for ecto_migrations_exs builds: ${step.name}.', step.pos);
                    }
            }
        }

        #if debug_migration trace('[Migration] Validated createTable chain for "$tableName" in $migrationName'); #end
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

    static function extractString(expr: Expr): Null<String> {
        return switch (expr.expr) {
            case EConst(CString(s)): s;
            default: null;
        }
    }

    static function extractStringArray(expr: Expr): Array<String> {
        return switch (expr.expr) {
            case EArrayDecl(values):
                var columns: Array<String> = [];
                for (v in values) {
                    var s = extractString(v);
                    if (s != null) columns.push(s);
                }
                columns;
            default:
                [];
        }
    }

    static function extractColumnType(expr: Expr): String {
        return switch (expr.expr) {
            case EField(_, name):
                name;
            case ECall({expr: EField(_, name)}, _):
                name;
            default:
                "Unknown";
        }
    }

    static function extractNullable(expr: Expr): Bool {
        return switch (expr.expr) {
            case EObjectDecl(fields):
                for (field in fields) {
                    if (field.field != "nullable") continue;
                    return switch (field.expr.expr) {
                        case EConst(CIdent("true")): true;
                        case EConst(CIdent("false")): false;
                        default: false;
                    }
                }
                false;
            default:
                false;
        }
    }
}

#end
