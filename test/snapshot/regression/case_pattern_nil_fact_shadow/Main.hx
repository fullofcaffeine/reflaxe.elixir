/** A result with a string payload. */
enum SRes {
	SOk(value:String);
	SErr(e:String);
}

/**
 * Regression for haxe.elixir.codex-c0o.9: a case pattern that binds a name that
 * an outer variable already uses.
 *
 * Before the switch, the compiler knows that the outer `value` is `nil`. Inside
 * `case SOk(value)` the name means the payload, so that fact no longer holds.
 * The compiler used the fact anyway and folded `value == null` to `true`.
 * `expected.stdout` is the output of this program on the Haxe interpreter.
 */
@:keep
class Main {
	static function main():Void {
		Sys.println(clash(SOk("x")));
		Sys.println(clash(SOk(null)));
		Sys.println(clash(SErr("e")));
		Sys.println(clashGuard(SOk("y")));
		Sys.println(clashGuard(SOk(null)));
		Sys.println(clashGuard(SErr("e")));
	}

	/** The clause body tests the payload. */
	public static function clash(r:SRes):String {
		var value:Null<String> = null;
		switch (r) {
			case SOk(value):
				if (value == null)
					return "inner nil";
				return value;
			case SErr(e):
				return value == null ? "outer nil" : "outer set";
		}
	}

	/** The case guard tests the payload. */
	public static function clashGuard(r:SRes):String {
		var value:Null<String> = null;
		return switch (r) {
			case SOk(value) if (value != null): "inner " + value;
			case SOk(_): "inner nil";
			case SErr(_): value == null ? "outer nil" : "outer set";
		};
	}
}
