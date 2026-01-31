package haxe;

/**
 * Int32 (Elixir target)
 *
 * WHAT
 * - A 32-bit signed integer type with deterministic overflow semantics.
 *
 * WHY
 * - BEAM integers are arbitrary precision; Haxe `Int32` is explicitly 32-bit.
 * - Some stdlib types (notably `haxe.Int64`) rely on 32-bit wrapping behavior.
 *
 * HOW
 * - Represented at runtime as a plain Elixir integer.
 * - All operations clamp results to signed 32-bit range using bit masking.
 */
@:transitive
abstract Int32(Int) from Int to Int {
    static inline function clamp(x: Int): Int {
        // Signed 32-bit clamp:
        // - mask to 32 bits
        // - interpret as signed (two's complement)
        return untyped __elixir__(
            "x = :erlang.band({0}, 4294967295)\n" +
            "if x >= 2147483648, do: x - 4294967296, else: x",
            x
        );
    }

    @:from public static inline function ofInt(x: Int): Int32 {
        return clamp(x);
    }

    @:to private inline function toInt(): Int {
        return this;
    }

    public static inline function ucompare(a: Int32, b: Int32): Int {
        // Compare as unsigned 32-bit.
        var au = untyped __elixir__("if {0} < 0, do: {0} + 4294967296, else: {0}", a);
        var bu = untyped __elixir__("if {0} < 0, do: {0} + 4294967296, else: {0}", b);
        return (au < bu) ? -1 : (au > bu ? 1 : 0);
    }

    @:op(-A) private inline function negate(): Int32 {
        return clamp(-this);
    }

    @:op(++A) private inline function preIncrement(): Int32 {
        this = clamp(this + 1);
        return this;
    }

    @:op(A++) private inline function postIncrement(): Int32 {
        var ret = this;
        this = clamp(this + 1);
        return ret;
    }

    @:op(--A) private inline function preDecrement(): Int32 {
        this = clamp(this - 1);
        return this;
    }

    @:op(A--) private inline function postDecrement(): Int32 {
        var ret = this;
        this = clamp(this - 1);
        return ret;
    }

    @:op(A + B) private static inline function add(a: Int32, b: Int32): Int32 {
        return clamp((a : Int) + (b : Int));
    }

    @:op(A - B) private static inline function sub(a: Int32, b: Int32): Int32 {
        return clamp((a : Int) - (b : Int));
    }

    @:op(A * B) private static inline function mul(a: Int32, b: Int32): Int32 {
        return clamp((a : Int) * (b : Int));
    }

    @:op(A % B) private static inline function mod(a: Int32, b: Int32): Int32 {
        return clamp(untyped __elixir__("rem({0}, {1})", a, b));
    }

    @:op(~A) private inline function complement(): Int32 {
        return clamp(untyped __elixir__(":erlang.bnot({0})", this));
    }

    @:op(A & B) private static inline function and(a: Int32, b: Int32): Int32 {
        return clamp(untyped __elixir__(":erlang.band({0}, {1})", a, b));
    }

    @:op(A | B) private static inline function or(a: Int32, b: Int32): Int32 {
        return clamp(untyped __elixir__(":erlang.bor({0}, {1})", a, b));
    }

    @:op(A ^ B) private static inline function xor(a: Int32, b: Int32): Int32 {
        return clamp(untyped __elixir__(":erlang.bxor({0}, {1})", a, b));
    }

    @:op(A << B) private static inline function shl(a: Int32, b: Int32): Int32 {
        var shift = (b : Int) & 31;
        return clamp(untyped __elixir__(":erlang.bsl({0}, {1})", a, shift));
    }

    @:op(A >> B) private static inline function shr(a: Int32, b: Int32): Int32 {
        var shift = (b : Int) & 31;
        return clamp(untyped __elixir__(":erlang.bsr({0}, {1})", a, shift));
    }

    @:op(A >>> B) private static inline function ushr(a: Int32, b: Int32): Int32 {
        var shift = (b : Int) & 31;
        var u = untyped __elixir__("if {0} < 0, do: {0} + 4294967296, else: {0}", a);
        var shifted = untyped __elixir__(":erlang.bsr({0}, {1})", u, shift);
        return clamp(shifted);
    }
}

