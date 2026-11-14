/** The result of a check: a value, or the reason why the check failed. */
enum Outcome<T, E> {
	Ok(value:T);
	Err(error:E);
}

/** Why a batch was refused. */
enum Problem {
	Negative(index:Int);
	Missing(first:Int, second:Int);
}

/** Numbers that arrive together under one name. */
typedef Batch = {
	final name:String;
	final values:Array<Int>;
}

/**
 * Regression for haxe.elixir.codex-4ll: an enum value whose argument needs a
 * helper statement.
 *
 * `batch.values.indexOf(x)` first stores `batch.values` in a temporary variable.
 * An enum value is an Elixir tuple, and a tuple cannot hold that statement, so
 * the compiler moves it in front of the tuple. `runtime.exs` checks natively
 * that the tuple still gets the right value.
 */
@:keep
class Main {
	static function main():Void {}

	/** One enum value around the call. */
	public static function single(batch:Batch, wanted:Int):Problem {
		return Negative(batch.values.indexOf(wanted));
	}

	/** Two enum values around the call. */
	public static function nested(batch:Batch, wanted:Int):Outcome<Int, Problem> {
		return Err(Negative(batch.values.indexOf(wanted)));
	}

	/** Two arguments of one enum value each need a helper statement. */
	public static function twoArguments(batch:Batch, first:Int, second:Int):Problem {
		return Missing(batch.values.indexOf(first), batch.values.indexOf(second));
	}

	/** The enum value is the result of an early return from a loop. */
	public static function firstNegative(batch:Batch):Outcome<Int, Problem> {
		for (value in batch.values)
			if (value < 0)
				return Err(Negative(batch.values.indexOf(value)));
		return Ok(batch.values.length);
	}
}
