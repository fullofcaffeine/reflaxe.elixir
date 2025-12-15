package migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;
import ecto.Migration.OnDeleteAction;

/**
 * Advanced migration example with foreign keys and constraints
 */
@:migration  
class CreatePosts extends Migration {
    public function new() {}

    public function up(): Void {
        createTable("posts")
            .addId()
            .addColumn("title", ColumnType.String(), {nullable: false})
            .addColumn("content", ColumnType.Text)
            .addColumn("published", ColumnType.Boolean, {defaultValue: false})
            .addColumn("view_count", ColumnType.Integer, {defaultValue: 0})
            .addReference("user_id", "users", {onDelete: OnDeleteAction.Cascade})
            .addTimestamps()
            .addIndex(["user_id"])
            .addIndex(["published", "inserted_at"])
            .addCheckConstraint("positive_view_count", "view_count >= 0");
    }

    public function down(): Void {
        dropTable("posts");
    }
}
