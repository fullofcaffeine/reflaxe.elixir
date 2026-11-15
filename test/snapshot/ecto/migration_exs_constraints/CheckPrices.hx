package;

import ecto.Migration;

/** Replace an earlier table constraint and restore its original rule on rollback. */
@:migration({timestamp: "20240103120000"})
class CheckPrices extends Migration {
	public function up():Void {
		dropConstraint("products", "legacy_price");
		createConstraint("products", "positive_price", "price > 0");
		createConstraint("products", "bounded_price", "price < 1000");
		// SQL text is literal data: `#{1,3}` is a repeat count, not Elixir code.
		createConstraint("products", "code_shape", "code ~ '^#{1,3}'");
	}

	public function down():Void {
		dropConstraint("products", "code_shape");
		dropConstraint("products", "bounded_price");
		dropConstraint("products", "positive_price");
		createConstraint("products", "legacy_price", "price >= 0");
	}
}
