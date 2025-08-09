package migrations;

import reflaxe.elixir.helpers.MigrationDSL;
import reflaxe.elixir.helpers.MigrationDSL.TableBuilder;

/**
 * Advanced migration example with foreign keys and constraints
 */
@:migration  
class CreatePosts {
    public static function up(): String {
        return MigrationDSL.createTable("posts", function(t) {
            t.addColumn("title", "string", {"null": false});
            t.addColumn("content", "text");
            t.addColumn("published", "boolean", {"default": false});
            t.addColumn("view_count", "integer", {"default": 0});
            t.addColumn("user_id", "integer", {"null": false});
            t.addColumn("inserted_at", "naive_datetime", {"null": false});
            t.addColumn("updated_at", "naive_datetime", {"null": false});
            
            t.addForeignKey("user_id", "users", "id");
            t.addIndex(["user_id"]);
            t.addIndex(["published", "inserted_at"]);
            
            // Check constraint to ensure view_count is non-negative
            t.addCheckConstraint("view_count >= 0", "positive_view_count");
        });
    }
    
    public static function down(): String {
        return MigrationDSL.dropTable("posts");
    }
    
    // Main function for compilation testing
    public static function main(): Void {
        trace("CreatePosts migration with real DSL helpers compiled successfully!");
        trace("Up migration: " + up());
        trace("Down migration: " + down());
    }
}