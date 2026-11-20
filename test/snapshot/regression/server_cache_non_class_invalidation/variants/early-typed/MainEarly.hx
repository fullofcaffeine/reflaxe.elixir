/**
 * Uses one enum and one class that a project initialization macro asks Haxe
 * for before Reflaxe starts (see `run_early_typed_variant`).
 */
class Main {
	static function main():Void {
		Sys.println(CacheNative.label());
	}

	public static function currentStatus():CacheStatus {
		return Ready;
	}
}
