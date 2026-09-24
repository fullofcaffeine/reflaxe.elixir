package migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;
import ecto.Migration.OnDeleteAction;
import ecto.Migration.OnUpdateAction;

/**
 * Advanced migration example with foreign keys and constraints
 */
// @:migration: marks this class as an Ecto migration definition for migration emission.
@:migration({timestamp: "20240102120000"})
class CreatePosts extends Migration {
	public function new() {}

	public function up():Void {
		// Ecto creates its conventional `id` primary key by default.
		createTable("posts").addColumn("title", ColumnType.String(), {nullable: false})
			.addColumn("content", ColumnType.Text)
			.addColumn("published", ColumnType.Boolean, {defaultValue: false})
			.addColumn("view_count", ColumnType.Integer, {defaultValue: 0})
			.addColumn("user_id", ColumnType.References("users"), {onDelete: OnDeleteAction.Cascade, onUpdate: OnUpdateAction.Cascade})
			.addTimestamps()
			.addIndex(["user_id"])
			.addIndex(["published", "inserted_at"]);
		createConstraint("posts", "positive_view_count", "view_count >= 0");
	}

	public function down():Void {
		dropConstraint("posts", "positive_view_count");
		dropTable("posts");
	}
}
