#if elixir
import elixir.ErlangTerm;

/** A second Erlang module, so that one arm can name two of them. */
@:native(":lists")
extern class ErlangLists {
	@:native("reverse")
	static function reverse(items:Array<Int>):Array<Int>;
}
#else

/** Stand-in for the Erlang term codec on the Haxe interpreter: a round trip returns the value. */
class ErlangTerm {
	public static function toBinary(value:Dynamic):String
		return haxe.Serializer.run(value);

	public static function fromBinary(value:String):Dynamic
		return haxe.Unserializer.run(value);
}

/** Stand-in for `:lists.reverse/1` on the Haxe interpreter. */
class ErlangLists {
	public static function reverse(items:Array<Int>):Array<Int> {
		final copy = items.copy();
		copy.reverse();
		return copy;
	}
}
#end

/** A result with the payload names that the compiler also uses by default. */
enum Reply {
	Ok(value:Int);
	Error(reason:String);
}

/**
 * Regression for haxe.elixir.codex-az9: an arm of a `switch` on `Ok`/`Error`
 * that calls a function of an Erlang module, such as
 * `:erlang.term_to_binary/1`.
 *
 * The compiler took the module name `:erlang` for an unbound local variable
 * and renamed the payload binder to it: `{:ok, value}` became
 * `{:ok, :erlang}`, which matches only the atom `:erlang`. `expected.stdout`
 * is the output of this program on the Haxe interpreter, where the two
 * stand-in classes above replace the Erlang modules.
 */
@:keep
class Main {
	static function main():Void {
		for (r in [Ok(5), Ok(-2), Error("bad"), Error("x")]) {
			Sys.println(otherArmCalls(r));
			Sys.println(sameArmCalls(r));
			Sys.println(guardOnlyBinder(r));
			Sys.println(afterSwitch(r));
			Sys.println(errorArmCalls(r));
			Sys.println(twoModules(r));
		}
	}

	static function roundTrip(n:Int):Int
		return (cast ErlangTerm.fromBinary(ErlangTerm.toBinary(cast n)) : Int);

	/** The guarded arm reads the binder; the other `Ok` arm calls the module. */
	public static function otherArmCalls(r:Reply):Int {
		return switch r {
			case Ok(value) if (value >= 0): value;
			case Ok(_): (cast ErlangTerm.fromBinary(ErlangTerm.toBinary(cast -1)) : Int);
			case Error(_): -2;
		};
	}

	/** The guarded arm passes the binder to the module. */
	public static function sameArmCalls(r:Reply):Int {
		return switch r {
			case Ok(value) if (value >= 0): (cast ErlangTerm.fromBinary(ErlangTerm.toBinary(cast value)) : Int);
			case Ok(_): -1;
			case Error(_): -2;
		};
	}

	/** Only the guard reads the binder; the body calls the module. */
	public static function guardOnlyBinder(r:Reply):Int {
		return switch r {
			case Ok(value) if (value >= 0): (cast ErlangTerm.fromBinary(ErlangTerm.toBinary(cast 7)) : Int);
			case Ok(_): -1;
			case Error(_): -2;
		};
	}

	/** An early return moves the code after the `switch`, with its module call, into the `Ok` arm. */
	public static function afterSwitch(r:Reply):Int {
		var n = 0;
		switch r {
			case Ok(value) if (value >= 0):
				n = value;
			case Ok(_):
				n = -1;
			case Error(_):
				return -2;
		}
		return roundTrip(n) + (cast ErlangTerm.fromBinary(ErlangTerm.toBinary(cast 1)) : Int);
	}

	/** The same shape on the `Error` side, with the default name `reason`. */
	public static function errorArmCalls(r:Reply):String {
		return switch r {
			case Error(reason) if (reason.length > 2): (cast ErlangTerm.fromBinary(ErlangTerm.toBinary(cast "long")) : String);
			case Error(_): "short";
			case Ok(_): "ok";
		};
	}

	/** One arm names two Erlang modules. */
	public static function twoModules(r:Reply):String {
		return switch r {
			case Ok(value) if (value >= 0):
				final items = ErlangLists.reverse([1, 2, value]);
				final back:Array<Int> = cast ErlangTerm.fromBinary(ErlangTerm.toBinary(cast items));
				back.join(",");
			case Ok(_): ErlangLists.reverse([3, 4]).join(",");
			case Error(reason): reason;
		};
	}
}
