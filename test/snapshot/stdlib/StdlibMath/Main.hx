package;

import TestHelper.*;

/**
 * Test Math standard library implementation
 * 
 * Validates that Math generates idiomatic Elixir using :math module
 * and correctly implements the Haxe Math interface.
 */
class Main {
    static function main() {
        var tests = [
            "constants" => testConstants,
            "basic arithmetic" => testBasicArithmetic,
            "trigonometry" => testTrigonometry,
            "logarithms and exponentials" => testLogarithmsAndExponentials,
            "rounding" => testRounding,
            "special values" => testSpecialValues,
            "random" => testRandom,
            "min and max" => testMinMax
        ];
        
        runSuite("Math Tests", tests);
    }
    
    /**
     * Test mathematical constants
     * 
     * Expected Elixir:
     * ```elixir
     * pi = :math.pi()
     * # NEGATIVE_INFINITY = :negative_infinity
     * # POSITIVE_INFINITY = :infinity
     * # NaN = 0.0 / 0.0
     * ```
     */
    static function testConstants() {
        expectsElixir("Math.PI", ":math.pi()");
        
        // PI should be approximately 3.14159
        assertTrue(Math.PI > 3.14159 && Math.PI < 3.14160, "PI value check");
        
        // Test infinity constants
        assertTrue(Math.NEGATIVE_INFINITY < 0, "Negative infinity");
        assertTrue(Math.POSITIVE_INFINITY > 0, "Positive infinity");
        assertTrue(Math.POSITIVE_INFINITY > 1000000, "Positive infinity is larger than any number");
        
        // NaN tests
        assertTrue(Math.isNaN(Math.NaN), "NaN is NaN");
        assertFalse(Math.NaN == Math.NaN, "NaN != NaN");
    }
    
    /**
     * Test basic arithmetic functions
     * 
     * Expected Elixir:
     * ```elixir
     * abs_val = abs(-5.5)
     * sqrt_val = :math.sqrt(16)
     * pow_val = :math.pow(2, 8)
     * ```
     */
    static function testBasicArithmetic() {
        expectsElixir("Math.abs(-5.5)", "abs(-5.5) or if x < 0, -x else x");
        expectsElixir("Math.sqrt(16)", ":math.sqrt(16)");
        expectsElixir("Math.pow(2, 8)", ":math.pow(2, 8)");
        
        assertEquals(5.5, Math.abs(-5.5), "abs(-5.5)");
        assertEquals(5.5, Math.abs(5.5), "abs(5.5)");
        assertEquals(0.0, Math.abs(0.0), "abs(0)");
        
        assertEquals(4.0, Math.sqrt(16), "sqrt(16)");
        assertEquals(5.0, Math.sqrt(25), "sqrt(25)");
        
        assertEquals(256.0, Math.pow(2, 8), "2^8");
        assertEquals(1000.0, Math.pow(10, 3), "10^3");
    }
    
    /**
     * Test trigonometric functions
     * 
     * Expected Elixir:
     * ```elixir
     * sin_val = :math.sin(angle)
     * cos_val = :math.cos(angle)
     * tan_val = :math.tan(angle)
     * atan2_val = :math.atan2(y, x)
     * ```
     */
    static function testTrigonometry() {
        expectsElixir("Math.sin(Math.PI / 2)", ":math.sin(:math.pi() / 2)");
        expectsElixir("Math.cos(0)", ":math.cos(0)");
        expectsElixir("Math.atan2(1, 1)", ":math.atan2(1, 1)");
        
        // sin(π/2) = 1
        var sin90 = Math.sin(Math.PI / 2);
        assertTrue(sin90 > 0.9999 && sin90 <= 1.0001, "sin(π/2) ≈ 1");
        
        // cos(0) = 1
        assertEquals(1.0, Math.cos(0), "cos(0) = 1");
        
        // sin(0) = 0
        assertEquals(0.0, Math.sin(0), "sin(0) = 0");
        
        // tan(π/4) = 1
        var tan45 = Math.tan(Math.PI / 4);
        assertTrue(tan45 > 0.9999 && tan45 < 1.0001, "tan(π/4) ≈ 1");
        
        // Test inverse functions
        var asin = Math.asin(0.5);
        assertTrue(asin > 0.523 && asin < 0.524, "asin(0.5) ≈ π/6");
        
        // atan2 should handle quadrants correctly
        assertTrue(Math.atan2(1, 1) > 0.785 && Math.atan2(1, 1) < 0.786, "atan2(1,1) ≈ π/4");
        assertTrue(Math.atan2(-1, -1) < -2.35 && Math.atan2(-1, -1) > -2.36, "atan2(-1,-1) ≈ -3π/4");
    }
    
    /**
     * Test logarithms and exponentials
     * 
     * Expected Elixir:
     * ```elixir
     * log_val = :math.log(e)  # Natural log
     * exp_val = :math.exp(1)  # e^1
     * ```
     */
    static function testLogarithmsAndExponentials() {
        expectsElixir("Math.log(Math.E)", ":math.log(:math.exp(1))");
        expectsElixir("Math.exp(1)", ":math.exp(1)");
        
        // log(e) = 1
        var e = Math.exp(1);
        var logE = Math.log(e);
        assertTrue(logE > 0.9999 && logE < 1.0001, "log(e) ≈ 1");
        
        // exp(0) = 1
        assertEquals(1.0, Math.exp(0), "exp(0) = 1");
        
        // log(1) = 0
        assertEquals(0.0, Math.log(1), "log(1) = 0");
    }
    
    /**
     * Test rounding functions
     * 
     * Expected Elixir:
     * ```elixir
     * floor_val = :math.floor(3.7)  # Returns 3.0, then cast to int
     * ceil_val = :math.ceil(3.2)    # Returns 4.0, then cast to int
     * round_val = Float.round(3.5)  # Returns 4.0, then cast to int
     * ```
     */
    static function testRounding() {
        expectsElixir("Math.floor(3.7)", "Std.int(:math.floor(3.7))");
        expectsElixir("Math.ceil(3.2)", "Std.int(:math.ceil(3.2))");
        expectsElixir("Math.round(3.5)", "Std.int(Float.round(3.5))");
        
        // Floor tests
        assertEquals(3, Math.floor(3.7), "floor(3.7) = 3");
        assertEquals(3, Math.floor(3.2), "floor(3.2) = 3");
        assertEquals(-4, Math.floor(-3.2), "floor(-3.2) = -4");
        
        // Ceiling tests
        assertEquals(4, Math.ceil(3.2), "ceil(3.2) = 4");
        assertEquals(4, Math.ceil(3.7), "ceil(3.7) = 4");
        assertEquals(-3, Math.ceil(-3.7), "ceil(-3.7) = -3");
        
        // Round tests
        assertEquals(4, Math.round(3.5), "round(3.5) = 4");
        assertEquals(4, Math.round(3.7), "round(3.7) = 4");
        assertEquals(3, Math.round(3.2), "round(3.2) = 3");
        assertEquals(-4, Math.round(-3.5), "round(-3.5) = -4");
        
        // Float versions
        assertEquals(3.0, Math.ffloor(3.7), "ffloor(3.7) = 3.0");
        assertEquals(4.0, Math.fceil(3.2), "fceil(3.2) = 4.0");
        assertEquals(4.0, Math.fround(3.5), "fround(3.5) = 4.0");
    }
    
    /**
     * Test special value handling
     * 
     * Expected Elixir:
     * ```elixir
     * is_nan = (value != value)  # NaN check
     * is_finite = !is_nan && value != :infinity && value != :negative_infinity
     * ```
     */
    static function testSpecialValues() {
        // Test isNaN
        assertTrue(Math.isNaN(Math.NaN), "isNaN(NaN) = true");
        assertTrue(Math.isNaN(0.0 / 0.0), "isNaN(0/0) = true");
        assertFalse(Math.isNaN(1.0), "isNaN(1.0) = false");
        assertFalse(Math.isNaN(Math.POSITIVE_INFINITY), "isNaN(∞) = false");
        
        // Test isFinite
        assertTrue(Math.isFinite(1.0), "isFinite(1.0) = true");
        assertTrue(Math.isFinite(0.0), "isFinite(0.0) = true");
        assertTrue(Math.isFinite(-1000000), "isFinite(-1000000) = true");
        assertFalse(Math.isFinite(Math.POSITIVE_INFINITY), "isFinite(∞) = false");
        assertFalse(Math.isFinite(Math.NEGATIVE_INFINITY), "isFinite(-∞) = false");
        assertFalse(Math.isFinite(Math.NaN), "isFinite(NaN) = false");
    }
    
    /**
     * Test random number generation
     * 
     * Expected Elixir:
     * ```elixir
     * random = :rand.uniform()
     * ```
     */
    static function testRandom() {
        expectsElixir("Math.random()", ":rand.uniform()");
        
        // Test that random returns values in [0, 1)
        for (i in 0...100) {
            var r = Math.random();
            assertTrue(r >= 0.0, "random() >= 0");
            assertTrue(r < 1.0, "random() < 1");
        }
        
        // Test that we get different values (not always the same)
        var r1 = Math.random();
        var r2 = Math.random();
        var r3 = Math.random();
        
        // At least one should be different (statistically almost certain)
        assertTrue(r1 != r2 || r2 != r3 || r1 != r3, "random() produces different values");
    }
    
    /**
     * Test min and max functions
     * 
     * Expected Elixir:
     * ```elixir
     * min_val = if a < b, do: a, else: b
     * max_val = if a > b, do: a, else: b
     * ```
     */
    static function testMinMax() {
        // Min tests
        assertEquals(3.0, Math.min(3, 5), "min(3, 5) = 3");
        assertEquals(3.0, Math.min(5, 3), "min(5, 3) = 3");
        assertEquals(-5.0, Math.min(-5, 3), "min(-5, 3) = -5");
        assertEquals(3.14, Math.min(3.14, 3.14), "min(3.14, 3.14) = 3.14");
        
        // Max tests
        assertEquals(5.0, Math.max(3, 5), "max(3, 5) = 5");
        assertEquals(5.0, Math.max(5, 3), "max(5, 3) = 5");
        assertEquals(3.0, Math.max(-5, 3), "max(-5, 3) = 3");
        assertEquals(3.14, Math.max(3.14, 3.14), "max(3.14, 3.14) = 3.14");
        
        // Edge cases with NaN
        assertTrue(Math.isNaN(Math.min(Math.NaN, 5)), "min(NaN, 5) = NaN");
        assertTrue(Math.isNaN(Math.max(5, Math.NaN)), "max(5, NaN) = NaN");
    }
}