import EarlyMulti;

/**
 * Uses the modules that a project initialization macro asks Haxe for before
 * Reflaxe starts (see `run_early_typed_variant`).
 */
class Main {
	static function main():Void {
		Sys.println(CacheNative.label());
		Sys.println(EarlyMulti.label());
		Sys.println(new EarlyBox<String>("value").describe());
	}

	public static function currentStatus():CacheStatus {
		return Ready;
	}

	public static function kind():EarlyKind {
		return First;
	}

	public static function shapeName(shape:EarlyShape):String {
		return shape.name;
	}

	public static function render(code:EarlyCode):Int {
		return code.render();
	}
}
