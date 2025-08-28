package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.TypedExprTools;
import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;

/**
 * Migration Compiler for Reflaxe.Elixir
 * 
 * WHY: Database migrations are critical for Phoenix applications.
 * This compiler enables type-safe migration definitions in Haxe that
 * compile to proper Ecto migration modules.
 * 
 * WHAT: Handles compilation of classes annotated with @:migration:
 * - Generates Ecto.Migration modules with up/down functions
 * - Table creation, modification, and deletion
 * - Index and constraint management
 * - Column operations with type mapping
 * - Execute raw SQL support
 * 
 * HOW:
 * 1. Extract migration metadata and version
 * 2. Generate module with use Ecto.Migration
 * 3. Compile up() and down() functions
 * 4. Transform Haxe migration DSL to Ecto DSL
 * 5. Handle timestamps and references
 * 
 * @see documentation/ECTO_MIGRATION.md - Complete migration guide
 */
@:nullSafety(Off)
class MigrationCompiler {
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    
    /**
     * Create a new migration compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Compile a class annotated with @:migration
     * 
     * WHY: Ecto migrations need specific module structure with
     * use Ecto.Migration and up/down functions.
     * 
     * WHAT: Generates a complete migration module including:
     * - Module definition with timestamp prefix
     * - use Ecto.Migration directive
     * - up() function for forward migration
     * - down() function for rollback
     * - Helper functions for complex migrations
     * 
     * HOW:
     * 1. Extract migration name and options
     * 2. Generate module with proper naming
     * 3. Find and compile up/down functions
     * 4. Add helper methods if present
     * 5. Ensure reversible operations
     * 
     * @param classType The class type information
     * @param varFields Variable fields (usually empty for migrations)
     * @param funcFields Function fields (up, down, helpers)
     * @return Generated Ecto migration module code
     */
    public function compileMigrationClass(
        classType: ClassType,
        varFields: Array<ClassVarData>,
        funcFields: Array<ClassFuncData>
    ): String {
        
        #if debug_migration
        trace('[MigrationCompiler] Compiling migration class: ${classType.name}');
        trace('[MigrationCompiler] Functions: ${funcFields.length}');
        for (f in funcFields) {
            trace('[MigrationCompiler] Function: ${f.field.name}');
        }
        #end
        
        var moduleName = compiler.getModuleName(classType);
        
        // Generate module header
        var result = 'defmodule ${moduleName} do\n';
        result += '  use Ecto.Migration\n\n';
        
        // Find and compile up/down functions
        var upFunction = findFunction(funcFields, "up");
        var downFunction = findFunction(funcFields, "down");
        
        if (upFunction != null) {
            result += compileMigrationFunction(upFunction, "up");
        } else {
            // Generate up function from metadata if no explicit up() defined
            result += generateUpFromMetadata(classType, varFields);
        }
        
        if (downFunction != null) {
            result += compileMigrationFunction(downFunction, "down");
        } else {
            // Generate down function from metadata if no explicit down() defined
            result += generateDownFromMetadata(classType);
        }
        
        // Compile helper functions (excluding DSL methods)
        var dslMethods = ["createTable", "dropTable", "addColumn", "removeColumn", 
                         "addIndex", "dropIndex", "timestamps", "execute"];
        for (funcField in funcFields) {
            var name = funcField.field.name;
            // Skip up/down, constructors, and DSL methods
            if (name != "up" && name != "down" && name != "new" && dslMethods.indexOf(name) == -1) {
                result += compiler.compileFunction(funcField, true) + '\n';
            }
        }
        
        result += 'end\n';
        
        #if debug_migration
//         trace('[MigrationCompiler] Generated migration: ${result.substring(0, 200)}...');
        #end
        
        return result;
    }
    
    // ================== Private Helper Methods ==================
    
    /**
     * Find a function by name in the function fields
     */
    private function findFunction(funcFields: Array<ClassFuncData>, name: String): ClassFuncData {
        #if debug_migration
        trace('[MigrationCompiler] Looking for function: ${name}');
        #end
        
        for (funcField in funcFields) {
            #if debug_migration
            trace('[MigrationCompiler] Checking function: ${funcField.field.name}');
            #end
            
            if (funcField.field.name == name) {
                #if debug_migration
                trace('[MigrationCompiler] Found function: ${name}');
                #end
                return funcField;
            }
        }
        
        #if debug_migration
        trace('[MigrationCompiler] Function not found: ${name}');
        #end
        return null;
    }
    
    /**
     * Compile a migration function (up or down)
     */
    private function compileMigrationFunction(funcField: ClassFuncData, name: String): String {
        #if debug_migration
        trace('[MigrationCompiler] compileMigrationFunction: ${name}');
        trace('[MigrationCompiler] funcField.expr type: ${funcField.expr}');
        #end
        
        // Special handling for migration DSL methods
        return '  def ${name} do\n' +
               compileMigrationBody(funcField.expr) +
               '  end\n\n';
    }
    
    /**
     * Compile the body of a migration function
     * 
     * WHY: Migration functions use DSL methods that need special handling
     * WHAT: Transform Haxe migration calls to Ecto DSL operations
     * HOW: Detect and compile migration-specific method calls
     * 
     * NOTE: This is a simplified implementation. A proper implementation would:
     * 1. Track table creation state
     * 2. Accumulate column additions within create table blocks
     * 3. Generate properly nested Ecto DSL
     */
    private function compileMigrationBody(expr: TypedExpr): String {
        // Handle migration DSL operations
        var body = compileMigrationExpression(expr);
        
        // Indent the body
        var lines = body.split('\n');
        return lines.map(line -> if (StringTools.trim(line) != "") '    ' + line else '').join('\n') + '\n';
    }
    
    /**
     * Compile migration-specific expressions with DSL support
     * 
     * WHY: Migration DSL methods need transformation to Ecto operations
     * WHAT: Handle createTable, addColumn, timestamps, etc.
     * HOW: Pattern match on method calls and generate appropriate Ecto DSL
     */
    private function compileMigrationExpression(expr: TypedExpr): String {
        if (expr == null) return "";
        
        #if debug_migration
        trace('[MigrationCompiler] compileMigrationExpression: ${expr.expr}');
        #end
        
        return switch(expr.expr) {
            case TBlock(exprs):
                // Compile each expression in the block
                var results = [];
                for (e in exprs) {
                    var compiled = compileMigrationExpression(e);
                    if (compiled != "") results.push(compiled);
                }
                results.join('\n');
                
            case TCall(e, params):
                // Check for migration DSL method calls
                var result = compileMigrationCall(e, params);
                #if debug_migration
                trace('[MigrationCompiler] TCall result: ${result}');
                #end
                result;
                
            case TIf(econd, eif, eelse):
                // Handle conditional migrations
                var cond = compiler.compileExpression(econd);
                var ifBody = compileMigrationExpression(eif);
                var elseBody = eelse != null ? compileMigrationExpression(eelse) : "";
                
                if (elseBody != "") {
                    'if ${cond} do\n  ${ifBody}\nelse\n  ${elseBody}\nend';
                } else {
                    'if ${cond} do\n  ${ifBody}\nend';
                }
                
            default:
                // For non-migration expressions, use main compiler
                compiler.compileExpression(expr);
        }
    }
    
    /**
     * Compile migration DSL method calls
     * 
     * WHY: Transform Haxe method calls to Ecto migration DSL
     * WHAT: Handle createTable, addColumn, dropTable, etc.
     * HOW: Pattern match on method name and generate appropriate Ecto code
     */
    private function compileMigrationCall(e: TypedExpr, params: Array<TypedExpr>): String {
        // Extract method name
        var methodName = extractMethodName(e);
        
        return switch(methodName) {
            case "createTable":
                compileCreateTable(params);
            case "dropTable":
                compileDropTable(params);
            case "addColumn":
                compileAddColumn(params);
            case "removeColumn":
                compileRemoveColumn(params);
            case "timestamps":
                "timestamps()";
            case "addIndex":
                compileAddIndex(params);
            case "dropIndex":
                compileDropIndex(params);
            default:
                // Not a migration DSL method, compile normally
                compiler.compileExpression({expr: TCall(e, params), pos: e.pos, t: e.t});
        }
    }
    
    /**
     * Extract method name from expression
     */
    private function extractMethodName(e: TypedExpr): String {
        var name = switch(e.expr) {
            case TField(_, FInstance(_, _, cf)) | TField(_, FStatic(_, cf)) | TField(_, FAnon(cf)):
                cf.get().name;
            case TIdent(s):
                s;
            default:
                "";
        }
        
        #if debug_migration
        trace('[MigrationCompiler] extractMethodName: ${name} from expr: ${e.expr}');
        #end
        
        return name;
    }
    
    /**
     * Compile createTable DSL operation
     */
    private function compileCreateTable(params: Array<TypedExpr>): String {
        if (params.length == 0) return "# createTable: missing table name";
        
        var tableName = extractStringLiteral(params[0]);
        if (tableName == null) {
            tableName = compiler.compileExpression(params[0]);
        }
        
        // For simple createTable("name") calls, just note that table creation was started
        // The actual structure will be built with subsequent addColumn calls
        // This is a simplified approach - in a real implementation, we'd track state
        return 'create table(:${tableName}) do\n  # columns will be added by subsequent DSL calls\nend';
    }
    
    /**
     * Compile dropTable DSL operation
     */
    private function compileDropTable(params: Array<TypedExpr>): String {
        if (params.length == 0) return "# dropTable: missing table name";
        
        var tableName = extractStringLiteral(params[0]);
        if (tableName == null) {
            tableName = compiler.compileExpression(params[0]);
        }
        
        return 'drop table(:${tableName})';
    }
    
    /**
     * Compile addColumn DSL operation
     */
    private function compileAddColumn(params: Array<TypedExpr>): String {
        if (params.length < 3) return "# addColumn: insufficient parameters";
        
        var tableName = extractStringLiteral(params[0]);
        var columnName = extractStringLiteral(params[1]);
        var columnType = extractStringLiteral(params[2]);
        
        if (tableName == null) tableName = compiler.compileExpression(params[0]);
        if (columnName == null) columnName = compiler.compileExpression(params[1]);
        if (columnType == null) columnType = compiler.compileExpression(params[2]);
        
        var options = "";
        if (params.length > 3) {
            // TODO: Handle column options
            options = ""; // Would parse options from params[3]
        }
        
        return 'add :${columnName}, :${columnType}${options}';
    }
    
    /**
     * Compile removeColumn DSL operation
     */
    private function compileRemoveColumn(params: Array<TypedExpr>): String {
        if (params.length < 2) return "# removeColumn: insufficient parameters";
        
        var tableName = extractStringLiteral(params[0]);
        var columnName = extractStringLiteral(params[1]);
        
        if (tableName == null) tableName = compiler.compileExpression(params[0]);
        if (columnName == null) columnName = compiler.compileExpression(params[1]);
        
        return 'remove :${columnName}';
    }
    
    /**
     * Compile addIndex DSL operation
     */
    private function compileAddIndex(params: Array<TypedExpr>): String {
        if (params.length < 2) return "# addIndex: insufficient parameters";
        
        var tableName = extractStringLiteral(params[0]);
        if (tableName == null) tableName = compiler.compileExpression(params[0]);
        
        // TODO: Handle column list for index
        var columns = "[:column_name]";
        
        return 'create index(:${tableName}, ${columns})';
    }
    
    /**
     * Compile dropIndex DSL operation
     */
    private function compileDropIndex(params: Array<TypedExpr>): String {
        if (params.length < 2) return "# dropIndex: insufficient parameters";
        
        var tableName = extractStringLiteral(params[0]);
        if (tableName == null) tableName = compiler.compileExpression(params[0]);
        
        // TODO: Handle column list for index
        var columns = "[:column_name]";
        
        return 'drop index(:${tableName}, ${columns})';
    }
    
    /**
     * Extract string literal from expression
     */
    private function extractStringLiteral(expr: TypedExpr): Null<String> {
        return switch(expr.expr) {
            case TConst(TString(s)): s;
            default: null;
        }
    }
    
    /**
     * Generate up function from class metadata
     * 
     * WHY: Allow table definition via field annotations
     * WHAT: Creates a create table operation from @:field annotations
     * HOW: Extract table name and fields, generate Ecto create table
     */
    private function generateUpFromMetadata(classType: ClassType, varFields: Array<ClassVarData>): String {
        // Extract table name from @:migration metadata
        var tableName = extractTableName(classType);
        
        var result = '  def up do\n';
        result += '    create table(:${tableName}) do\n';
        
        // Add columns from field annotations
        for (field in varFields) {
            var fieldResult = compileFieldToColumn(field);
            if (fieldResult != "") {
                result += '      ${fieldResult}\n';
            }
        }
        
        // Add timestamps if @:timestamps is present
        if (classType.meta.has(":timestamps")) {
            result += '      timestamps()\n';
        }
        
        result += '    end\n';
        
        // Add indexes from migrate functions
        // TODO: Parse migrateAddIndexes function if present
        
        result += '  end\n\n';
        
        return result;
    }
    
    /**
     * Generate down function from class metadata
     * 
     * WHY: Automatic rollback for metadata-based migrations
     * WHAT: Creates a drop table operation
     * HOW: Extract table name and generate drop table
     */
    private function generateDownFromMetadata(classType: ClassType): String {
        var tableName = extractTableName(classType);
        
        return '  def down do\n' +
               '    drop table(:${tableName})\n' +
               '  end\n\n';
    }
    
    /**
     * Extract table name from migration metadata
     */
    private function extractTableName(classType: ClassType): String {
        if (!classType.meta.has(":migration")) {
            // Derive from class name
            var name = classType.name;
            name = StringTools.replace(name, "Create", "");
            name = StringTools.replace(name, "Migration", "");
            return NamingHelper.toSnakeCase(name) + "s"; // Pluralize
        }
        
        var meta = classType.meta.extract(":migration")[0];
        if (meta.params != null && meta.params.length > 0) {
            switch (meta.params[0].expr) {
                case EConst(CString(s, _)):
                    return s;
                case EObjectDecl(fields):
                    for (field in fields) {
                        if (field.field == "table") {
                            switch (field.expr.expr) {
                                case EConst(CString(s, _)):
                                    return s;
                                default:
                            }
                        }
                    }
                default:
            }
        }
        
        // Fallback to deriving from class name
        var name = classType.name;
        name = StringTools.replace(name, "Create", "");
        name = StringTools.replace(name, "Migration", "");
        return NamingHelper.toSnakeCase(name) + "s";
    }
    
    /**
     * Compile field to column definition
     */
    private function compileFieldToColumn(field: ClassVarData): String {
        if (field.field.meta == null) return "";
        
        var fieldMeta = field.field.meta.extract(":field");
        if (fieldMeta.length == 0) return "";
        
        var fieldName = NamingHelper.toSnakeCase(field.field.name);
        var fieldType = "string"; // Default type
        var options = [];
        
        // Extract field options from metadata
        var meta = fieldMeta[0];
        if (meta.params != null && meta.params.length > 0) {
            switch (meta.params[0].expr) {
                case EObjectDecl(fields):
                    for (f in fields) {
                        switch (f.field) {
                            case "type":
                                switch (f.expr.expr) {
                                    case EConst(CString(s, _)):
                                        fieldType = s;
                                    default:
                                }
                            case "null":
                                switch (f.expr.expr) {
                                    case EConst(CIdent("false")):
                                        options.push("null: false");
                                    default:
                                }
                            case "default":
                                var defaultValue = compileMetaExpr(f.expr);
                                if (defaultValue != null) {
                                    options.push('default: ${defaultValue}');
                                }
                        }
                    }
                default:
            }
        }
        
        var optionsStr = options.length > 0 ? ", " + options.join(", ") : "";
        return 'add :${fieldName}, :${fieldType}${optionsStr}';
    }
    
    /**
     * Compile metadata expression to Elixir
     */
    private function compileMetaExpr(expr: Expr): Null<String> {
        return switch (expr.expr) {
            case EConst(CString(s, _)): '"${s}"';
            case EConst(CIdent("true")): "true";
            case EConst(CIdent("false")): "false";
            case EConst(CInt(i)): i;
            case EConst(CFloat(f)): f;
            default: null;
        }
    }
}

#end