/** Two or three numbers that are computed in order. */
enum Numbers {
	Pair(first:Int, second:Int);
	Triple(first:Int, second:Int, third:Int);
}

/**
 * Regression for the review of haxe.elixir.codex-4ll: the arguments of an enum
 * value must run from left to right.
 *
 * `source("second").indexOf(2)` needs a helper statement, which moves in front
 * of the Elixir tuple. The earlier argument `step("first")` must still run
 * before it. `runtime.exs` passes native callbacks that record the order.
 */
@:keep
class Main {
	static function main():Void {}

	/** The first argument is a call; the second needs a helper statement. */
	public static function pair(step:String->Int, source:String->Array<Int>):Numbers {
		return Pair(step("first"), source("second").indexOf(2));
	}

	/** A plain variable sits between a call and an argument with a helper statement, and a call follows. */
	public static function triple(step:String->Int, source:String->Array<Int>, plain:Int):Numbers {
		return Triple(step("first"), plain, source("third").indexOf(3) + step("fourth"));
	}

	/** Both arguments need a helper statement. */
	public static function twoHelpers(source:String->Array<Int>):Numbers {
		return Pair(source("first").indexOf(1), source("second").indexOf(3));
	}

	/** The outer value has an earlier call, and the inner value needs a helper statement. */
	public static function nested(step:String->Int, source:String->Array<Int>):Array<Numbers> {
		return [Pair(step("first"), 0), Pair(step("second"), source("third").indexOf(2))];
	}
}
