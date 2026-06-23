package phoenix_hx_todo_hx.migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;

@:migration({timestamp: "20260623090200"})
class CreateChatMessages extends Migration {
	public function up():Void {
		createTable("chat_messages").addColumn("body", ColumnType.Text, {nullable: false})
			.addColumn("user_id", ColumnType.Integer, {nullable: false})
			.addTimestamps()
			.addIndex(["user_id"]);
	}

	public function down():Void {
		dropTable("chat_messages");
	}
}
