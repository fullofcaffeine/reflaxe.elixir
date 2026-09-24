import ecto.Migration;

/** A computed SQL string must not be mistaken for literal target-looking data. */
@:migration({timestamp: "20240104120002"})
class Main extends Migration {
	public function up():Void {
		execute("SELECT 1");
	}

	public function down():Void {
		execute("SELECT " + Sys.getEnv("MIGRATION_VALUE"));
	}
}
