import ecto.Migration;
import ecto.Migration.ColumnType;

@:migration({timestamp: "20240106120000"})
class Main extends Migration {
	public function up():Void {
		createTable("children").addColumn("code", ColumnType.String(), {reference: {table: "parents", with: []}});
	}

	public function down():Void {
		dropTable("children");
	}
}
