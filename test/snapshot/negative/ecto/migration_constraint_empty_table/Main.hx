import ecto.Migration;

/** Reject an unnamed target instead of emitting a malformed constraint. */
@:migration({timestamp: "20240105120000"})
class Main extends Migration {
	public function up():Void {
		createConstraint("", "positive_price", "price > 0");
	}

	public function down():Void {}
}
