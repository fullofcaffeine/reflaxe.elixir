package haxe;

/**
 * Implements the Haxe logging contract on the Elixir target.
 *
 * The compiler adds source information to each `trace()` call. Applications can
 * replace `trace` with a function that receives the value and source information.
 */
@:coreApi
class Log {
	/**
	 * Formats a value with its source position and optional parameters.
	 */
	public static function formatOutput(v:Dynamic, infos:PosInfos):String {
		var str = Std.string(v);
		if (infos == null)
			return str;
		var position = infos.fileName + ":" + infos.lineNumber;
		if (infos.customParams != null)
			for (parameter in infos.customParams)
				str += ", " + Std.string(parameter);
		return position + ": " + str;
	}

	/**
	 * Prints the formatted value to standard output.
	 *
	 * An application can replace this function. A `null` replacement makes the
	 * next `trace()` call fail, as required by the Haxe contract.
	 */
	@:keep
	public static dynamic function trace(v:Dynamic, ?infos:PosInfos):Void {
		Sys.println(formatOutput(v, infos));
	}
}
