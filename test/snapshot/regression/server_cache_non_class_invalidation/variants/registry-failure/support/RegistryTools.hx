package support;

/**
 * An application module. With `-D app_name=Cache` it is emitted as
 * `Cache.RegistryTools`, and only this class registers that module name.
 */
class RegistryTools {
	public static function run():Int
		return 1;
}
