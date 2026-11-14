/** The result of a check: a value, or the reason why the check failed. */
enum Outcome<T, E> {
	Ok(value:T);
	Err(error:E);
}

/** Why a revision was refused. */
enum Refusal {
	Stale(expected:String, actual:String);
	Malformed(field:String);
}

/**
 * Regression for haxe.elixir.codex-zrm: a pattern inside a pattern, such as
 * `Err(Stale(expected, _))`.
 *
 * The inner pattern must match the value that the outer pattern found, not the
 * whole result again. `runtime.exs` checks the results natively.
 */
@:keep
class Main {
	static function main():Void {}

	/** Admits a revision when the digests are equal and both are present. */
	public static function admit(expected:String, actual:String):Outcome<Int, Refusal> {
		if (expected == "" || actual == "")
			return Err(Malformed("digest"));
		return expected == actual ? Ok(1) : Err(Stale(expected, actual));
	}

	/** True only for a stale refusal that names the digest that the caller expected. */
	public static function refusesStale(expected:String, actual:String):Bool {
		return switch admit(expected, actual) {
			case Err(Stale(wanted, _)): wanted == expected;
			case _: false;
		};
	}
}
