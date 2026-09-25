class Anchored {
	public static function anchor():Int
		return localValue();

	private static function localValue():Int
		return 1;

	@:allow(Reader)
	private static function value():Int
		return 7;
}
