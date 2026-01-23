package haxe.io;

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
    public static function i32ToFloat(i: Int): Float {
        return untyped __elixir__(
            '<<value::float-little-size(32)>> = <<{0}::little-signed-size(32)>>\nvalue',
            i
        );
    }

    public static function floatToI32(f: Float): Int {
        return untyped __elixir__(
            '<<value::little-signed-size(32)>> = <<{0}::float-little-size(32)>>\nvalue',
            f
        );
    }

    public static function i64ToDouble(low: Int, high: Int): Float {
        return untyped __elixir__(
            '<<value::float-little-size(64)>> = <<{0}::little-signed-size(32), {1}::little-signed-size(32)>>\nvalue',
            low,
            high
        );
    }

    public static function doubleToI64(v: Float): haxe.Int64 {
        return untyped __elixir__(
            '<<value::little-signed-size(64)>> = <<{0}::float-little-size(64)>>\nvalue',
            v
        );
    }
}

