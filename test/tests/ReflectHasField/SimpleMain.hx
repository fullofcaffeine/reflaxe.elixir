class SimpleMain {
    public static function main() {
        var obj = {
            name: "John",
            age: 30
        };
        
        // Test basic hasField
        var hasName: Bool = Reflect.hasField(obj, "name");
        var hasMissing: Bool = Reflect.hasField(obj, "missing");
        
        trace('Has name: $hasName');
        trace('Has missing: $hasMissing');
    }
}