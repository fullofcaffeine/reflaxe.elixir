package loop_compilation_tests;

/**
 * LoopVariables: Tests loop variable scoping and mapping
 * 
 * Covers variable capture, scope issues, and variable
 * naming/mapping in different loop contexts.
 */
class LoopVariables {
    public static function testVariableCapture(): Array<() -> Int> {
        var functions = [];
        for (i in 0...5) {
            functions.push(() -> i);
        }
        return functions; // Each should capture its own i value
    }
    
    public static function testShadowing(): Array<Int> {
        var i = 100;
        var result = [];
        for (i in 0...3) {
            result.push(i);
        }
        result.push(i); // Should be 100 (outer scope)
        return result; // [0, 1, 2, 100]
    }
    
    public static function testMultipleIterators(): Array<Int> {
        var result = [];
        var numbers1 = [1, 2, 3];
        var numbers2 = [4, 5, 6];
        
        for (n1 in numbers1) {
            for (n2 in numbers2) {
                result.push(n1 + n2);
            }
        }
        return result; // [5, 6, 7, 6, 7, 8, 7, 8, 9]
    }
    
    public static function testLoopVariableMutation(): Array<Int> {
        var result = [];
        for (i in 0...5) {
            var j = i;
            j *= 2;
            result.push(j);
        }
        return result; // [0, 2, 4, 6, 8]
    }
    
    public static function testOuterScopeModification(): Array<Int> {
        var result = [];
        var counter = 0;
        for (i in 0...3) {
            counter += i;
            result.push(counter);
        }
        return result; // [0, 1, 3]
    }
    
    public static function testComplexVariableMapping(): Array<String> {
        var result = [];
        var items = [
            {name: "apple", count: 5},
            {name: "banana", count: 3},
            {name: "cherry", count: 8}
        ];
        
        for (item in items) {
            for (i in 0...item.count) {
                result.push(item.name + i);
                if (result.length >= 10) break;
            }
            if (result.length >= 10) break;
        }
        return result;
    }
    
    public static function testVariableReuseAcrossLoops(): Array<Int> {
        var result = [];
        var sum = 0;
        
        for (i in 0...3) {
            sum += i;
        }
        result.push(sum);
        
        for (i in 0...3) {
            sum += i * 2;
        }
        result.push(sum);
        
        return result; // [3, 9]
    }
    
    public static function testLoopInLambda(): Array<Int> {
        var processor = (arr: Array<Int>) -> {
            var result = [];
            for (x in arr) {
                result.push(x * 2);
            }
            return result;
        };
        
        return processor([1, 2, 3, 4]); // [2, 4, 6, 8]
    }
}