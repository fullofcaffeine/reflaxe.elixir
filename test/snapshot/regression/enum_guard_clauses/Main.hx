/**
 * Regression test for guard clause compilation
 *
 * BUG: Guard clauses compile to nested if-else instead of idiomatic when clauses
 *
 * Expected: case value do
 *             {:ok, n} when n > 0 -> "positive"
 *           end
 *
 * Was generating: case value do
 *                   {:ok, _} ->
 *                     if (n > 0) do "positive" end
 *                 end
 */

enum Result<T> {
	Ok(value: T);
	Error(msg: String);
}

class Main {
	public static function main() {
		var result = Ok(42);

		var description = switch(result) {
			case Ok(n) if (n > 0): "positive";
			case Ok(n) if (n < 0): "negative";
			case Ok(_): "zero";
			case Error(msg): "error: " + msg;
		}

		trace(description);
	}
}
