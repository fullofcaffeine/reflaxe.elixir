// Test case for variable declarations inside nested if statements within loops
// This tests the specific case found in TodoPresence.getUsersEditingTodo
class Main {
    static function main() {
        // Test 1: Simple nested variable declaration in loop
        testSimpleNestedVar();
        
        // Test 2: Reflect.fields pattern with nested variable declaration
        testReflectFieldsNestedVar();
        
        // Test 3: Multiple nested levels
        testDeepNesting();
    }
    
    static function testSimpleNestedVar() {
        trace("Test 1: Simple nested variable in loop");
        var items = [1, 2, 3, 4, 5];
        var results = [];
        var i = 0;
        
        while (i < items.length) {
            var item = items[i];
            i++;
            
            if (item > 2) {
                var doubled = item * 2;  // This variable declaration should be preserved
                if (doubled > 6) {
                    results.push(doubled);  // Use the variable in the body
                }
            }
        }
        
        trace(results);
    }
    
    static function testReflectFieldsNestedVar() {
        trace("Test 2: Reflect.fields with nested variable");
        var data: Dynamic = {
            user1: {status: "active", score: 10},
            user2: {status: "inactive", score: 5},
            user3: {status: "active", score: 15}
        };
        
        var activeHighScorers = [];
        
        for (key in Reflect.fields(data)) {
            var userData = Reflect.field(data, key);
            if (userData.status == "active") {
                var score = userData.score;  // This should be preserved
                if (score > 8) {
                    activeHighScorers.push(key);
                }
            }
        }
        
        trace(activeHighScorers);
    }
    
    static function testDeepNesting() {
        trace("Test 3: Deep nesting levels");
        var matrix = [[1, 2], [3, 4], [5, 6]];
        var found = [];
        var i = 0;
        
        while (i < matrix.length) {
            var row = matrix[i];
            i++;
            
            if (row.length > 0) {
                var j = 0;
                while (j < row.length) {
                    var value = row[j];
                    j++;
                    
                    if (value > 2) {
                        var squared = value * value;  // Deeply nested variable
                        if (squared > 10) {
                            var result = {original: value, squared: squared};  // Another nested variable
                            found.push(result);
                        }
                    }
                }
            }
        }
        
        trace(found);
    }
}