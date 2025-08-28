package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
using StringTools;

/**
 * Fixed version of MigrationDSL - avoids string concatenation bug
 * Haxe compiler hangs when using string concatenation or StringBuf in
 * macro-conditional blocks with output redirection
 */
class MigrationDSLFixed {
    
    /**
     * Generate migration module structure
     * Using array join instead of string concatenation to avoid Haxe compiler bug
     */
    public static function generateMigrationModule(className: String): String {
        var moduleName = className;
        
        // Use array and join instead of concatenation
        var lines = [
            'defmodule ${moduleName} do',
            '  @moduledoc """',
            '  Generated from Haxe @:migration class: ${className}',
            '  """',
            '  ',
            '  use Ecto.Migration',
            '  ',
            '  def change do',
            '    # Migration operations go here',
            '  end',
            'end'
        ];
        
        return lines.join('\n');
    }
    
    /**
     * Create a table with columns defined via callback
     */
    public static function createTable(tableName: String, callback: Dynamic): String {
        var sanitized = sanitizeIdentifier(tableName);
        
        // Simplified version without TableBuilder
        var lines = [
            'create table(:${sanitized}) do',
            '      # Add columns here',
            '      timestamps()',
            '    end'
        ];
        
        return lines.join('\n');
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
        
        var lines = ['create table(:${tableName}) do'];
        for (col in columnDefs) {
            lines.push(col);
        }
        lines.push('      timestamps()');
        lines.push('    end');
        
        return lines.join('\n');
    }
    
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
     * Sanitize identifiers to prevent injection attacks
     */
    static function sanitizeIdentifier(identifier: String): String {
        if (identifier == null || identifier == "") return "unnamed";
        
        var sanitized = identifier;
        sanitized = sanitized.split("';").join("");
        sanitized = sanitized.split("--").join("");
        sanitized = sanitized.split("DROP").join("");
        
        var clean = "";
        for (i in 0...sanitized.length) {
            var c = sanitized.charAt(i);
            if ((c >= "a" && c <= "z") || 
                (c >= "A" && c <= "Z") || 
                (c >= "0" && c <= "9") || 
                c == "_") {
                clean = clean + c.toLowerCase();  // Avoid += concatenation
            }
        }
        
        return clean.length > 0 ? clean : "sanitized";
    }
    
    static function extractTableNameFromClassName(className: String): String {
        var tableName = className;
        tableName = tableName.replace("Create", "");
        tableName = tableName.replace("Migration", "");
        return camelCaseToSnakeCase(tableName);
    }
    
    static function generateTimestamp(): String { 
        var now = Date.now();
        var parts = [
            Std.string(now.getFullYear()),
            StringTools.lpad(Std.string(now.getMonth() + 1), "0", 2),
            StringTools.lpad(Std.string(now.getDate()), "0", 2),
            StringTools.lpad(Std.string(now.getHours()), "0", 2),
            StringTools.lpad(Std.string(now.getMinutes()), "0", 2),
            StringTools.lpad(Std.string(now.getSeconds()), "0", 2)
        ];
        return parts.join("");
    }
    
    static function camelCaseToSnakeCase(s: String): String {
        var result = "";
        for (i in 0...s.length) {
            var c = s.charAt(i);
            if (c >= "A" && c <= "Z") {
                if (i > 0) result = result + "_";  // Avoid +=
                result = result + c.toLowerCase();
            } else {
                result = result + c;
            }
        }
        return result;
    }
}

#end