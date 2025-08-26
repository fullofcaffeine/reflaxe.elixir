package loop_compilation_tests;

/**
 * LoopControlFlow: Tests break, continue, and return in loops
 * 
 * Covers control flow statements within loops to ensure
 * proper handling of early exits and skip iterations.
 */
class LoopControlFlow {
    public static function testBreakInFor(): Array<Int> {
        var result = [];
        for (i in 0...10) {
            if (i == 5) break;
            result.push(i);
        }
        return result; // [0, 1, 2, 3, 4]
    }
    
    public static function testBreakInWhile(): Array<Int> {
        var result = [];
        var i = 0;
        while (i < 10) {
            if (i == 5) break;
            result.push(i);
            i++;
        }
        return result; // [0, 1, 2, 3, 4]
    }
    
    public static function testContinueInFor(): Array<Int> {
        var result = [];
        for (i in 0...10) {
            if (i % 2 == 0) continue;
            result.push(i);
        }
        return result; // [1, 3, 5, 7, 9]
    }
    
    public static function testContinueInWhile(): Array<Int> {
        var result = [];
        var i = 0;
        while (i < 10) {
            i++;
            if (i % 2 == 0) continue;
            result.push(i);
        }
        return result; // [1, 3, 5, 7, 9]
    }
    
    public static function testBreakInNested(): Array<Int> {
        var result = [];
        for (i in 0...5) {
            for (j in 0...5) {
                if (j == 3) break; // Only breaks inner loop
                result.push(i * 10 + j);
            }
        }
        return result; // [0, 1, 2, 10, 11, 12, 20, 21, 22, 30, 31, 32, 40, 41, 42]
    }
    
    public static function testReturnFromLoop(): Int {
        for (i in 0...10) {
            if (i == 7) return i;
        }
        return -1; // Should return 7
    }
    
    public static function testMultipleBreakConditions(): Array<Int> {
        var result = [];
        var i = 0;
        while (true) {
            if (i >= 10) break;
            if (i == 5) {
                i += 2;
                continue;
            }
            result.push(i);
            i++;
        }
        return result; // [0, 1, 2, 3, 4, 7, 8, 9]
    }
}