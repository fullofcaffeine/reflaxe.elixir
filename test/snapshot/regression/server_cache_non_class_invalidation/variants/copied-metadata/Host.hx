/** `Gen.build` defines `HostCompanion` from the text that `v` returns. */
@:build(Gen.build())
class Host {
	public static function v():String
		return "host-before";
}
