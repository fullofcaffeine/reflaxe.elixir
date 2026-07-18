class Main {
	public static function findOriginal(values:Array<String>, expected:String):String {
		for (value in values) {
			var normalized = value.toLowerCase();
			if (normalized == expected)
				return value;
		}
		return "missing";
	}
}
