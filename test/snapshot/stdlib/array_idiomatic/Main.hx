/**
 * Test Array.hx standard library implementation
 * Verifies that array operations generate idiomatic Elixir code using Enum functions
 */
class Main {
    public static function main() {
        testMapFunction();
        testFilterFunction();
        testConcatFunction();
        testReverseFunction();
        testSortFunction();
        testContainsFunction();
        testIndexOfFunction();
        testJoinFunction();
        testSliceFunction();
        testIteratorFunction();
    }
    
    static function testMapFunction() {
        var numbers = [1, 2, 3, 4, 5];
        
        // Should generate: Enum.map(numbers, fn x -> x * 2 end)
        var doubled = numbers.map(x -> x * 2);
        
        // Should generate: Enum.map(numbers, fn x -> x + 10 end)
        var plusTen = numbers.map(x -> x + 10);
        
        // Nested map - should generate nested Enum.map calls
        var strings = ["hello", "world"];
        var uppercased = strings.map(s -> s.toUpperCase());
        
        trace('Doubled: ${doubled}');
        trace('Plus ten: ${plusTen}');
        trace('Uppercased: ${uppercased}');
    }
    
    static function testFilterFunction() {
        var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        
        // Should generate: Enum.filter(numbers, fn x -> rem(x, 2) == 0 end)
        var evens = numbers.filter(x -> x % 2 == 0);
        
        // Should generate: Enum.filter(numbers, fn x -> x > 5 end)
        var greaterThanFive = numbers.filter(x -> x > 5);
        
        // Combined filter - should generate chained Enum.filter
        var evenAndGreaterThanFive = numbers
            .filter(x -> x % 2 == 0)
            .filter(x -> x > 5);
        
        trace('Evens: ${evens}');
        trace('Greater than 5: ${greaterThanFive}');
        trace('Even and > 5: ${evenAndGreaterThanFive}');
    }
    
    static function testConcatFunction() {
        var first = [1, 2, 3];
        var second = [4, 5, 6];
        var third = [7, 8, 9];
        
        // Should generate: first ++ second
        var combined = first.concat(second);
        
        // Multiple concat - should generate: first ++ second ++ third
        var all = first.concat(second).concat(third);
        
        trace('Combined: ${combined}');
        trace('All: ${all}');
    }
    
    static function testReverseFunction() {
        var numbers = [1, 2, 3, 4, 5];
        var copy = numbers.copy();
        
        // Should generate: Enum.reverse(copy)
        copy.reverse();
        
        trace('Original: ${numbers}');
        trace('Reversed: ${copy}');
    }
    
    static function testSortFunction() {
        var numbers = [5, 2, 8, 1, 9, 3];
        var copy = numbers.copy();
        
        // Should generate: Enum.sort(copy, fn(a, b) -> ... end)
        copy.sort((a, b) -> a - b);
        
        trace('Original: ${numbers}');
        trace('Sorted: ${copy}');
    }
    
    static function testContainsFunction() {
        var numbers = [1, 2, 3, 4, 5];
        
        // Should generate: Enum.member?(numbers, 3)
        var hasThree = numbers.contains(3);
        
        // Should generate: Enum.member?(numbers, 10)
        var hasTen = numbers.contains(10);
        
        trace('Contains 3: ${hasThree}');
        trace('Contains 10: ${hasTen}');
    }
    
    static function testIndexOfFunction() {
        var numbers = [1, 2, 3, 4, 5, 3, 6];
        
        // Should generate: Enum.find_index(numbers, fn item -> item == 3 end) || -1
        var firstThree = numbers.indexOf(3);
        
        // Should generate: Enum.find_index(numbers, fn item -> item == 10 end) || -1
        var notFound = numbers.indexOf(10);
        
        trace('Index of 3: ${firstThree}');
        trace('Index of 10: ${notFound}');
    }
    
    static function testJoinFunction() {
        var words = ["Hello", "Elixir", "World"];
        
        // Should generate: Enum.join(words, " ")
        var sentence = words.join(" ");
        
        // Should generate: Enum.join(words, ", ")
        var csv = words.join(", ");
        
        trace('Sentence: ${sentence}');
        trace('CSV: ${csv}');
    }
    
    static function testSliceFunction() {
        var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        
        // Should generate: Enum.slice(numbers, 2..-1)
        var fromThird = numbers.slice(2);
        
        // Should generate: Enum.slice(numbers, 2..5)
        var middle = numbers.slice(2, 5);
        
        trace('From third: ${fromThird}');
        trace('Middle: ${middle}');
    }
    
    static function testIteratorFunction() {
        var numbers = [1, 2, 3];
        
        // Should work with for loops
        trace("Iterating with for loop:");
        for (n in numbers) {
            trace('  Number: ${n}');
        }
        
        // Should work with iterator
        var iter = numbers.iterator();
        trace("Iterating with iterator:");
        while (iter.hasNext()) {
            trace('  Next: ${iter.next()}');
        }
    }
}