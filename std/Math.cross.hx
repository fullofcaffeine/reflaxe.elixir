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
package;

import elixir.ErlangMath;

/**
 * Mathematical functions and constants for the Elixir target.
 * 
 * Uses Erlang's :math module for mathematical operations.
 * 
 * @see https://api.haxe.org/Math.html
 */
class Math {
    /**
     * The constant PI (π).
     */
    public static inline var PI: Float = 3.141592653589793;
    
    /**
     * A special Float constant which denotes negative infinity.
     */
    // NOTE: The BEAM raises on float overflow and division-by-zero, so we cannot
    // construct IEEE Infinity values at runtime like some Haxe targets do (e.g. 1/0).
    // We approximate infinities with the largest finite float value representable.
    public static inline var NEGATIVE_INFINITY: Float = -1.7976931348623157e308;
    
    /**
     * A special Float constant which denotes positive infinity.
     */
    // See NEGATIVE_INFINITY note above.
    public static inline var POSITIVE_INFINITY: Float = 1.7976931348623157e308;
    
    /**
     * A special Float constant which denotes an invalid number.
     */
    public static inline var NaN: Float = 0.0 / 0.0;
    
    /**
     * Returns the absolute value of v.
     */
    public static inline function abs(v: Float): Float {
        return v < 0 ? -v : v;
    }
    
    /**
     * Returns the smallest integer value that is not less than v.
     */
    public static inline function ceil(v: Float): Int {
        return untyped __elixir__('ceil({0})', v);
    }
    
    /**
     * Returns the largest integer value that is not greater than v.
     */
    public static inline function floor(v: Float): Int {
        return untyped __elixir__('floor({0})', v);
    }
    
    /**
     * Returns the closest integer value to v.
     */
    public static inline function round(v: Float): Int {
        return untyped __elixir__('round({0})', v);
    }
    
    /**
     * Returns the smaller of values a and b.
     */
    public static inline function min(a: Float, b: Float): Float {
        return a < b ? a : b;
    }
    
    /**
     * Returns the greater of values a and b.
     */
    public static inline function max(a: Float, b: Float): Float {
        return a > b ? a : b;
    }
    
    /**
     * Returns the cosine of v (v in radians).
     */
    public static inline function cos(v: Float): Float {
        return untyped __elixir__(':math.cos({0})', v);
    }
    
    /**
     * Returns the sine of v (v in radians).
     */
    public static inline function sin(v: Float): Float {
        return untyped __elixir__(':math.sin({0})', v);
    }
    
    /**
     * Returns the tangent of v (v in radians).
     */
    public static inline function tan(v: Float): Float {
        return untyped __elixir__(':math.tan({0})', v);
    }
    
    /**
     * Returns the arc cosine of v (result in radians).
     */
    public static inline function acos(v: Float): Float {
        return untyped __elixir__(':math.acos({0})', v);
    }
    
    /**
     * Returns the arc sine of v (result in radians).
     */
    public static inline function asin(v: Float): Float {
        return untyped __elixir__(':math.asin({0})', v);
    }
    
    /**
     * Returns the arc tangent of v (result in radians).
     */
    public static inline function atan(v: Float): Float {
        return untyped __elixir__(':math.atan({0})', v);
    }
    
    /**
     * Returns the arc tangent of y/x (result in radians).
     */
    public static inline function atan2(y: Float, x: Float): Float {
        return untyped __elixir__(':math.atan2({0}, {1})', y, x);
    }
    
    /**
     * Returns e raised to the power of v.
     */
    public static inline function exp(v: Float): Float {
        return untyped __elixir__(':math.exp({0})', v);
    }
    
    /**
     * Returns the natural logarithm of v.
     */
    public static inline function log(v: Float): Float {
        return untyped __elixir__(':math.log({0})', v);
    }
    
    /**
     * Returns base raised to the power of exp.
     */
    public static inline function pow(base: Float, exp: Float): Float {
        return untyped __elixir__(':math.pow({0}, {1})', base, exp);
    }
    
    /**
     * Returns the square root of v.
     */
    public static inline function sqrt(v: Float): Float {
        return untyped __elixir__(':math.sqrt({0})', v);
    }
    
    /**
     * Returns a random float in the range [0, 1).
     */
    public static inline function random(): Float {
        return untyped __elixir__(':rand.uniform()');
    }
    
    /**
     * Returns true if v is a finite number.
     */
    public static inline function isFinite(v: Float): Bool {
        return !isNaN(v) && v != POSITIVE_INFINITY && v != NEGATIVE_INFINITY;
    }
    
    /**
     * Returns true if v is NaN.
     */
    public static inline function isNaN(v: Float): Bool {
        return v != v;
    }
    
    /**
     * Returns the integer part of v (removes the fractional part).
     */
    public static inline function ffloor(v: Float): Float {
        return untyped __elixir__(':math.floor({0})', v);
    }
    
    /**
     * Returns the ceiling of v as a Float.
     */
    public static inline function fceil(v: Float): Float {
        return untyped __elixir__(':math.ceil({0})', v);
    }
    
    /**
     * Returns v rounded to the nearest integer as a Float.
     */
    public static inline function fround(v: Float): Float {
        return untyped __elixir__('Float.round({0})', v);
    }
}
