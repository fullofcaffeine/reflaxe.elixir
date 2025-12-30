package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * MigrationValidator: Build macro for compile-time migration validation
 * 
 * WHY: Process migration definitions at compile time to validate schema
 * WHAT: Analyzes migration class methods to extract and validate table operations
 * HOW: AST traversal of up()/down() methods to find table/column operations
 */
class MigrationValidator {
    
    /**
     * Build macro to validate migrations at compile time
     */
    public static macro function build(): Array<Field> {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        
        // Only process classes with @:migration metadata
        if (!cls.meta.has(":migration")) {
            return fields;
        }
        
        // Find the up() method and analyze it
        for (field in fields) {
            if (field.name == "up") {
                switch(field.kind) {
                    case FFun(func):
                        if (func.expr != null) {
                            analyzeMigrationExpr(func.expr);
                        }
                    default:
                }
            }
        }
        
        return fields;
    }
    
    /**
     * Analyze migration expressions to extract table operations
     */
    static function analyzeMigrationExpr(expr: Expr): Void {
        switch(expr.expr) {
            case ECall(e, args):
                // Check for createTable calls
                switch(e.expr) {
                    case EField(_, "createTable"):
                        if (args.length > 0) {
                            switch(args[0].expr) {
                                case EConst(CString(tableName, _)):
                                    MigrationRegistry.registerTable(tableName, expr.pos);
                                    // Analyze chained calls for columns
                                    analyzeTableBuilder(expr, tableName);
                                default:
                            }
                        }
                    default:
                }
                
                // Recursively analyze arguments
                for (arg in args) {
                    analyzeMigrationExpr(arg);
                }
                
            case EBlock(exprs):
                for (e in exprs) {
                    analyzeMigrationExpr(e);
                }
                
            case EReturn(e) if (e != null):
                analyzeMigrationExpr(e);
                
            default:
                // Continue traversal for other expression types
                haxe.macro.ExprTools.iter(expr, analyzeMigrationExpr);
        }
    }
    
    /**
     * Analyze TableBuilder method chains
     */
    static function analyzeTableBuilder(expr: Expr, tableName: String): Void {
        switch(expr.expr) {
            case ECall(e, args):
                // First analyze the chain
                analyzeTableBuilder(e, tableName);
                
                // Then process this call
                switch(e.expr) {
                    case EField(_, methodName):
                        processTableBuilderMethod(methodName, args, tableName, expr.pos);
                    default:
                }
            default:
        }
    }
    
    /**
     * Process individual TableBuilder methods
     */
    static function processTableBuilderMethod(methodName: String, args: Array<Expr>, 
                                             tableName: String, pos: Position): Void {
        switch(methodName) {
            case "addColumn":
                if (args.length >= 2) {
                    // Extract column name
                    var columnName = extractString(args[0]);
                    if (columnName != null) {
                        MigrationRegistry.registerColumn(tableName, columnName, "Unknown", false, pos);
                    }
                }
                
            case "addForeignKey":
                if (args.length >= 2) {
                    var columnName = extractString(args[0]);
                    var referencedTable = extractString(args[1]);
                    
                    if (referencedTable != null) {
                        MigrationRegistry.validateTableExistsDeferred(referencedTable, pos);
                    }
                    if (columnName != null) {
                        MigrationRegistry.validateColumnExists(tableName, columnName, pos);
                    }
                }
                
            case "addIndex":
                if (args.length >= 1) {
                    // Extract column array
                    switch(args[0].expr) {
                        case EArrayDecl(values):
                            var columns = [];
                            for (v in values) {
                                var col = extractString(v);
                                if (col != null) columns.push(col);
                            }
                            MigrationRegistry.validateColumnsExist(tableName, columns, pos);
                        default:
                    }
                }
        }
    }
    
    /**
     * Extract string value from expression
     */
    static function extractString(expr: Expr): Null<String> {
        return switch(expr.expr) {
            case EConst(CString(s, _)): s;
            default: null;
        }
    }
}
#end
