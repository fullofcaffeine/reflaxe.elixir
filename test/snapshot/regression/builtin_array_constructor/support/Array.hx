package support;

/** Same short name as the built-in type, but an ordinary user-defined class. */
@:native("ArrayConstructorControl")
class Array {
	public final seed:Int;

	public function new(seed:Int) {
		this.seed = seed;
	}
}
