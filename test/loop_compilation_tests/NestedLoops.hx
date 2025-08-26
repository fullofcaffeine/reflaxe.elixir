package loop_compilation_tests;

/**
 * NestedLoops: Tests nested loop constructs
 * 
 * Covers various nested loop patterns including
 * for-in-for, while-in-while, and mixed nesting.
 */
class NestedLoops {
    public static function testNestedForLoops(): Array<Array<Int>> {
        var result = [];
        for (i in 0...3) {
            var row = [];
            for (j in 0...3) {
                row.push(i * 3 + j);
            }
            result.push(row);
        }
        return result; // [[0, 1, 2], [3, 4, 5], [6, 7, 8]]
    }
    
    public static function testNestedWhileLoops(): Array<Array<Int>> {
        var result = [];
        var i = 0;
        while (i < 3) {
            var row = [];
            var j = 0;
            while (j < 3) {
                row.push(i * 3 + j);
                j++;
            }
            result.push(row);
            i++;
        }
        return result; // [[0, 1, 2], [3, 4, 5], [6, 7, 8]]
    }
    
    public static function testMixedNesting(): Array<Int> {
        var result = [];
        for (i in 0...3) {
            var j = 0;
            while (j < 2) {
                result.push(i * 10 + j);
                j++;
            }
        }
        return result; // [0, 1, 10, 11, 20, 21]
    }
    
    public static function testTripleNesting(): Array<Int> {
        var result = [];
        for (i in 0...2) {
            for (j in 0...2) {
                var k = 0;
                while (k < 2) {
                    result.push(i * 100 + j * 10 + k);
                    k++;
                }
            }
        }
        return result; // [0, 1, 10, 11, 100, 101, 110, 111]
    }
    
    public static function testNestedWithBreak(): Array<Int> {
        var result = [];
        for (i in 0...5) {
            for (j in 0...5) {
                if (i * j > 6) break;
                result.push(i * 10 + j);
            }
        }
        return result;
    }
}