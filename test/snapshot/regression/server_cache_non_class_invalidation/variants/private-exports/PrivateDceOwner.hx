class PrivateDceOwner {
	public static function anchor():Int
		return 2;

	@:allow(PrivateDceCaller)
	private static function secret():Int
		return 3;
}
