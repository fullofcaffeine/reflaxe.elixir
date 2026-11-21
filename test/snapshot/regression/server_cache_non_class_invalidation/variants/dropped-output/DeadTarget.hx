// Only the unused DeadLive.viaDead() and, in one step, DeadUser call `m`.
// While nothing live calls it, `-dce full` removes `m`, the module is empty,
// and a fresh build writes no file for this class. Edits of DeadUser make `m`
// live and dead again; Haxe does not type this class again for those edits.
class DeadTarget {
	public static function m():Int
		return 7;
}
