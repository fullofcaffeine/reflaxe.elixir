import ecto.Migration;

/** Dropping a constraint requires its explicit, non-empty identity. */
@:migration({timestamp: "20240105120000"})
class Main extends Migration {
	public function up():Void {
		createConstraint("products", "positive_price", "price > 0");
	}

	public function down():Void {
		dropConstraint("products", "");
	}
}
