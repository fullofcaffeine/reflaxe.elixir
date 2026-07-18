class Main {
	public static function classify(outer:Bool, inner:Bool):String {
		if (outer) {
			if (inner)
				return "inner";
			return "outer";
		}
		return "fallback";
	}
}
