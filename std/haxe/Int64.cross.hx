package haxe;

using haxe.Int64;

/**
 * Int64 (Elixir target)
 *
 * WHAT
 * - A signed 64-bit integer type with deterministic overflow semantics.
 *
 * WHY
 * - BEAM integers are arbitrary precision, but Haxe `Int64` is explicitly 64-bit.
 * - We want portable Haxe code that expects `Int64` wrapping and bitwise behavior to work on Elixir.
 *
 * HOW
 * - Represented at runtime as a plain Elixir integer.
 * - All operations clamp to signed 64-bit range using bit masking.
 * - `high`/`low` are derived from the 64-bit value.
 */
@:transitive
abstract Int64(Int) from Int to Int {
    private inline function new(v: Int) {
        this = clamp(v);
    }

    static inline function clamp(x: Int): Int {
        // Signed 64-bit clamp:
        // - mask to 64 bits
        // - interpret as signed (two's complement)
        return untyped __elixir__(
            "x = :erlang.band({0}, 18446744073709551615)\n" +
            "if x >= 9223372036854775808, do: x - 18446744073709551616, else: x",
            x
        );
    }

    static inline function unsigned64(x: Int64): Int {
        return untyped __elixir__("if {0} < 0, do: {0} + 18446744073709551616, else: {0}", x);
    }

    public inline function copy(): Int64 {
        return new Int64(this);
    }

    public static inline function make(high: Int32, low: Int32): Int64 {
        var lowUnsigned = untyped __elixir__("if {0} < 0, do: {0} + 4294967296, else: {0}", low);
        var value = untyped __elixir__(":erlang.bsl({0}, 32) + {1}", (high : Int), lowUnsigned);
        return new Int64(value);
    }

    @:from public static inline function ofInt(x: Int): Int64 {
        // Sign-extend the low 32 bits of `x`.
        var i32: Int32 = x;
        var high: Int32 = (i32 >> 31);
        return make(high, i32);
    }

    public static inline function toInt(x: Int64): Int {
        var min: Int64 = Int64.ofInt(-2147483648);
        var max: Int64 = Int64.ofInt(2147483647);
        if (Int64.compare(x, min) < 0 || Int64.compare(x, max) > 0) {
            throw "Overflow";
        }
        return cast x;
    }

    public static inline function isInt64(val: Dynamic): Bool {
        return untyped __elixir__("is_integer({0})", val);
    }

    public static inline function isNeg(x: Int64): Bool {
        return (x : Int) < 0;
    }

    public static inline function isZero(x: Int64): Bool {
        return (x : Int) == 0;
    }

    public static inline function compare(a: Int64, b: Int64): Int {
        var ai: Int = a;
        var bi: Int = b;
        return (ai < bi) ? -1 : (ai > bi ? 1 : 0);
    }

    public static inline function ucompare(a: Int64, b: Int64): Int {
        var au = unsigned64(a);
        var bu = unsigned64(b);
        return (au < bu) ? -1 : (au > bu ? 1 : 0);
    }

    public static inline function toStr(x: Int64): String {
        return untyped __elixir__("Integer.to_string({0})", x);
    }

    public static inline function parseString(s: String): Int64 {
        return Int64Helper.parseString(s);
    }

    public static inline function fromFloat(f: Float): Int64 {
        return Int64Helper.fromFloat(f);
    }

    public static inline function divMod(dividend: Int64, divisor: Int64): {quotient: Int64, modulus: Int64} {
        if ((divisor : Int) == 0) throw "divide by zero";
        var q = untyped __elixir__("div({0}, {1})", dividend, divisor);
        var r = untyped __elixir__("rem({0}, {1})", dividend, divisor);
        return {quotient: new Int64(q), modulus: new Int64(r)};
    }

    @:op(A + B) public static inline function add(a: Int64, b: Int64): Int64 {
        return new Int64((a : Int) + (b : Int));
    }

    @:op(A - B) public static inline function sub(a: Int64, b: Int64): Int64 {
        return new Int64((a : Int) - (b : Int));
    }

    @:op(A * B) public static inline function mul(a: Int64, b: Int64): Int64 {
        return new Int64((a : Int) * (b : Int));
    }

    @:op(A / B) public static inline function div(a: Int64, b: Int64): Float {
        return (a : Int) / (b : Int);
    }

    @:op(A % B) public static inline function mod(a: Int64, b: Int64): Int64 {
        return new Int64(untyped __elixir__("rem({0}, {1})", a, b));
    }

    @:op(-A) public static inline function neg(a: Int64): Int64 {
        return new Int64(-(a : Int));
    }

    @:op(~A) public static inline function complement(a: Int64): Int64 {
        return new Int64(untyped __elixir__(":erlang.bnot({0})", a));
    }

    @:op(A & B) public static inline function and(a: Int64, b: Int64): Int64 {
        return new Int64(untyped __elixir__(":erlang.band({0}, {1})", a, b));
    }

    @:op(A | B) public static inline function or(a: Int64, b: Int64): Int64 {
        return new Int64(untyped __elixir__(":erlang.bor({0}, {1})", a, b));
    }

    @:op(A ^ B) public static inline function xor(a: Int64, b: Int64): Int64 {
        return new Int64(untyped __elixir__(":erlang.bxor({0}, {1})", a, b));
    }

    @:op(A << B) public static inline function shl(a: Int64, b: Int): Int64 {
        var shift = b & 63;
        return new Int64(untyped __elixir__(":erlang.bsl({0}, {1})", a, shift));
    }

    @:op(A >> B) public static inline function shr(a: Int64, b: Int): Int64 {
        var shift = b & 63;
        return new Int64(untyped __elixir__(":erlang.bsr({0}, {1})", a, shift));
    }

    @:op(A >>> B) public static inline function ushr(a: Int64, b: Int): Int64 {
        var shift = b & 63;
        var u = unsigned64(a);
        var shifted = untyped __elixir__(":erlang.bsr({0}, {1})", u, shift);
        return new Int64(shifted);
    }

    public var high(get, never): Int32;
    inline function get_high(): Int32 {
        return Int32.ofInt(untyped __elixir__(":erlang.bsr({0}, 32)", this));
    }

    public var low(get, never): Int32;
    inline function get_low(): Int32 {
        var lowUnsigned = untyped __elixir__(":erlang.band({0}, 4294967295)", this);
        var signed = untyped __elixir__("if {0} >= 2147483648, do: {0} - 4294967296, else: {0}", lowUnsigned);
        return Int32.ofInt(signed);
    }
}
