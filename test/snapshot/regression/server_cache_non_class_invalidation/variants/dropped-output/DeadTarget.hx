// Main keeps this class as a value, so `-dce full` keeps the class and removes
// `m` while nothing calls it. Its module is then empty, and a fresh build
// writes no file for it. Edits of DeadUser make `m` live and dead again; Haxe
// does not type this class again for those edits.
class DeadTarget {
	public static function m():Int
		return 7;
}
