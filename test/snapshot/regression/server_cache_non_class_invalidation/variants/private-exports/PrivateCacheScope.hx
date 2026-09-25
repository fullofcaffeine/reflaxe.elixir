class PrivateCacheScope {
	public static function anchor():Int
		return secret();

	@:allow(Main)
	private static function secret():Int
		return 7;
}
