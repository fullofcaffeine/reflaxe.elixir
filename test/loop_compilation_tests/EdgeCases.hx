package loop_compilation_tests;

/**
 * EdgeCases: Tests unusual and boundary loop conditions
 * 
 * Covers edge cases like empty loops, single iterations,
 * infinite loops with breaks, and complex conditions.
 */
class EdgeCases {
    public static function testEmptyLoop(): Array<Int> {
        var result = [];
        for (i in 0...0) {
            result.push(i); // Should never execute
        }
        return result; // []
    }
    
    public static function testSingleIteration(): Array<Int> {
        var result = [];
        for (i in 0...1) {
            result.push(i);
        }
        return result; // [0]
    }
    
    public static function testNegativeRange(): Array<Int> {
        var result = [];
        for (i in 5...3) { // Invalid range
            result.push(i);
        }
        return result; // []
    }
    
    public static function testInfiniteWithBreak(): Int {
        var count = 0;
        while (true) {
            count++;
            if (count == 100) break;
        }
        return count; // 100
    }
    
    public static function testEmptyArray(): Array<Int> {
        var empty: Array<Int> = [];
        var result = [];
        for (item in empty) {
            result.push(item);
        }
        return result; // []
    }
    
    public static function testNullCheck(): Array<String> {
        var items: Array<String> = ["a", null, "b", null, "c"];
        var result = [];
        for (item in items) {
            if (item != null) {
                result.push(item);
            }
        }
        return result; // ["a", "b", "c"]
    }
    
    public static function testComplexCondition(): Array<Int> {
        var result = [];
        var i = 0;
        var j = 10;
        while (i < 5 && j > 5) {
            result.push(i + j);
            i++;
            j--;
        }
        return result; // [10, 10, 10, 10, 10]
    }
    
    public static function testNoBodyLoop(): Int {
        var count = 0;
        for (i in 0...10) {
            // Empty body - should still iterate
        }
        while (count < 5) {
            count++; // Minimal body
        }
        return count; // 5
    }
    
    public static function testLargeIteration(): Int {
        var sum = 0;
        for (i in 0...1000) {
            sum += i;
        }
        return sum; // Sum of 0..999
    }
    
    public static function testBreakInElse(): Array<Int> {
        var result = [];
        for (i in 0...10) {
            if (i < 5) {
                result.push(i);
            } else {
                break;
            }
        }
        return result; // [0, 1, 2, 3, 4]
    }
    
    public static function testContinueAsLastStatement(): Array<Int> {
        var result = [];
        for (i in 0...5) {
            result.push(i);
            if (i % 2 == 0) continue; // Continue as last statement
        }
        return result; // [0, 1, 2, 3, 4]
    }
    
    public static function testLoopWithException(): Array<Int> {
        var result = [];
        try {
            for (i in 0...5) {
                result.push(i);
                if (i == 3) throw "Stop";
            }
        } catch (e: String) {
            result.push(-1);
        }
        return result; // [0, 1, 2, 3, -1]
    }
}