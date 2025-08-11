package migrations;

import reflaxe.elixir.helpers.MigrationDSL;
import reflaxe.elixir.helpers.MigrationDSL.TableBuilder;

/**
 * Example migration using Haxe→Elixir Migration DSL
 * Demonstrates @:migration annotation with table creation, indexes, and constraints
 */
@:migration
class CreateUsers {
    public static function up(): String {
        return MigrationDSL.createTable("users", function(t) {
            t.addColumn("name", "string", {"null": false});
            t.addColumn("email", "string", {"null": false});
            t.addColumn("age", "integer");
            t.addColumn("active", "boolean", {"default": true});
            t.addColumn("inserted_at", "naive_datetime", {"null": false});
            t.addColumn("updated_at", "naive_datetime", {"null": false});
            
            t.addIndex(["email"], {unique: true});
            t.addIndex(["name", "active"]);
        });
    }
    
    public static function down(): String {
        return MigrationDSL.dropTable("users");
    }
    
    // Main function for compilation testing
    public static function main(): Void {
        trace("CreateUsers migration with real DSL helpers compiled successfully!");
        trace("Up migration: " + up());
        trace("Down migration: " + down());
    }
}