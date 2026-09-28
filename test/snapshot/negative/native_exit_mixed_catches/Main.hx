import elixir.types.NativeExit;
import elixir.types.NativeException;

typedef ExitAlias = NativeExit;

class Main {
	public static function invalid(operation:Void->String):String {
		return try operation() catch (_:ExitAlias) "exit" catch (_:NativeException) "exception";
	}
}
