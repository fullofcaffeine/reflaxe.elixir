// Comprehensive test for infrastructure variable elimination
// Tests ALL patterns where g, g1, g2, _g variables appear

class Main {
    static function main() {
        // Test 1: Simple switch statements
        testBasicSwitch();
        
        // Test 2: Array operations with indexing
        testArrayOperations();
        
        // Test 3: Nested loops and iterations
        testNestedLoops();
        
        // Test 4: Enum.filter with bracket access
        testFilterWithIndexing();
        
        // Test 5: Map iterator patterns
        testMapIterator();
        
        // Test 6: Result pattern matching
        testResultPatternMatching();
        
        // Test 7: PubSub message parsing patterns
        testMessageParsing();
        
        // Test 8: Mixed patterns from real code
        testMixedRealWorldPatterns();
    }
    
    // Test 1: Basic switch statements
    static function testBasicSwitch() {
        var msg = {type: "test", data: "hello"};
        var result = switch(msg.type) {
            case "test": msg.data;
            case _: "unknown";
        };
        trace('Basic switch result: $result');
    }
    
    // Test 2: Array operations with indexing 
    static function testArrayOperations() {
        var items = ["a", "b", "c", "d"];
        
        // Simple map with index access
        var mapped = items.map(function(item) {
            return item.toUpperCase();
        });
        trace('Mapped: ${mapped.join(", ")}');
        
        // Filter with array indexing
        var numbers = [1, 2, 3, 4, 5];
        var filtered = numbers.filter(function(n) {
            return n > 2;
        });
        trace('Filtered: ${filtered.join(", ")}');
    }
    
    // Test 3: Nested loops
    static function testNestedLoops() {
        var matrix = [[1, 2], [3, 4], [5, 6]];
        var result = [];
        
        for (row in matrix) {
            for (item in row) {
                result.push(item * 2);
            }
        }
        trace('Nested loop result: ${result.join(", ")}');
    }
    
    // Test 4: Filter with bracket notation
    static function testFilterWithIndexing() {
        var items = [{id: 1, name: "one"}, {id: 2, name: "two"}, {id: 3, name: "three"}];
        var names = [];
        
        // This pattern generates g variables in current compiler
        for (i in 0...items.length) {
            var item = items[i];
            if (item.id > 1) {
                names.push(item.name);
            }
        }
        trace('Names with id > 1: ${names.join(", ")}');
    }
    
    // Test 5: Map iterator (from todo-app)
    static function testMapIterator() {
        var userMap = new Map<Int, String>();
        userMap.set(1, "Alice");
        userMap.set(2, "Bob");
        userMap.set(3, "Charlie");
        
        var result = [];
        for (key => value in userMap) {
            result.push('$key: $value');
        }
        trace('Map iteration: ${result.join(", ")}');
    }
    
    // Test 6: Result pattern matching (Repo operations)
    static function testResultPatternMatching() {
        var results = [
            {status: "ok", value: 42},
            {status: "error", value: -1}
        ];
        
        for (result in results) {
            var output = switch(result.status) {
                case "ok": 'Success: ${result.value}';
                case "error": 'Failed: ${result.value}';
                case _: "Unknown";
            };
            trace(output);
        }
    }
    
    // Test 7: Message parsing (from PubSub)
    static function testMessageParsing() {
        var messages = [
            {type: "created", content: "New item"},
            {type: "updated", content: "Changed item"},
            {type: "deleted", content: "Removed item"}
        ];
        
        var parsed = messages.map(function(msg) {
            return switch(msg.type) {
                case "created": 'Created: ${msg.content}';
                case "updated": 'Updated: ${msg.content}';
                case "deleted": 'Deleted: ${msg.content}';
                case _: "Unknown message";
            };
        });
        
        for (p in parsed) {
            trace(p);
        }
    }
    
    // Test 8: Complex real-world pattern
    static function testMixedRealWorldPatterns() {
        // Simulate finding an item in array (generates g variables)
        var todos = [
            {id: 1, title: "First", completed: false},
            {id: 2, title: "Second", completed: true},
            {id: 3, title: "Third", completed: false}
        ];
        
        // Find by id pattern
        var targetId = 2;
        var found = null;
        for (i in 0...todos.length) {
            if (todos[i].id == targetId) {
                found = todos[i];
                break;
            }
        }
        
        if (found != null) {
            trace('Found todo: ${found.title}');
        }
        
        // Count pattern
        var completedCount = 0;
        for (todo in todos) {
            if (todo.completed) {
                completedCount++;
            }
        }
        trace('Completed todos: $completedCount');
        
        // Transform and collect pattern  
        var titles = [];
        for (todo in todos) {
            if (!todo.completed) {
                titles.push(todo.title.toUpperCase());
            }
        }
        trace('Pending todo titles: ${titles.join(", ")}');
    }
}