/**
 * Regression: under `-dce full`, the compiler lowers `s.fastCodeAt(i)` and
 * `s.unsafeCodeAt(i)` to calls of `StringTools.fast_code_at/2` and
 * `StringTools.unsafe_code_at/2`. Haxe does not see those calls as uses of
 * `StringTools`, so the two functions must be kept, or the generated call
 * raises an undefined-function error. Nothing else here uses `StringTools`:
 * the compiler adds the class for its helpers.
 *
 * `runtime.exs` checks the values natively.
 */
@:keep
class Main {
	static function main():Void {}

	public static function code(s:String, i:Int):Int {
		return s.fastCodeAt(i);
	}

	public static function unsafeCode(s:String, i:Int):Int {
		return s.unsafeCodeAt(i);
	}
}
