/**
 * A generic class. Haxe makes one class for each type argument, here
 * `EarlyBox_String`, and runs no global build macro for that class.
 */
@:generic
class EarlyBox<T> {
	public final value:T;

	public function new(value:T) {
		this.value = value;
	}

	public function describe():String {
		return "box-before";
	}
}
