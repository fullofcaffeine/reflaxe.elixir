/**
 * Nothing refers to this class. The framework metadata makes module discovery
 * force-type it, so its target module must appear on a warm server too.
 */
@:genserver
class CacheDiscovered {
	public static function label():String
		return "found";
}
