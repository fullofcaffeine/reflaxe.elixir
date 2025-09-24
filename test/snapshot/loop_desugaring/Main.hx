/**
 * LoopDesugaring Test Suite
 * 
 * Tests various loop patterns to ensure:
 * 1. Infrastructure variables (_g, _g1) are properly initialized
 * 2. Idiomatic Elixir is generated (Enum functions, not reduce_while)
 * 3. Complex patterns like StringTools.urlEncode work correctly
 */
class Main {
    static function main() {
        // Test all loop patterns
        testSimpleForLoop();
        testWhileLoop();
        testArrayMap();
        testArrayFilter();
        testStringIteration();
        testNestedLoops();
        testLoopWithBreak();
        testLoopWithContinue();
    }

    // Pattern 1: Simple counting for loop
    static function testSimpleForLoop(): Void {
        trace("Simple for loop:");
        for (i in 0...5) {
            trace('Iteration $i');
        }
    }

    // Pattern 2: While loop with counter
    static function testWhileLoop(): Int {
        var count = 0;
        var sum = 0;
        while (count < 10) {
            sum += count;
            count++;
        }
        return sum;
    }

    // Pattern 3: Array map operation
    static function testArrayMap(): Array<Int> {
        var numbers = [1, 2, 3, 4, 5];
        return numbers.map(x -> x * 2);
    }

    // Pattern 4: Array filter operation
    static function testArrayFilter(): Array<Int> {
        var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        return numbers.filter(x -> x % 2 == 0);
    }

    // Pattern 5: String iteration (like urlEncode)
    static function testStringIteration(): String {
        var input = "Hello World!";
        var result = "";
        
        for (i in 0...input.length) {
            var c = input.charCodeAt(i);
            if ((c >= 65 && c <= 90) || (c >= 97 && c <= 122) || (c >= 48 && c <= 57)) {
                // Alphanumeric
                result += String.fromCharCode(c);
            } else if (c == 32) {
                // Space
                result += "+";
            } else {
                // Other characters
                result += "%" + StringTools.hex(c, 2).toUpperCase();
            }
        }
        
        return result;
    }

    // Pattern 6: Nested loops
    static function testNestedLoops(): Array<String> {
        var result = [];
        for (i in 0...3) {
            for (j in 0...3) {
                result.push('($i, $j)');
            }
        }
        return result;
    }

    // Pattern 7: Loop with break (early termination)
    static function testLoopWithBreak(): Int {
        var result = -1;
        for (i in 0...100) {
            if (i * i > 50) {
                result = i;
                break;
            }
        }
        return result;
    }

    // Pattern 8: Loop with continue (skip iterations)
    static function testLoopWithContinue(): Array<Int> {
        var result = [];
        for (i in 0...10) {
            if (i % 2 == 0) {
                continue;
            }
            result.push(i);
        }
        return result;
    }
}