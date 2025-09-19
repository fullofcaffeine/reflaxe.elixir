using ArrayTools;
/**
 * Comprehensive Loop Test Suite
 * Tests all forms of loops and iteration to ensure idiomatic Elixir generation
 * 
 * Expected output:
 * - for (i in 0...n) -> Enum.each or for comprehension
 * - for (item in array) -> Enum.each or for comprehension  
 * - while loops -> named recursive functions (NOT Y-combinators)
 * - do-while -> named recursive functions
 * - array.map/filter -> Enum.map/filter
 * - Lambda.fold -> Enum.reduce
 * - break/continue -> proper pattern matching
 */
using Lambda;

class Main {
    static function main() {
        testBasicForLoops();
        testWhileLoops();
        testArrayOperations();
        testNestedLoops();
        testLoopControlFlow();
        testComplexPatterns();
    }
    
    // Test 1: Basic for loops
    static function testBasicForLoops() {
        trace("=== Basic For Loops ===");
        
        // Range iteration
        for (i in 0...10) {
            trace('Index: $i');
        }
        
        // Array iteration
        var fruits = ["apple", "banana", "orange"];
        for (fruit in fruits) {
            trace('Fruit: $fruit');
        }
        
        // Map iteration
        var scores = ["Alice" => 95, "Bob" => 87, "Charlie" => 92];
        for (name => score in scores) {
            trace('$name scored $score');
        }
    }
    
    // Test 2: While loops (should become named recursive functions)
    static function testWhileLoops() {
        trace("=== While Loops ===");
        
        // Basic while
        var i = 0;
        while (i < 5) {
            trace('While: $i');
            i++;
        }
        
        // While with break
        var j = 0;
        while (true) {
            if (j >= 3) break;
            trace('Break at: $j');
            j++;
        }
        
        // While with continue
        var k = 0;
        while (k < 10) {
            k++;
            if (k % 2 != 0) continue;
            trace('Even: $k');
        }
        
        // Do-while
        var m = 0;
        do {
            trace('Do-while: $m');
            m++;
        } while (m < 3);
    }
    
    // Test 3: Array operations (should use Enum functions)
    static function testArrayOperations() {
        trace("=== Array Operations ===");
        
        var numbers = [1, 2, 3, 4, 5];
        
        // Map - should become Enum.map
        var doubled = numbers.map(n -> n * 2);
        trace('Doubled: $doubled');
        
        // Filter - should become Enum.filter
        var evens = numbers.filter(n -> n % 2 == 0);
        trace('Evens: $evens');
        
        // Lambda.fold - should become Enum.reduce
        var sum = Lambda.fold(numbers, (n, acc) -> acc + n, 0);
        trace('Sum with Lambda.fold: $sum');
        
        // Lambda.map - should also become Enum.map
        var tripled = Lambda.map(numbers, n -> n * 3);
        trace('Tripled with Lambda.map: $tripled');
        
        // Lambda.filter - should become Enum.filter
        var odds = Lambda.filter(numbers, n -> n % 2 != 0);
        trace('Odds with Lambda.filter: $odds');
        
        // Chained operations with Lambda
        var result = Lambda.fold(
            Lambda.map(
                Lambda.filter(numbers, n -> n > 2),
                n -> n * 3
            ),
            (n, acc) -> acc + n,
            0
        );
        trace('Chained Lambda result: $result');
        
        // Complex map with conditionals
        var processed = numbers.map(n -> {
            if (n > 3) {
                return n * 10;
            } else {
                return n + 100;
            }
        });
        trace('Processed: $processed');
        
        // Lambda.exists - should become Enum.any?
        var hasEven = Lambda.exists(numbers, n -> n % 2 == 0);
        trace('Has even: $hasEven');
        
        // Lambda.iter - should become Enum.each (foreach doesn't exist, iter is the right method)
        Lambda.iter(numbers, n -> trace('Each: $n'));
        
        // Lambda.find - should become Enum.find
        var found = Lambda.find(numbers, n -> n > 3);
        trace('Found > 3: $found');
        
        // Lambda.count - should become Enum.count
        var countEvens = Lambda.count(numbers, n -> n % 2 == 0);
        trace('Count evens: $countEvens');
    }
    
    // Test 4: Nested loops
    static function testNestedLoops() {
        trace("=== Nested Loops ===");
        
        // Nested for loops
        for (i in 0...3) {
            for (j in 0...2) {
                trace('Nested for: $i, $j');
            }
        }
        
        // Nested while loops
        var outer = 0;
        while (outer < 2) {
            var inner = 0;
            while (inner < 2) {
                trace('Nested while: $outer, $inner');
                inner++;
            }
            outer++;
        }
        
        // Mixed nesting
        for (i in 0...2) {
            var j = 0;
            while (j < 2) {
                trace('Mixed: $i, $j');
                j++;
            }
        }
        
        // Array operations inside loops
        var matrix = [[1, 2], [3, 4], [5, 6]];
        for (row in matrix) {
            var doubled = row.map(n -> n * 2);
            trace('Row doubled: $doubled');
        }
    }
    
    // Test 5: Loop control flow
    static function testLoopControlFlow() {
        trace("=== Loop Control Flow ===");
        
        // Break in nested loops
        for (i in 0...5) {
            for (j in 0...5) {
                if (i + j > 4) break;
                trace('Before break: $i, $j');
            }
        }
        
        // Continue in array operations
        var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        var processed = [];
        for (n in numbers) {
            if (n % 3 == 0) continue;
            processed.push(n * 2);
        }
        trace('Processed with continue: $processed');
        
        // Early return from loop
        function findFirst(arr: Array<Int>, target: Int): Int {
            for (i in 0...arr.length) {
                if (arr[i] == target) {
                    return i;
                }
            }
            return -1;
        }
        
        var index = findFirst([10, 20, 30, 40], 30);
        trace('Found at index: $index');
    }
    
    // Test 6: Complex real-world patterns
    static function testComplexPatterns() {
        trace("=== Complex Patterns ===");
        
        // List comprehension-like pattern
        var pairs = [];
        for (i in 1...4) {
            for (j in 1...4) {
                if (i != j) {
                    pairs.push({x: i, y: j});
                }
            }
        }
        trace('Pairs: $pairs');
        
        // Accumulator pattern
        var data = [1, 2, 3, 4, 5];
        var acc = {sum: 0, count: 0, product: 1};
        for (n in data) {
            acc.sum += n;
            acc.count++;
            acc.product *= n;
        }
        trace('Accumulator: $acc');
        
        // State machine pattern
        var states = ["start", "processing", "done"];
        var currentState = 0;
        var events = ["begin", "work", "work", "finish"];
        
        for (event in events) {
            switch (event) {
                case "begin":
                    if (currentState == 0) currentState = 1;
                case "work":
                    // Stay in processing
                case "finish":
                    if (currentState == 1) currentState = 2;
            }
            trace('State after $event: ${states[currentState]}');
        }
        
        // Real-world: process batch with error handling
        var items = ["valid1", "error", "valid2", "valid3"];
        var results = [];
        var errors = [];
        
        for (item in items) {
            if (item.indexOf("error") >= 0) {
                errors.push('Failed: $item');
                continue;
            }
            results.push('Processed: $item');
        }
        
        trace('Results: $results');
        trace('Errors: $errors');
    }
}