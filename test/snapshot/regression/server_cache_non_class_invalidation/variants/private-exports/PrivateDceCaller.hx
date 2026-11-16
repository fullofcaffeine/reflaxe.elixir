class PrivateDceCaller {
	public static function live():Int
		return 1;

	// Private and unused at first, so `-dce full` removes it. A later edit of
	// PrivateDceUser calls it, while Haxe does not type this class again.

	@:allow(PrivateDceUser)
	private static function relay():Int
		return PrivateDceOwner.secret() + 1;
}
