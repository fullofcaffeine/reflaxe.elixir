class DceMemberOwner {
	public static function anchor():Int
		return 2;

	@:allow(DceMemberCaller)
	private static function first():Int
		return 3;

	@:allow(DceMemberCaller)
	private static function second():Int
		return 4;

	@:allow(DceMemberCaller)
	private static function third():Int
		return 5;
}
