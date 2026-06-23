package phoenix_hx_todo_hx.migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;

@:migration({timestamp: "20260623090100"})
class CreateTodos extends Migration {
	public function up():Void {
		createTable("todos").addColumn("title", ColumnType.String(), {nullable: false})
			.addColumn("notes", ColumnType.Text)
			.addColumn("completed", ColumnType.Boolean, {defaultValue: false})
			.addColumn("user_id", ColumnType.Integer, {nullable: false})
			.addTimestamps()
			.addIndex(["user_id"])
			.addIndex(["completed"]);
	}

	public function down():Void {
		dropTable("todos");
	}
}
