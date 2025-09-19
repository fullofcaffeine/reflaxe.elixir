using ArrayTools;
class Main {
    static function main() {
        var errorMap = new Map<String, Array<String>>();
        var field = "test";
        
        // Test negation of Map.exists
        if (!errorMap.exists(field)) {
            errorMap.set(field, []);
        }
        
        // Test another negation case
        var hasField = errorMap.exists(field);
        if (!hasField) {
            errorMap.set(field, ["value"]);
        }
        
        // Test getting from map
        var values = errorMap.get(field);
        values.push("new value");
        
        trace("Map test completed");
    }
}