package loop_compilation_tests;

/**
 * BasicLoops: Tests fundamental loop constructs
 * 
 * Covers basic for, while, and do-while loops
 * to establish baseline loop compilation behavior.
 */
class BasicLoops {
    public static function testBasicForLoop(): Array<Int> {
        var result = [];
        for (i in 0...5) {
            result.push(i);
        }
        return result; // [0, 1, 2, 3, 4]
    }
    
    public static function testBasicWhileLoop(): Array<Int> {
        var result = [];
        var i = 0;
        while (i < 5) {
            result.push(i);
            i++;
        }
        return result; // [0, 1, 2, 3, 4]
    }
    
    public static function testDoWhileLoop(): Array<Int> {
        var result = [];
        var i = 0;
        do {
            result.push(i);
            i++;
        } while (i < 5);
        return result; // [0, 1, 2, 3, 4]
    }
    
    public static function testForInArray(): Array<String> {
        var items = ["apple", "banana", "cherry"];
        var result = [];
        for (item in items) {
            result.push(item.toUpperCase());
        }
        return result; // ["APPLE", "BANANA", "CHERRY"]
    }
    
    public static function testReverseForLoop(): Array<Int> {
        var result = [];
        var i = 5;
        while (i > 0) {
            i--;
            result.push(i);
        }
        return result; // [4, 3, 2, 1, 0]
    }
}