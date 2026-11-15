/** A small value nested in a result. */
enum Inner {
	Stale(wanted:Int, other:Int);
	Fresh(n:Int);
}

/** A result that carries an `Inner` value on error. */
enum Res {
	Ok(v:Int);
	Err(e:Inner);
}

/**
 * Regression for haxe.elixir.codex-lrl: a pattern inside a pattern with a guard,
 * such as `case Err(Stale(wanted, _)) if (wanted > 0)`.
 *
 * The inner `case` must test the value that the outer pattern found. It tested
 * `nil`, so every `Err` value took the fallback. `expected.stdout` is the
 * output of this program on the Haxe interpreter.
 */
@:keep
class Main {
	static function main():Void {
		Sys.println(nestedGuard(Err(Stale(5, 0))));
		Sys.println(nestedGuard(Err(Stale(-5, 0))));
		Sys.println(nestedGuard(Err(Fresh(3))));
		Sys.println(nestedGuard(Ok(1)));
		Sys.println(guardOnLaterCase(Err(Fresh(7))));
		Sys.println(guardOnLaterCase(Err(Fresh(-7))));
		Sys.println(guardOnLaterCase(Err(Stale(1, 2))));
	}

	/** The guard is on the first inner pattern. */
	public static function nestedGuard(r:Res):Int {
		var value = 100;
		return switch r {
			case Err(Stale(wanted, _)) if (wanted > 0): wanted + value;
			case Err(Fresh(count)): count + value;
			case _: -1;
		};
	}

	/** The guard is on the second inner pattern. */
	public static function guardOnLaterCase(r:Res):Int {
		return switch r {
			case Err(Stale(wanted, other)): wanted * 10 + other;
			case Err(Fresh(count)) if (count > 0): count;
			case _: 0;
		};
	}
}
