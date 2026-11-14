package;

class Main {
	public static function main():Void {
		Sys.println(firstRun("aab"));
	}

	static function firstRun(text:String):String {
		var pattern:EReg = null;

		// Negative test: the receiver of `match` assigns `pattern`. The Elixir
		// target cannot keep that assignment, so `pattern.matched(1)` would read an
		// unset variable at run time. The compiler must refuse this instead.
		if ((pattern = new EReg("^(a+)", "")).match(text))
			return pattern.matched(1);
		return "none";
	}
}
