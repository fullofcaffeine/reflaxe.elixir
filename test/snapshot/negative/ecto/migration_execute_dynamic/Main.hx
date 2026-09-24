import ecto.Migration;

/** A removed Haxe helper must not leak into an apparently runnable Ecto script. */
@:migration({timestamp: "20240104120001"})
class Main extends Migration {
	public function up():Void {
		execute(Sys.getEnv("MIGRATION_SQL"));
	}

	public function down():Void {
		execute("SELECT 1");
	}
}
