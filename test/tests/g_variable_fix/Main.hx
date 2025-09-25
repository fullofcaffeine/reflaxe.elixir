// Test case to verify 'g' temporary pattern variables are properly assigned
class Main {
    static function main() {
        // Test 1: Simple switch with temporary variable
        var msg = {type: "test", data: "hello"};
        var result = switch(msg.type) {
            case "test": msg.data;
            case _: "unknown";
        };
        trace(result);
        
        // Test 2: Pattern matching with enum-like structures
        var value = parseMessage({type: "created", content: "New item"});
        trace(value);
        
        // Test 3: Nested pattern matching
        var data = {status: "ok", value: {inner: 42}};
        var extracted = switch(data.status) {
            case "ok": switch(data.value.inner) {
                case 42: "found";
                case _: "not found";
            };
            case _: "error";
        };
        trace(extracted);
    }
    
    static function parseMessage(msg: {type: String, content: String}): String {
        return switch(msg.type) {
            case "created": "Created: " + msg.content;
            case "updated": "Updated: " + msg.content;
            case _: "Unknown";
        };
    }
}