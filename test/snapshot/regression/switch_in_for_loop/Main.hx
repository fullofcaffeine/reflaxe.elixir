// Regression test for undefined g2/g3 variables in switch expressions inside for loops
class Main {
    static function main() {
        var items = [{id: 1, completed: false}, {id: 2, completed: true}];
        
        // This pattern causes undefined g2/g3 in generated Elixir
        for (item in items) {
            var updated = update(item);
            switch (updated) {
                case Ok(result):
                    trace("Updated: " + result.id);
                case Error(msg):
                    trace("Failed: " + msg);
            }
        }
    }
    
    static function update(item: {id: Int, completed: Bool}): Result<{id: Int, completed: Bool}, String> {
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