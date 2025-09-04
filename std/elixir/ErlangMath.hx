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
 * result = :math.sin(:math.pi() / 2)
 * log = :math.log(10)
 * sqrt = :math.sqrt(16)
 * ```
 * 
 * For cross-platform code, use std.Math instead, which builds on top of this.
 * 
 * @see https://www.erlang.org/doc/man/math.html
 */
@:native(":math")
extern class ErlangMath {
    // Constants
    /**
     * Returns the value of π (pi).
     * Generates: :math.pi()
     */
    static function pi(): Float;
    
    /**
     * Returns the value of e (Euler's number).
     * Generates: :math.exp(1)
     */
    @:native("exp")
    static function e(): Float;
    
    // Trigonometric functions
    /**
     * Returns the sine of x (x in radians).
     */
    static function sin(x: Float): Float;
    
    /**
     * Returns the cosine of x (x in radians).
     */
    static function cos(x: Float): Float;
    
    /**
     * Returns the tangent of x (x in radians).
     */
    static function tan(x: Float): Float;
    
    /**
     * Returns the arc sine of x (result in radians).
     */
    static function asin(x: Float): Float;
    
    /**
     * Returns the arc cosine of x (result in radians).
     */
    static function acos(x: Float): Float;
    
    /**
     * Returns the arc tangent of x (result in radians).
     */
    static function atan(x: Float): Float;
    
    /**
     * Returns the arc tangent of y/x using the signs of both arguments to determine the quadrant.
     */
    static function atan2(y: Float, x: Float): Float;
    
    // Hyperbolic functions
    /**
     * Returns the hyperbolic sine of x.
     */
    static function sinh(x: Float): Float;
    
    /**
     * Returns the hyperbolic cosine of x.
     */
    static function cosh(x: Float): Float;
    
    /**
     * Returns the hyperbolic tangent of x.
     */
    static function tanh(x: Float): Float;
    
    /**
     * Returns the inverse hyperbolic sine of x.
     */
    static function asinh(x: Float): Float;
    
    /**
     * Returns the inverse hyperbolic cosine of x.
     */
    static function acosh(x: Float): Float;
    
    /**
     * Returns the inverse hyperbolic tangent of x.
     */
    static function atanh(x: Float): Float;
    
    // Exponential and logarithmic functions
    /**
     * Returns e raised to the power of x.
     */
    static function exp(x: Float): Float;
    
    /**
     * Returns the natural logarithm (base e) of x.
     */
    static function log(x: Float): Float;
    
    /**
     * Returns the base 10 logarithm of x.
     */
    static function log10(x: Float): Float;
    
    /**
     * Returns the base 2 logarithm of x.
     */
    static function log2(x: Float): Float;
    
    /**
     * Returns x raised to the power of y.
     */
    static function pow(x: Float, y: Float): Float;
    
    /**
     * Returns the square root of x.
     */
    static function sqrt(x: Float): Float;
    
    // Rounding and absolute value
    /**
     * Returns the smallest integer not less than x.
     */
    static function ceil(x: Float): Float;
    
    /**
     * Returns the largest integer not greater than x.
     */
    static function floor(x: Float): Float;
    
    /**
     * Returns the fractional part of x.
     * The result has the same sign as x.
     */
    static function fmod(x: Float, y: Float): Float;
    
    // Error and gamma functions
    /**
     * Returns the error function of x.
     */
    static function erf(x: Float): Float;
    
    /**
     * Returns the complementary error function of x.
     */
    static function erfc(x: Float): Float;
}