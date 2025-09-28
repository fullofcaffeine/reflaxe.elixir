// Test for the g2/g3 infrastructure variable issue in for loops with switches
// This reproduces the bug where Haxe generates undefined infrastructure variables
// when a switch expression is inside a for loop
class Main {
    static function main() {
        var items = [
            {id: 1, name: "Item 1"},
            {id: 2, name: "Item 2"},
            {id: 3, name: "Item 3"}
        ];
        
        // This pattern triggers the g2/g3 issue
        for (item in items) {
            var result = processItem(item);
            switch (result) {
                case Ok(processed):
                    trace("Processed: " + processed.name);
                case Error(reason):
                    trace("Failed: " + reason);
            }
        }
    }
    
    static function processItem(item: {id: Int, name: String}): Result<{id: Int, name: String}, String> {
        if (item.id > 0) {
            return Ok(item);
        } else {
            return Error("Invalid ID");
        }
    }
}

enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}