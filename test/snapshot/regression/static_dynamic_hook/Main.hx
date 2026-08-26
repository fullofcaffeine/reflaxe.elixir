class Main {
	static var seen = "";
	static var position:haxe.PosInfos = null;
	static var nullFailed = false;
	static var ordinaryHook:String->String = value -> "ordinary:" + value;

	@:keep
	public static dynamic function hook(value:String):String {
		return "default:" + value;
	}

	@:keep
	@:native("renamed_zero")
	public static dynamic function nativeHook():String {
		return "native-default";
	}

	static function captureTrace(value:Dynamic, ?infos:haxe.PosInfos):Void {
		seen = value;
		position = infos;
	}

	static function nullHookFails():Bool {
		var original = hook;
		nullFailed = false;
		hook = null;
		try {
			hook("unused");
		} catch (_:Dynamic) {
			nullFailed = true;
		}
		hook = original;
		return nullFailed;
	}

	static function main():Void {
		var original = hook;
		hook = function customHook(value:String):String {
			return "custom:" + value;
		};
		Sys.println(hook("value"));
		hook = original;
		Sys.println(hook("value"));
		if (!nullHookFails())
			throw "a null dynamic hook remained callable";

		var originalNative = nativeHook;
		nativeHook = () -> "native-custom";
		if (nativeHook() != "native-custom")
			throw "the native dynamic hook did not use its replacement";
		nativeHook = originalNative;
		if (nativeHook() != "native-default")
			throw "the native dynamic hook did not restore its default";

		if (ordinaryHook("value") != "ordinary:value")
			throw "the ordinary static function value selected its setter";

		var oldTrace = haxe.Log.trace;
		haxe.Log.trace = captureTrace;
		var activeTrace = haxe.Log.trace;
		var tracePosition:haxe.PosInfos = {
			fileName: "Main.hx",
			lineNumber: 1,
			className: "Main",
			methodName: "main"
		};
		activeTrace("trace-value", tracePosition);
		haxe.Log.trace = oldTrace;
		if (seen != "trace-value")
			throw "dynamic callback did not update its captured value";
		if (position.fileName != "Main.hx")
			throw "dynamic callback did not preserve source position";
		Sys.println("dynamic-static-ok");
	}
}
