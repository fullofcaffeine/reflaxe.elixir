/**
 * ArrayIterator Regression Test
 * 
 * ISSUE: ArrayIterator generated broken Elixir code where function parameters
 * were prefixed with underscore (e.g., _struct) but referenced without underscore
 * in the function body, causing "undefined variable struct" errors.
 * 
 * FIX: Implemented runtime module override pattern where ArrayIterator.hx
 * is a regular class with @:runtimeModule metadata, and runtime/array_iterator.ex
 * provides the correct Elixir implementation.
 * 
 * This test ensures the fix remains stable and covers various ArrayIterator
 * usage patterns to prevent future regressions.
 * 
 * @see runtime/array_iterator.ex for the runtime module implementation
 * @see std/haxe/iterators/ArrayIterator.hx for the Haxe interface
 */
class Main {
    static function main(): Void {
        // Test 1: Basic array iteration with for loop
        basicForLoopIteration();
        
        // Test 2: Manual iterator usage with hasNext() and next()
        manualIteratorUsage();
        
        // Test 3: Nested iterations to test multiple iterator instances
        nestedIterations();
        
        // Test 4: Iterator passed to function
        iteratorAsParameter();
        
        // Test 5: Iterator with different array types
        differentTypeIterations();
    }
    
    static function basicForLoopIteration(): Void {
        var numbers: Array<Int> = [1, 2, 3, 4, 5];
        var sum: Int = 0;
        
        // This uses array.iterator() internally
        for (num in numbers) {
            sum += num;
        }
        
        trace('Sum of numbers: $sum'); // Should be 15
    }
    
    static function manualIteratorUsage(): Void {
        var fruits: Array<String> = ["apple", "banana", "orange"];
        var iterator: haxe.iterators.ArrayIterator<String> = fruits.iterator();
        
        var result: String = "";
        while (iterator.hasNext()) {
            var fruit: String = iterator.next();
            result += fruit + " ";
        }
        
        trace('Fruits: $result');
    }
    
    static function nestedIterations(): Void {
        var matrix: Array<Array<Int>> = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9]
        ];
        
        var total: Int = 0;
        for (row in matrix) {
            for (val in row) {
                total += val;
            }
        }
        
        trace('Matrix total: $total'); // Should be 45
    }
    
    static function iteratorAsParameter(): Void {
        var data: Array<Float> = [1.5, 2.5, 3.5];
        var iter: haxe.iterators.ArrayIterator<Float> = data.iterator();
        
        processIterator(iter);
    }
    
    static function processIterator<T>(iterator: haxe.iterators.ArrayIterator<T>): Void {
        var count: Int = 0;
        while (iterator.hasNext()) {
            var item: T = iterator.next();
            trace('Item $count: $item');
            count++;
        }
    }
    
    static function differentTypeIterations(): Void {
        // Test with boolean array
        var flags: Array<Bool> = [true, false, true];
        var trueCount: Int = 0;
        for (flag in flags) {
            if (flag) trueCount++;
        }
        trace('True count: $trueCount');
        
        // Test with custom type array
        var points: Array<Point> = [
            {x: 1, y: 2},
            {x: 3, y: 4},
            {x: 5, y: 6}
        ];
        
        var totalX: Int = 0;
        for (point in points) {
            totalX += point.x;
        }
        trace('Total X: $totalX'); // Should be 9
    }
}

typedef Point = {
    x: Int,
    y: Int
}