import ecto.Migration;
import ecto.Migration.ColumnType;

/** SQL entrypoints retain their string bytes and order beside typed table calls. */
@:migration({timestamp: "20240104120000"})
class ExecuteSql extends Migration {
	public function up():Void {
		createTable("execute_records").addColumn("label", ColumnType.String(), {nullable: false});
		execute("INSERT INTO execute_records (label) VALUES ('first')");
		execute("INSERT INTO execute_records (label) VALUES ('quote '' slash \\ interpolation #{untouched}')\n-- retained SQL comment");
		execute("CREATE TABLE execute_audit AS SELECT label FROM execute_records ORDER BY id");
	}

	public function down():Void {
		execute("DELETE FROM execute_audit WHERE label = 'first'");
		execute("DROP TABLE execute_audit");
		dropTable("execute_records");
	}
}
