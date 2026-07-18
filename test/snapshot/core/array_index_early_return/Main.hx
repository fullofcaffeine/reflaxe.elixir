class Main {
	static function preserve(values:Array<String>):Array<String> {
		return values;
	}

	public static function firstOnly(values:Array<String>):String {
		var matches = preserve(values);
		if (matches.length == 1)
			return matches[0];
		return "none";
	}

	public static function embedCapture(captures:Array<String>):String {
		return "[" + captures[2] + "]";
	}
}
