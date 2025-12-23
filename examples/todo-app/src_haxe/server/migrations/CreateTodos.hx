package server.migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;

/**
 * Migration to create the todos table with proper indexes
 * 
 * Uses the new typed Migration DSL for compile-time validation
 * and idiomatic Elixir code generation.
 */
@:migration({timestamp: "20250813170314"})
class CreateTodos extends Migration {
    
    public function up(): Void {
        createTable("todos")
            .addColumn("title", ColumnType.String(), {nullable: false})
            .addColumn("description", ColumnType.Text)
            .addColumn("completed", ColumnType.Boolean, {defaultValue: false})
            .addColumn("priority", ColumnType.String())
            .addColumn("due_date", ColumnType.DateTime)
            .addColumn("tags", ColumnType.Json)
            .addColumn("user_id", ColumnType.Integer)
            .addTimestamps()
            .addIndex(["user_id"])
            .addIndex(["completed"]);
    }
    
    public function down(): Void {
        dropTable("todos");
    }
}
