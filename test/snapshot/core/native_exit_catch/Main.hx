import elixir.types.NativeExit;
import elixir.types.NativeException;

typedef ExitAlias = NativeExit;
typedef ChainedExitAlias = ExitAlias;

class Main {
	public static function safely(operation:Void->String):String {
		return try {
			operation();
		} catch (_:NativeExit) {
			"unavailable";
		}
	}

	public static function recover(operation:Void->String, handler:NativeExit->String):String {
		return try {
			operation();
		} catch (reason:NativeExit) {
			handler(reason);
		}
	}

	public static function both(operation:Void->String):String {
		return try {
			safely(operation);
		} catch (_:NativeException) {
			"exception";
		}
	}

	public static function state(operation:Void->String):Int {
		var result = 1;
		try {
			operation();
			result = 2;
		} catch (_:NativeExit) {
			result = 3;
		}
		return result;
	}

	// Foreign exception boundary: deliberately exercise the ordinary catch-all,
	// discard its untyped payload, and return a concrete value.
	public static function ordinary(operation:Void->String):String {
		return try {
			operation();
		} catch (_:Dynamic) {
			"rescued";
		}
	}

	public static function aliased(operation:Void->String):String {
		return try {
			operation();
		} catch (_:ChainedExitAlias) {
			"unavailable";
		}
	}
}
