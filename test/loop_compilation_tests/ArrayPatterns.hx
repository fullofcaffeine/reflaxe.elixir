package loop_compilation_tests;

/**
 * ArrayPatterns: Tests array building and transformation patterns
 * 
 * Covers common array patterns that should be optimized
 * to Enum.map, Enum.filter, and other functional constructs.
 */
class ArrayPatterns {
    public static function testSimpleMap(): Array<Int> {
        var numbers = [1, 2, 3, 4, 5];
        var result = [];
        for (n in numbers) {
            result.push(n * 2);
        }
        return result; // [2, 4, 6, 8, 10]
    }
    
    public static function testSimpleFilter(): Array<Int> {
        var numbers = [1, 2, 3, 4, 5, 6, 7, 8];
        var result = [];
        for (n in numbers) {
            if (n % 2 == 0) {
                result.push(n);
            }
        }
        return result; // [2, 4, 6, 8]
    }
    
    public static function testMapFilter(): Array<Int> {
        var numbers = [1, 2, 3, 4, 5, 6];
        var result = [];
        for (n in numbers) {
            if (n % 2 == 0) {
                result.push(n * n);
            }
        }
        return result; // [4, 16, 36]
    }
    
    public static function testArrayComprehension(): Array<Int> {
        // Haxe array comprehension syntax
        var squares = [for (i in 1...6) i * i];
        return squares; // [1, 4, 9, 16, 25]
    }
    
    public static function testConditionalComprehension(): Array<Int> {
        var evenSquares = [for (i in 1...10) if (i % 2 == 0) i * i];
        return evenSquares; // [4, 16, 36, 64]
    }
    
    public static function testNestedComprehension(): Array<Dynamic> {
        var pairs = [for (x in 1...4) for (y in 1...4) if (x != y) {x: x, y: y}];
        return pairs; // All pairs where x != y
    }
    
    public static function testReduce(): Int {
        var numbers = [1, 2, 3, 4, 5];
        var sum = 0;
        for (n in numbers) {
            sum += n;
        }
        return sum; // 15
    }
    
    public static function testFindPattern(): Null<Int> {
        var numbers = [1, 3, 5, 6, 7, 9];
        for (n in numbers) {
            if (n % 2 == 0) {
                return n; // First even number
            }
        }
        return null;
    }
    
    public static function testIndexedIteration(): Array<String> {
        var items = ["a", "b", "c"];
        var result = [];
        for (i in 0...items.length) {
            result.push(items[i] + i);
        }
        return result; // ["a0", "b1", "c2"]
    }
    
    public static function testReverseIteration(): Array<Int> {
        var numbers = [1, 2, 3, 4, 5];
        var result = [];
        var i = numbers.length - 1;
        while (i >= 0) {
            result.push(numbers[i]);
            i--;
        }
        return result; // [5, 4, 3, 2, 1]
    }
}