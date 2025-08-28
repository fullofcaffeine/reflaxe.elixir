package;

class Main {
    public static function main() {
        testArrayFilterWithOuterVariable();
        testArrayMapWithOuterVariable(); 
        testNestedArrayOperations();
        testMultipleOuterVariables();
    }
    
    static function testArrayFilterWithOuterVariable() {
        var items = ["apple", "banana", "cherry"];
        var targetItem = "banana";
        
        // This should generate: Enum.filter(items, fn item -> item != target_item end)
        // NOT: Enum.filter(items, fn item -> item != item end)
        var filtered = items.filter(function(item) return item != targetItem);
        
        // Similar pattern with field access
        var todos = [{id: 1, name: "first"}, {id: 2, name: "second"}];
        var id = 2;
        
        // Should generate: Enum.filter(todos, fn item -> item.id != id end)  
        // NOT: Enum.filter(todos, fn item -> item.id != item end)
        var filteredTodos = todos.filter(function(item) return item.id != id);
    }
    
    static function testArrayMapWithOuterVariable() {
        var numbers = [1, 2, 3, 4, 5];
        var multiplier = 3;
        
        // Should generate: Enum.map(numbers, fn item -> item * multiplier end)
        // NOT: Enum.map(numbers, fn item -> item * item end)
        var mapped = numbers.map(function(n) return n * multiplier);
        
        // Test with different variable names
        var prefix = "Item: ";
        var prefixed = numbers.map(function(num) return prefix + Std.string(num));
    }
    
    static function testNestedArrayOperations() {
        var data = [[1, 2], [3, 4], [5, 6]];
        var threshold = 3;
        
        // Should preserve both lambda parameters and outer variables
        var processed = data.map(function(arr) {
            return arr.filter(function(val) return val > threshold);
        });
    }
    
    static function testMultipleOuterVariables() {
        var items = ["a", "b", "c", "d"];
        var prefix = "prefix_";
        var suffix = "_suffix";
        var excludeItem = "b";
        
        // Test complex expression with multiple outer scope references
        var result = items
            .filter(function(item) return item != excludeItem)
            .map(function(item) return prefix + item + suffix);
    }
}

// Simple type definitions for testing
typedef Todo = {
    id: Int,
    name: String
}