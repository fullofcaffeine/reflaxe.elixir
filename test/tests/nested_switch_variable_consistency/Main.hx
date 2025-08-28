/**
 * Regression test for nested switch variable consistency
 * 
 * This test reproduces a bug where outer switch generates variables
 * with underscore prefix (_parsed_msg) but inner switch references
 * them without prefix (parsed_msg), causing undefined variable errors.
 * 
 * The issue occurs when PatternMatchingCompiler marks extracted
 * variables as unused but doesn't register the modified names.
 */

// Simulate the Option type
enum Option<T> {
    Some(value: T);
    None;
}

// Simulate message types like in todo-app
enum Message {
    TodoCreated(todo: Dynamic);
    TodoUpdated(todo: Dynamic);
    TodoDeleted(id: Int);
    SystemAlert(message: String);
}

class Main {
    
    // Simulate message parsing that returns Option
    static function parseMessage(msg: String): Option<Message> {
        return switch(msg) {
            case "create": Some(TodoCreated({id: 1, title: "Test"}));
            case "update": Some(TodoUpdated({id: 1, title: "Updated"}));
            case "delete": Some(TodoDeleted(1));
            case "alert": Some(SystemAlert("Warning"));
            default: None;
        }
    }
    
    // Main function with nested switch pattern that triggers the bug
    public static function main(): Void {
        var msg = "create";
        
        // This nested switch pattern causes the variable naming issue:
        // Outer switch extracts 'parsedMsg' but marks it as unused
        // Inner switch references 'parsedMsg' expecting consistent naming
        switch(parseMessage(msg)) {
            case Some(parsedMsg):
                // Inner switch uses the extracted variable
                switch(parsedMsg) {
                    case TodoCreated(todo):
                        trace("Todo created: " + todo.title);
                    case TodoUpdated(todo):
                        trace("Todo updated: " + todo.title);
                    case TodoDeleted(id):
                        trace("Todo deleted: " + id);
                    case SystemAlert(message):
                        trace("Alert: " + message);
                }
            case None:
                trace("No message parsed");
        }
    }
}