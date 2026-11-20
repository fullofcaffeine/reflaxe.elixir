class DceMemberUser {
	public static function run():Int
		return DceMemberCaller.relay() + new DceMemberCaller().total();
}
