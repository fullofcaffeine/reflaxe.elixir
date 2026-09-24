import ecto.Migration;

/** Migration script generation must not guess a runtime-supplied SQL check. */
@:migration({timestamp: "20240105120000"})
class Main extends Migration {
	public function up():Void {
		createConstraint("products", "positive_price", Sys.getEnv("MIGRATION_CHECK"));
	}

	public function down():Void {}
}
