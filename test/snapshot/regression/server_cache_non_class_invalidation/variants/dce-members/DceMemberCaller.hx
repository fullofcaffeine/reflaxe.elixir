class DceMemberCaller {
	var value:Int;

	public static function live():Int
		return 1;

	// Under `-dce full`, each member below is removed while nothing uses it.
	// Edits of DceMemberUser make them live and dead again, and Haxe does not
	// type this class again for those edits.

	public static function relay():Int
		return DceMemberOwner.first() + 1;

	@:allow(DceMemberUser)
	private function new() {
		value = DceMemberOwner.second();
	}

	@:allow(DceMemberUser)
	private function total():Int
		return value + DceMemberOwner.third();
}
