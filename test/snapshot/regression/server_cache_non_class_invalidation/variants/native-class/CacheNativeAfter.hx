/**
 * A class whose target module name differs from its Haxe path. Haxe renames
 * the class to the native path after typing, which is the case this variant
 * protects on a warm compilation server.
 */
@:native("CacheWeb.NativeLabel")
class CacheNative {
	public static function label():String
		return "native-after";
}
