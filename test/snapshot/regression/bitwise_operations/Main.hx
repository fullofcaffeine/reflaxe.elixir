/**
 * Comprehensive Bitwise Operators Regression Test
 *
 * Validates that all bitwise operators (&&&, |||, ^^^, <<<, >>>)
 * correctly transform to Elixir Bitwise module functions.
 *
 * Background: Elixir requires Bitwise.band(), .bor(), .bxor(), .bsl(), .bsr()
 * instead of custom infix operators.
 */
class Main {
    static function main() {
        testBitwiseAnd();
        testBitwiseOr();
        testBitwiseXor();
        testShiftLeft();
        testShiftRight();
        testNestedOperations();
        testOperatorPrecedence();
        testComplexExpressions();
    }

    /**
     * Test bitwise AND operator (&)
     * Expected: Bitwise.band(left, right)
     */
    static function testBitwiseAnd() {
        var n = 255;

        // Simple AND with literal
        var result1 = n & 15;  // Should generate: Bitwise.band(n, 15)
        trace('AND with literal: $result1');

        // AND with two variables
        var a = 0xFF;
        var b = 0x0F;
        var result2 = a & b;  // Should generate: Bitwise.band(a, b)
        trace('AND with variables: $result2');

        // AND chain
        var result3 = n & 0xF0 & 0x0F;  // Nested band calls
        trace('AND chain: $result3');
    }

    /**
     * Test bitwise OR operator (|)
     * Expected: Bitwise.bor(left, right)
     */
    static function testBitwiseOr() {
        var flags = 0;

        // Simple OR
        var result1 = flags | 1;  // Should generate: Bitwise.bor(flags, 1)
        trace('OR with literal: $result1');

        // OR with multiple flags
        var read = 1;
        var write = 2;
        var result2 = read | write;  // Should generate: Bitwise.bor(read, write)
        trace('OR flags: $result2');

        // OR chain
        var result3 = 1 | 2 | 4 | 8;  // Nested bor calls
        trace('OR chain: $result3');
    }

    /**
     * Test bitwise XOR operator (^)
     * Expected: Bitwise.bxor(left, right)
     */
    static function testBitwiseXor() {
        var x = 0xAA;
        var y = 0x55;

        // Simple XOR
        var result1 = x ^ y;  // Should generate: Bitwise.bxor(x, y)
        trace('XOR: $result1');

        // XOR for toggle
        var flag = true;
        var toggle = flag ? 1 : 0;
        var result2 = toggle ^ 1;  // Should generate: Bitwise.bxor(toggle, 1)
        trace('XOR toggle: $result2');
    }

    /**
     * Test left shift operator (<<)
     * Expected: Bitwise.bsl(left, right)
     */
    static function testShiftLeft() {
        var value = 1;

        // Simple shift left
        var result1 = value << 4;  // Should generate: Bitwise.bsl(value, 4)
        trace('Shift left: $result1');

        // Shift for power of 2
        var result2 = 1 << 8;  // Should generate: Bitwise.bsl(1, 8)
        trace('Shift power: $result2');

        // Variable shift amount
        var shiftBy = 3;
        var result3 = value << shiftBy;  // Should generate: Bitwise.bsl(value, shiftBy)
        trace('Variable shift: $result3');
    }

    /**
     * Test right shift operator (>>)
     * Expected: Bitwise.bsr(left, right)
     */
    static function testShiftRight() {
        var value = 256;

        // Simple shift right
        var result1 = value >> 4;  // Should generate: Bitwise.bsr(value, 4)
        trace('Shift right: $result1');

        // Divide by power of 2
        var result2 = 1024 >> 2;  // Should generate: Bitwise.bsr(1024, 2)
        trace('Shift divide: $result2');

        // Variable shift amount
        var shiftBy = 3;
        var result3 = value >> shiftBy;  // Should generate: Bitwise.bsr(value, shiftBy)
        trace('Variable shift: $result3');
    }

    /**
     * Test nested bitwise operations
     * Validates complex expressions with multiple operators
     */
    static function testNestedOperations() {
        var n = 0xABCD;

        // Extract nibbles using nested operations
        var highNibble = (n >> 12) & 0xF;  // Bitwise.band(Bitwise.bsr(n, 12), 15)
        trace('High nibble: $highNibble');

        // Combine operations
        var result = ((n & 0xFF) << 8) | ((n >> 8) & 0xFF);
        trace('Byte swap: $result');

        // Complex masking
        var masked = (n & 0xFF00) | (n & 0x00FF);
        trace('Complex mask: $masked');
    }

    /**
     * Test operator precedence
     * Ensures parentheses are respected in transformation
     */
    static function testOperatorPrecedence() {
        var a = 0xF0;
        var b = 0x0F;
        var c = 8;

        // AND before OR (no parens needed)
        var result1 = a & b | c;  // Bitwise.bor(Bitwise.band(a, b), c)
        trace('AND before OR: $result1');

        // Force OR before AND with parens
        var result2 = a & (b | c);  // Bitwise.band(a, Bitwise.bor(b, c))
        trace('OR before AND: $result2');

        // Shift has higher precedence
        var result3 = a << 2 & 0xFF;  // Bitwise.band(Bitwise.bsl(a, 2), 255)
        trace('Shift before AND: $result3');
    }

    /**
     * Test bitwise operations in complex expressions
     * Real-world usage patterns like the StringTools hex function
     */
    static function testComplexExpressions() {
        // Simulate hex string generation (from StringTools.hx)
        var n = 255;
        var hexChars = "0123456789ABCDEF";
        var s = "";

        while (n > 0) {
            var digit = n & 15;  // Extract lowest 4 bits: Bitwise.band(n, 15)
            s = hexChars.charAt(digit) + s;
            n = n >> 4;  // Shift right by 4: Bitwise.bsr(n, 4)
        }
        trace('Hex string: $s');

        // Bit field packing
        var r = 255;
        var g = 128;
        var b = 64;
        var rgb = (r << 16) | (g << 8) | b;
        trace('RGB packed: $rgb');

        // Bit field extraction
        var extractedR = (rgb >> 16) & 0xFF;
        var extractedG = (rgb >> 8) & 0xFF;
        var extractedB = rgb & 0xFF;
        trace('RGB extracted: $extractedR, $extractedG, $extractedB');
    }
}
