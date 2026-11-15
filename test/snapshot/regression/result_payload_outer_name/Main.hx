/** A small value nested in a result. */
enum Inner {
	Stale(wanted:Int, other:Int);
	Fresh(n:Int);
}

/** A result whose success payload has the generic name `v`. */
enum Res {
	Ok(v:Int);
	Err(e:Inner);
}

/** A result whose error payload has the generic name `v`. */
enum Reply {
	Ok(v:Int);
	Error(v:String);
}

/**
 * Regression for haxe.elixir.codex-spk: an `Ok(v)` clause that also reads an
 * outer variable named `value`.
 *
 * Elixir code often names the payload of `{:ok, _}` `value` and the payload of
 * `{:error, _}` `reason`. The compiler must not pick that name when the clause
 * reads another variable with the same name. `expected.stdout` is the output of
 * this program on the Haxe interpreter.
 */
@:keep
class Main {
	static function main():Void {
		Sys.println(outerValue(Ok(2), 10));
		Sys.println(outerValue(Err(Stale(3, 1)), 10));
		Sys.println(outerValue(Err(Fresh(4)), 10));
		Sys.println(localValue(Ok(2)));
		Sys.println(outerReason(Error("bad"), "why"));
		Sys.println(outerReason(Ok(5), "why"));
	}

	/** Reads the function argument `value` in the `Ok(v)` clause. */
	public static function outerValue(r:Res, value:Int):Int {
		return switch r {
			case Ok(v): v + value;
			case Err(Stale(wanted, _)): wanted + value;
			case Err(Fresh(n)): n * value;
		};
	}

	/** Reads a local variable `value` in the `Ok(v)` clause. */
	public static function localValue(r:Res):Int {
		var value = 100;
		return switch r {
			case Ok(v): v + value;
			case Err(_): value;
		};
	}

	/** Reads the function argument `reason` in the `Error(v)` clause. */
	public static function outerReason(r:Reply, reason:String):String {
		return switch r {
			case Ok(v): reason + v;
			case Error(v): v + "/" + reason;
		};
	}
}
