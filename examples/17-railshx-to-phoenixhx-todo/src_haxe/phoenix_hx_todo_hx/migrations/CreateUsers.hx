package phoenix_hx_todo_hx.migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;

@:migration({timestamp: "20260623090000"})
class CreateUsers extends Migration {
	public function up():Void {
		createTable("users").addColumn("name", ColumnType.String(), {nullable: false})
			.addColumn("email", ColumnType.String(), {nullable: false})
			.addTimestamps()
			.addUniqueConstraint(["email"], "phoenix_hx_todo_users_email_unique")
			.addCheckConstraint("name_length", "length(name) >= 2");
	}

	public function down():Void {
		dropTable("users");
	}
}
