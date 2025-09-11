package;

/**
 * Test nested array comprehensions and their correct compilation to Elixir
 * 
 * This test validates that nested array comprehensions are properly detected
 * and reconstructed from Haxe's desugared imperative code into idiomatic
 * Elixir for comprehensions.
 * 
 * Expected behavior:
 * - Haxe unrolls constant-range comprehensions into imperative code
 * - Our compiler detects these patterns and reconstructs them
 * - The output should be idiomatic Elixir `for` expressions
 */
class Main {
    public static function simpleNested(): Array<Array<Int>> {
        // Simple 2-level nested comprehension
        var grid = [for (i in 0...3) [for (j in 0...3) i * 3 + j]];
        trace('Simple nested grid: $grid');
        return grid;
    }
    
    public static function constantRangeUnrolled(): Array<Array<Int>> {
        // This will be completely unrolled by Haxe due to constant ranges
        // Tests our ability to detect unrolled blocks
        var unrolled = [for (i in 0...2) [for (j in 0...2) j]];
        trace('Constant range unrolled: $unrolled');
        return unrolled;
    }
    
    public static function nestedWithCondition(): Array<Array<Int>> {
        // Nested comprehension with filter condition
        var filtered = [for (i in 0...4) 
                          [for (j in 0...4) 
                            if ((i + j) % 2 == 0) i * 4 + j]];
        trace('Filtered nested: $filtered');
        return filtered;
    }
    
    public static function deeplyNested(): Array<Array<Array<Int>>> {
        // 3-level deep nesting
        var cube = [for (i in 0...2)
                      [for (j in 0...2)
                        [for (k in 0...2) i * 4 + j * 2 + k]]];
        trace('3D cube: $cube');
        return cube;
    }
    
    public static function fourLevelNesting(): Array<Array<Array<Array<Int>>>> {
        // 4-level deep nesting to test recursion depth
        var hypercube = [for (a in 0...2)
                          [for (b in 0...2)
                            [for (c in 0...2)
                              [for (d in 0...2) a * 8 + b * 4 + c * 2 + d]]]];
        trace('4D hypercube: $hypercube');
        return hypercube;
    }
    
    public static function nestedWithExpression(): Array<Array<String>> {
        // Nested with complex expressions
        var table = [for (row in 0...3)
                       [for (col in 0...3)
                         'R${row}C${col}']];
        trace('String table: $table');
        return table;
    }
    
    public static function nestedWithBlock(): Array<Array<Int>> {
        // Nested with block expressions
        var computed = [for (i in 0...3)
                         [for (j in 0...3) {
                             var temp = i * j;
                             temp + (i + j);
                         }]];
        trace('Block computed: $computed');
        return computed;
    }
    
    public static function mixedConstantVariable(): Array<Array<Int>> {
        // Mix of constant and variable ranges
        var n = 3;
        var mixed = [for (i in 0...n)
                       [for (j in 0...2) i + j]];
        trace('Mixed ranges: $mixed');
        return mixed;
    }
    
    public static function nestedInExpression(): Int {
        // Nested comprehension used in an expression
        var sum = 0;
        var data = [for (i in 0...3) [for (j in 0...3) i + j]];
        for (row in data) {
            for (val in row) {
                sum += val;
            }
        }
        trace('Sum of nested: $sum');
        return sum;
    }
    
    public static function withMetaAndParens(): Array<Array<Int>> {
        // Test that meta and parenthesis wrappers are handled
        @:keep var wrapped = ([for (i in 0...2) ([for (j in 0...2) (i * 2 + j)])]);
        trace('Wrapped comprehension: $wrapped');
        return wrapped;
    }
    
    public static function mixedWithLiterals(): Array<Array<Int>> {
        // Mix comprehensions with literal arrays
        var mixed = [
            [for (i in 0...3) i * 2],
            [10, 20, 30],
            [for (j in 0...3) j + 100]
        ];
        trace('Mixed with literals: $mixed');
        return mixed;
    }
    
    public static function comprehensionFromIterable(): Array<Array<Int>> {
        // Use an array as the iterable source
        var source = [1, 2, 3];
        var fromArray = [for (x in source) [for (y in source) x * y]];
        trace('From iterable: $fromArray');
        return fromArray;
    }
    
    public static function emptyComprehensions(): Array<Array<Int>> {
        // Edge case: empty ranges
        var empty = [for (i in 0...0) [for (j in 0...3) i + j]];
        trace('Empty comprehension: $empty');
        return empty;
    }
    
    public static function singleElementNested(): Array<Array<Int>> {
        // Edge case: single element in each level
        var single = [for (i in 0...1) [for (j in 0...1) i + j]];
        trace('Single element: $single');
        return single;
    }
    
    public static function main() {
        trace("=== Testing Nested Array Comprehensions ===");
        
        simpleNested();
        constantRangeUnrolled();
        nestedWithCondition();
        deeplyNested();
        fourLevelNesting();
        nestedWithExpression();
        nestedWithBlock();
        mixedConstantVariable();
        nestedInExpression();
        withMetaAndParens();
        mixedWithLiterals();
        comprehensionFromIterable();
        emptyComprehensions();
        singleElementNested();
        
        trace("=== All nested comprehension tests complete ===");
    }
}