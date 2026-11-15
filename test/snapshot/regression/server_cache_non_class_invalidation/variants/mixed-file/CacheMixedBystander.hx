/**
 * A class that uses nothing from the mixed files. A warm request that edits
 * only a class body in a mixed file must not build this class again.
 */
class CacheMixedBystander {
	public static function label():String {
		return "bystander";
	}
}
