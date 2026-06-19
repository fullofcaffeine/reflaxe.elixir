/*
 * Copyright (C)2005-2025 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package elixir;

import reflaxe.elixir.runtime.HaxeFloat;

/**
 * 1:1 extern mapping to Erlang's :math module
 * 
 * Provides direct access to Erlang's mathematical functions with type safety.
 * This is Layer 2 of the layered architecture - faithful Erlang/Elixir API mappings.
 * 
 * ## Usage Example (Haxe)
 * ```haxe
 * import elixir.ErlangMath;
 * 
 * var result = ErlangMath.sin(Math.PI / 2);  // 1.0
 * var log = ErlangMath.log(10);              // Natural logarithm
 * var sqrt = ErlangMath.sqrt(16);            // 4.0
 * ```
 * 
 * ## Generated Idiomatic Elixir
 * ```elixir
 * result = :math.sin(Reflaxe.Elixir.HaxeFloat.require_finite_native(:math.pi() / 2, ":math.sin/1"))
 * log = :math.log(10)
 * sqrt = :math.sqrt(16)
 * ```
 * 
 * For cross-platform code, use `Math` instead. This module is Elixir-first and
 * intentionally requires finite native BEAM numbers at the boundary.
 * 
 * @see https://www.erlang.org/doc/man/math.html
 */
class ErlangMath {
	static inline function finite(value:Float, boundary:String):Float {
		return HaxeFloat.requireFiniteNative(cast value, boundary);
	}

	// Constants

	/**
	 * Returns the value of π (pi).
	 * Generates: :math.pi()
	 */
	public static inline function pi():Float {
		return untyped __elixir__(":math.pi()");
	}

	/**
	 * Returns the value of e (Euler's number).
	 * Generates: :math.exp(1)
	 */
	public static inline function e():Float {
		return untyped __elixir__(":math.exp(1)");
	}

	// Trigonometric functions

	/**
	 * Returns the sine of x (x in radians).
	 */
	public static inline function sin(x:Float):Float {
		return untyped __elixir__(":math.sin({0})", finite(x, ":math.sin/1"));
	}

	/**
	 * Returns the cosine of x (x in radians).
	 */
	public static inline function cos(x:Float):Float {
		return untyped __elixir__(":math.cos({0})", finite(x, ":math.cos/1"));
	}

	/**
	 * Returns the tangent of x (x in radians).
	 */
	public static inline function tan(x:Float):Float {
		return untyped __elixir__(":math.tan({0})", finite(x, ":math.tan/1"));
	}

	/**
	 * Returns the arc sine of x (result in radians).
	 */
	public static inline function asin(x:Float):Float {
		return untyped __elixir__(":math.asin({0})", finite(x, ":math.asin/1"));
	}

	/**
	 * Returns the arc cosine of x (result in radians).
	 */
	public static inline function acos(x:Float):Float {
		return untyped __elixir__(":math.acos({0})", finite(x, ":math.acos/1"));
	}

	/**
	 * Returns the arc tangent of x (result in radians).
	 */
	public static inline function atan(x:Float):Float {
		return untyped __elixir__(":math.atan({0})", finite(x, ":math.atan/1"));
	}

	/**
	 * Returns the arc tangent of y/x using the signs of both arguments to determine the quadrant.
	 */
	public static inline function atan2(y:Float, x:Float):Float {
		return untyped __elixir__(":math.atan2({0}, {1})", finite(y, ":math.atan2/2"), finite(x, ":math.atan2/2"));
	}

	// Hyperbolic functions

	/**
	 * Returns the hyperbolic sine of x.
	 */
	public static inline function sinh(x:Float):Float {
		return untyped __elixir__(":math.sinh({0})", finite(x, ":math.sinh/1"));
	}

	/**
	 * Returns the hyperbolic cosine of x.
	 */
	public static inline function cosh(x:Float):Float {
		return untyped __elixir__(":math.cosh({0})", finite(x, ":math.cosh/1"));
	}

	/**
	 * Returns the hyperbolic tangent of x.
	 */
	public static inline function tanh(x:Float):Float {
		return untyped __elixir__(":math.tanh({0})", finite(x, ":math.tanh/1"));
	}

	/**
	 * Returns the inverse hyperbolic sine of x.
	 */
	public static inline function asinh(x:Float):Float {
		return untyped __elixir__(":math.asinh({0})", finite(x, ":math.asinh/1"));
	}

	/**
	 * Returns the inverse hyperbolic cosine of x.
	 */
	public static inline function acosh(x:Float):Float {
		return untyped __elixir__(":math.acosh({0})", finite(x, ":math.acosh/1"));
	}

	/**
	 * Returns the inverse hyperbolic tangent of x.
	 */
	public static inline function atanh(x:Float):Float {
		return untyped __elixir__(":math.atanh({0})", finite(x, ":math.atanh/1"));
	}

	// Exponential and logarithmic functions

	/**
	 * Returns e raised to the power of x.
	 */
	public static inline function exp(x:Float):Float {
		return untyped __elixir__(":math.exp({0})", finite(x, ":math.exp/1"));
	}

	/**
	 * Returns the natural logarithm (base e) of x.
	 */
	public static inline function log(x:Float):Float {
		return untyped __elixir__(":math.log({0})", finite(x, ":math.log/1"));
	}

	/**
	 * Returns the base 10 logarithm of x.
	 */
	public static inline function log10(x:Float):Float {
		return untyped __elixir__(":math.log10({0})", finite(x, ":math.log10/1"));
	}

	/**
	 * Returns the base 2 logarithm of x.
	 */
	public static inline function log2(x:Float):Float {
		return untyped __elixir__(":math.log2({0})", finite(x, ":math.log2/1"));
	}

	/**
	 * Returns x raised to the power of y.
	 */
	public static inline function pow(x:Float, y:Float):Float {
		return untyped __elixir__(":math.pow({0}, {1})", finite(x, ":math.pow/2"), finite(y, ":math.pow/2"));
	}

	/**
	 * Returns the square root of x.
	 */
	public static inline function sqrt(x:Float):Float {
		return untyped __elixir__(":math.sqrt({0})", finite(x, ":math.sqrt/1"));
	}

	// Rounding and absolute value

	/**
	 * Returns the smallest integer not less than x.
	 */
	public static inline function ceil(x:Float):Float {
		return untyped __elixir__(":math.ceil({0})", finite(x, ":math.ceil/1"));
	}

	/**
	 * Returns the largest integer not greater than x.
	 */
	public static inline function floor(x:Float):Float {
		return untyped __elixir__(":math.floor({0})", finite(x, ":math.floor/1"));
	}

	/**
	 * Returns the fractional part of x.
	 * The result has the same sign as x.
	 */
	public static inline function fmod(x:Float, y:Float):Float {
		return untyped __elixir__(":math.fmod({0}, {1})", finite(x, ":math.fmod/2"), finite(y, ":math.fmod/2"));
	}

	// Error and gamma functions

	/**
	 * Returns the error function of x.
	 */
	public static inline function erf(x:Float):Float {
		return untyped __elixir__(":math.erf({0})", finite(x, ":math.erf/1"));
	}

	/**
	 * Returns the complementary error function of x.
	 */
	public static inline function erfc(x:Float):Float {
		return untyped __elixir__(":math.erfc({0})", finite(x, ":math.erfc/1"));
	}
}
