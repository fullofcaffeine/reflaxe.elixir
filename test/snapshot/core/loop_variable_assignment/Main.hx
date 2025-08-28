// Test loop variable assignment and immutability handling
// This tests how loop results are assigned to variables in Elixir

class Main {
    public static function main() {
        // Test 1: Simple for loop result assignment
        var numbers = [1, 2, 3, 4, 5];
        var doubled = [for (n in numbers) n * 2];
        trace('Doubled: $doubled');
        
        // Test 2: For loop with filter (array comprehension)
        var evens = [for (n in numbers) if (n % 2 == 0) n];
        trace('Evens: $evens');
        
        // Test 3: Nested for loops
        var pairs = [for (x in [1, 2]) 
                       for (y in ['a', 'b']) 
                           {x: x, y: y}];
        trace('Pairs: $pairs');
        
        // Test 4: While loop with result collection
        var i = 0;
        var collected = [];
        while (i < 5) {
            collected.push(i * i);
            i++;
        }
        trace('Collected squares: $collected');
        
        // Test 5: Do-while loop
        var j = 0;
        var results = [];
        do {
            results.push(j);
            j++;
        } while (j < 3);
        trace('Do-while results: $results');
        
        // Test 6: Loop with mutable accumulator
        var sum = 0;
        for (n in numbers) {
            sum += n;
        }
        trace('Sum: $sum');
        
        // Test 7: Loop modifying external array
        var output = [];
        for (n in numbers) {
            if (n > 2) {
                output.push(n);
            }
        }
        trace('Filtered output: $output');
    }
}