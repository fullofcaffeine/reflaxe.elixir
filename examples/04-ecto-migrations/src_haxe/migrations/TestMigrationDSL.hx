package migrations;

import reflaxe.elixir.helpers.MigrationDSL;

/**
 * Test for MigrationDSL helper functions to verify proper Ecto DSL generation
 */
class TestMigrationDSL {
    public static function main(): Void {
        trace("Testing MigrationDSL helper functions...");
        
        // Test createTable DSL generation
        var usersMigration = MigrationDSL.createTable("users", function(t) {
            t.addColumn("name", "string", {"null": false});
            t.addColumn("email", "string", {"null": false});
            t.addColumn("age", "integer");
            t.addColumn("active", "boolean", {"default": true});
            
            t.addIndex(["email"], {unique: true});
            t.addIndex(["name", "active"]);
        });
        
        trace("Users table creation DSL:");
        trace(usersMigration);
        trace("");
        
        // Test dropTable DSL generation
        var dropMigration = MigrationDSL.dropTable("users");
        trace("Users table drop DSL:");
        trace(dropMigration);
        trace("");
        
        // Test posts table with foreign keys and constraints
        var postsMigration = MigrationDSL.createTable("posts", function(t) {
            t.addColumn("title", "string", {"null": false});
            t.addColumn("content", "text");
            t.addColumn("user_id", "integer", {"null": false});
            
            t.addForeignKey("user_id", "users", "id");
            t.addIndex(["user_id"]);
            t.addCheckConstraint("length(title) > 0", "title_not_empty");
        });
        
        trace("Posts table creation with foreign key DSL:");
        trace(postsMigration);
        trace("");
        
        // Test individual helper functions
        var addColumnResult = MigrationDSL.addColumn("users", "phone", "string", {"null": true});
        trace("Add column DSL:");
        trace(addColumnResult);
        trace("");
        
        var addIndexResult = MigrationDSL.addIndex("users", ["phone", "active"], {unique: false});
        trace("Add index DSL:");
        trace(addIndexResult);
        trace("");
        
        trace("✅ MigrationDSL helper functions test completed successfully!");
    }
}