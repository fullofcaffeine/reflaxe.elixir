package probe;

/** Exercise application namespace observation without running a Phoenix server. */
@:phoenixWebModule
class Web {
	public static function static_paths():Array<String> {
		return [];
	}
}
