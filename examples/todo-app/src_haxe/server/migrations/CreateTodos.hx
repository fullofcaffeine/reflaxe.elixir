package server.migrations;

import ecto.Migration;
import ecto.Migration.*;

/**
 * Migration to create the todos table with proper indexes
 * 
 * Uses the new typed Migration DSL for compile-time validation
 * and idiomatic Elixir code generation.
 */
@:migration
class CreateTodos extends Migration {
    
    public function up(): Void {
        createTable("todos")
            .addColumn("title", String(), {nullable: false})
            .addColumn("description", Text)
            .addColumn("completed", Boolean, {defaultValue: false})
            .addColumn("priority", String())
            .addColumn("due_date", DateTime)
            .addColumn("tags", Json)
            .addColumn("user_id", Integer)
            .addTimestamps()
            .addIndex(["user_id"])
            .addIndex(["completed"]);
    }
    
    public function down(): Void {
        dropTable("todos");
    }
}