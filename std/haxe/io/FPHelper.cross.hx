package haxe.io;

import reflaxe.elixir.runtime.HaxeFloat;

/**
 * FPHelper (Elixir target)
 *
 * WHAT
 * - Converts between floating point numbers and their binary representations.
 *
 * WHY
 * - Haxe std uses these helpers in IO code (e.g. BytesBuffer) to provide stable
 *   IEEE754 encoding/decoding.
 *
 * HOW
 * - Use Elixir bitstring pattern matching to reinterpret bits (little-endian).
 */
class FPHelper {
	public static function i32ToFloat(i:Int):Float {
		return HaxeFloat.decode32(untyped __elixir__('<<{0}::little-signed-size(32)>>', i));
	}

	public static function floatToI32(f:Float):Int {
		return untyped __elixir__('<<value::little-signed-size(32)>> = {0}; value', HaxeFloat.encode32(cast f));
	}

	public static function i64ToDouble(low:Int, high:Int):Float {
		return HaxeFloat.decode64(untyped __elixir__('<<{0}::little-signed-size(32), {1}::little-signed-size(32)>>', low, high));
	}

	public static function doubleToI64(v:Float):haxe.Int64 {
		return untyped __elixir__('<<value::little-signed-size(64)>> = {0}; value', HaxeFloat.encode64(cast v));
	}
}
