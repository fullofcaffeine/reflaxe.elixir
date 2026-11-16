/**
 * A Web module. The printer writes `RegistryTools.run()` here as
 * `Cache.RegistryTools.run()` only while the module registry knows
 * `Cache.RegistryTools`.
 */
@:native("CacheWeb.RegistryPage")
class RegistryPage {
	public static function render():Int
		return RegistryToolsNative.run() + 2;
}
