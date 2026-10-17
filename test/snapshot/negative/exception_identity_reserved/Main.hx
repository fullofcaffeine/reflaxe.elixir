/** User code must not replace the compiler's exception identity function. */
class Main extends haxe.Exception {
	public function new() {
		super("collision");
	}

	public static function main():Void {
		new Main();
	}

	@:native("__reflaxe_haxe_exception__")
	@:keep
	public static function replacement():Bool {
		return false;
	}
}
