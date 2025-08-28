package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
using StringTools;

/**
 * Core migration DSL functions - Part 1 of split MigrationDSL
 * Split to avoid Haxe compiler hang with >153 lines in macro blocks
 */
class MigrationDSLCore {
    
    /**
     * Check if a class is annotated with @:migration
     */
    public static function isMigrationClass(className: String): Bool {
        if (className == null || className == "") return false;
        return className.indexOf("Migration") != -1 || 
               className.indexOf("Create") != -1 || 
               className.indexOf("Alter") != -1 ||
               className.indexOf("Drop") != -1;
    }
    
    /**
     * Get migration configuration from @:migration annotation
     */
    public static function getMigrationConfig(classType: haxe.macro.Type.ClassType): Dynamic {
        if (!classType.meta.has(":migration")) {
            return {table: "default_table", timestamp: generateTimestamp()};
        }
        
        var meta = classType.meta.extract(":migration")[0];
        var tableName = "default_table";
        
        if (meta.params != null && meta.params.length > 0) {
            switch (meta.params[0].expr) {
                case EConst(CString(s, _)):
                    tableName = s;
                case EObjectDecl(fields):
                    for (field in fields) {
                        if (field.field == "table") {
                            switch (field.expr.expr) {
                                case EConst(CString(s, _)):
                                    tableName = s;
                                case _:
                            }
                        }
                    }
                case _:
                    tableName = extractTableNameFromClassName(classType.name);
            }
        } else {
            tableName = extractTableNameFromClassName(classType.name);
        }
        
        return {table: tableName, timestamp: generateTimestamp()};
    }
    
    /**
     * Extract table name from class name (CreateUsers -> users)
     */
    static function extractTableNameFromClassName(className: String): String {
        var tableName = className;
        tableName = tableName.replace("Create", "");
        tableName = tableName.replace("Alter", "");
        tableName = tableName.replace("Drop", "");
        tableName = tableName.replace("Add", "");
        tableName = tableName.replace("Remove", "");
        tableName = tableName.replace("Table", "");
        tableName = tableName.replace("Migration", "");
        return camelCaseToSnakeCase(tableName);
    }
    
    /**
     * Generate migration module structure
     */
    public static function generateMigrationModule(className: String): String {
        var moduleName = className;
        
        var sb = new StringBuf();
        sb.add('defmodule ${moduleName} do\n');
        sb.add('  @moduledoc """\n');
        sb.add('  Generated from Haxe @:migration class: ${className}\n');
        sb.add('  """\n');
        sb.add('  \n');
        sb.add('  use Ecto.Migration\n');
        sb.add('  \n');
        sb.add('  def change do\n');
        sb.add('    # Migration operations go here\n');
        sb.add('  end\n');
        sb.add('end');
        
        return sb.toString();
    }
    
    /**
     * Sanitize identifiers to prevent injection attacks
     */
    public static function sanitizeIdentifier(identifier: String): String {
        if (identifier == null || identifier == "") return "unnamed";
        
        var sanitized = identifier;
        sanitized = sanitized.split("';").join("");
        sanitized = sanitized.split("--").join("");
        sanitized = sanitized.split("DROP").join("");
        sanitized = sanitized.split("System.").join("");
        sanitized = sanitized.split("/*").join("");
        sanitized = sanitized.split("*/").join("");
        
        var clean = "";
        for (i in 0...sanitized.length) {
            var c = sanitized.charAt(i);
            if ((c >= "a" && c <= "z") || 
                (c >= "A" && c <= "Z") || 
                (c >= "0" && c <= "9") || 
                c == "_") {
                clean += c.toLowerCase();
            }
        }
        
        return clean.length > 0 ? clean : "sanitized";
    }
    
    // Helper functions
    static function generateTimestamp(): String { 
        var now = Date.now();
        var year = Std.string(now.getFullYear());
        var month = StringTools.lpad(Std.string(now.getMonth() + 1), "0", 2);
        var day = StringTools.lpad(Std.string(now.getDate()), "0", 2);
        var hour = StringTools.lpad(Std.string(now.getHours()), "0", 2);
        var min = StringTools.lpad(Std.string(now.getMinutes()), "0", 2);
        var sec = StringTools.lpad(Std.string(now.getSeconds()), "0", 2);
        return year + month + day + hour + min + sec;
    }
    
    static function camelCaseToSnakeCase(s: String): String {
        var result = "";
        for (i in 0...s.length) {
            var c = s.charAt(i);
            if (c >= "A" && c <= "Z") {
                if (i > 0) result += "_";
                result += c.toLowerCase();
            } else {
                result += c;
            }
        }
        return result;
    }
}
#end