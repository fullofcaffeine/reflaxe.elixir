package;

/**
 * UInt — Unsigned 32-bit integer semantics for the Elixir target.
 *
 * WHY
 * - BEAM integers are arbitrary precision, so arithmetic does not overflow at 32 bits.
 * - Haxe UInt semantics (and downstream code like hashing/crypto) expect 32-bit wrap-around.
 *
 * WHAT
 * - Provides a UInt implementation that preserves 32-bit unsigned behavior for:
 *   - arithmetic (+, -, *)
 *   - bitwise ops (~, &, |, ^, <<, >>>)
 *   - unsigned comparisons
 *
 * HOW
 * - Keep the same public surface as Haxe's UInt abstract (UInt<Int>).
 * - Normalize results back into a signed 32-bit representation after operations:
 *   - mask to 0xFFFFFFFF
 *   - if >= 0x80000000 subtract 0x100000000 (two's-complement signed form)
 *
 * Notes
 * - This does not change Int semantics globally. It only ensures UInt stays correct.
 * - We implement unsigned shift right manually because the compiler maps Haxe >>> to Elixir >>>,
 *   which is arithmetic on BEAM. For UInt we must zero-fill.
 */
@:transitive
abstract UInt(Int) from Int to Int {
	private static inline function normalizeSigned32(value:Int):Int {
		return untyped __elixir__('
			case Bitwise.band({0}, 0xFFFFFFFF) do
				v when v >= 0x80000000 -> v - 0x100000000
				v -> v
			end
		', value);
	}

	private inline function toInt():Int {
		return this;
	}

	@:to private inline function toFloat():Float {
		return untyped __elixir__('Bitwise.band({0}, 0xFFFFFFFF) + 0.0', this);
	}

	@:op(A + B) private static inline function add(a:UInt, b:UInt):UInt {
		return normalizeSigned32(a.toInt() + b.toInt());
	}

	@:op(A / B) private static inline function div(a:UInt, b:UInt):Float {
		return a.toFloat() / b.toFloat();
	}

	@:op(A * B) private static inline function mul(a:UInt, b:UInt):UInt {
		return normalizeSigned32(a.toInt() * b.toInt());
	}

	@:op(A - B) private static inline function sub(a:UInt, b:UInt):UInt {
		return normalizeSigned32(a.toInt() - b.toInt());
	}

	@:op(A > B) private static inline function gt(a:UInt, b:UInt):Bool {
		var aNeg = a.toInt() < 0;
		var bNeg = b.toInt() < 0;
		return if (aNeg != bNeg) aNeg else a.toInt() > b.toInt();
	}

	@:op(A >= B) private static inline function gte(a:UInt, b:UInt):Bool {
		var aNeg = a.toInt() < 0;
		var bNeg = b.toInt() < 0;
		return if (aNeg != bNeg) aNeg else a.toInt() >= b.toInt();
	}

	@:op(A < B) private static inline function lt(a:UInt, b:UInt):Bool {
		return gt(b, a);
	}

	@:op(A <= B) private static inline function lte(a:UInt, b:UInt):Bool {
		return gte(b, a);
	}

	@:op(A & B) private static inline function and(a:UInt, b:UInt):UInt {
		return normalizeSigned32(a.toInt() & b.toInt());
	}

	@:op(A | B) private static inline function or(a:UInt, b:UInt):UInt {
		return normalizeSigned32(a.toInt() | b.toInt());
	}

	@:op(A ^ B) private static inline function xor(a:UInt, b:UInt):UInt {
		return normalizeSigned32(a.toInt() ^ b.toInt());
	}

	@:op(A << B) private static inline function shl(a:UInt, b:Int):UInt {
		return untyped __elixir__('
			case Bitwise.band(Bitwise.bsl({0}, Bitwise.band({1}, 31)), 0xFFFFFFFF) do
				v when v >= 0x80000000 -> v - 0x100000000
				v -> v
			end
		', a.toInt(), b);
	}

	@:op(A >> B) private static inline function shr(a:UInt, b:Int):UInt {
		return untyped __elixir__('
			case Bitwise.band(Bitwise.bsr(Bitwise.band({0}, 0xFFFFFFFF), Bitwise.band({1}, 31)), 0xFFFFFFFF) do
				v when v >= 0x80000000 -> v - 0x100000000
				v -> v
			end
		', a.toInt(), b);
	}

	@:op(A >>> B) private static inline function ushr(a:UInt, b:Int):UInt {
		return untyped __elixir__('
			case Bitwise.band(Bitwise.bsr(Bitwise.band({0}, 0xFFFFFFFF), Bitwise.band({1}, 31)), 0xFFFFFFFF) do
				v when v >= 0x80000000 -> v - 0x100000000
				v -> v
			end
		', a.toInt(), b);
	}

	@:op(A % B) private static inline function mod(a:UInt, b:UInt):UInt {
		return untyped __elixir__('
			case Bitwise.band(rem(Bitwise.band({0}, 0xFFFFFFFF), Bitwise.band({1}, 0xFFFFFFFF)), 0xFFFFFFFF) do
				v when v >= 0x80000000 -> v - 0x100000000
				v -> v
			end
		', a.toInt(), b.toInt());
	}

	@:commutative @:op(A + B) private static inline function addWithFloat(a:UInt, b:Float):Float {
		return a.toFloat() + b;
	}

	@:commutative @:op(A * B) private static inline function mulWithFloat(a:UInt, b:Float):Float {
		return a.toFloat() * b;
	}

	@:op(A / B) private static inline function divFloat(a:UInt, b:Float):Float {
		return a.toFloat() / b;
	}

	@:op(A / B) private static inline function floatDiv(a:Float, b:UInt):Float {
		return a / b.toFloat();
	}

	@:op(A - B) private static inline function subFloat(a:UInt, b:Float):Float {
		return a.toFloat() - b;
	}

	@:op(A - B) private static inline function floatSub(a:Float, b:UInt):Float {
		return a - b.toFloat();
	}

	@:op(A > B) private static inline function gtFloat(a:UInt, b:Float):Bool {
		return a.toFloat() > b;
	}

	@:commutative @:op(A == B) private static inline function equalsInt<T:Int>(a:UInt, b:T):Bool {
		return a.toInt() == b;
	}

	@:commutative @:op(A != B) private static inline function notEqualsInt<T:Int>(a:UInt, b:T):Bool {
		return a.toInt() != b;
	}

	@:commutative @:op(A == B) private static inline function equalsFloat<T:Float>(a:UInt, b:T):Bool {
		return a.toFloat() == b;
	}

	@:commutative @:op(A != B) private static inline function notEqualsFloat<T:Float>(a:UInt, b:T):Bool {
		return a.toFloat() != b;
	}

	@:op(A >= B) private static inline function gteFloat(a:UInt, b:Float):Bool {
		return a.toFloat() >= b;
	}

	@:op(A > B) private static inline function floatGt(a:Float, b:UInt):Bool {
		return a > b.toFloat();
	}

	@:op(A >= B) private static inline function floatGte(a:Float, b:UInt):Bool {
		return a >= b.toFloat();
	}

	@:op(A < B) private static inline function ltFloat(a:UInt, b:Float):Bool {
		return a.toFloat() < b;
	}

	@:op(A <= B) private static inline function lteFloat(a:UInt, b:Float):Bool {
		return a.toFloat() <= b;
	}

	@:op(A < B) private static inline function floatLt(a:Float, b:UInt):Bool {
		return a < b.toFloat();
	}

	@:op(A <= B) private static inline function floatLte(a:Float, b:UInt):Bool {
		return a <= b.toFloat();
	}

	@:op(A % B) private static inline function modFloat(a:UInt, b:Float):Float {
		return a.toFloat() % b;
	}

	@:op(A % B) private static inline function floatMod(a:Float, b:UInt):Float {
		return a % b.toFloat();
	}

	@:op(~A) private inline function negBits():UInt {
		return untyped __elixir__('
			case Bitwise.band(Bitwise.bnot({0}), 0xFFFFFFFF) do
				v when v >= 0x80000000 -> v - 0x100000000
				v -> v
			end
		', this);
	}

	@:op(++A) private inline function prefixIncrement():UInt {
		this = normalizeSigned32(this + 1);
		return this;
	}

	@:op(A++) private inline function postfixIncrement():UInt {
		var old = this;
		this = normalizeSigned32(this + 1);
		return old;
	}

	@:op(--A) private inline function prefixDecrement():UInt {
		this = normalizeSigned32(this - 1);
		return this;
	}

	@:op(A--) private inline function postfixDecrement():UInt {
		var old = this;
		this = normalizeSigned32(this - 1);
		return old;
	}

	private inline function toString(?radix:Int):String {
		if (radix == null) {
			return untyped __elixir__('Integer.to_string(Bitwise.band({0}, 0xFFFFFFFF))', this);
		}
		return untyped __elixir__('Integer.to_string(Bitwise.band({0}, 0xFFFFFFFF), {1})', this, radix);
	}
}
