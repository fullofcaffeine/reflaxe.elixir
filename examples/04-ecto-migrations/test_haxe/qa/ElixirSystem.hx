package qa;

/** Minimal target boundary for a required runtime environment value. */
@:native("System")
extern class ElixirSystem {
	@:native("fetch_env!")
	static function fetchEnv(name:String):String;
}
