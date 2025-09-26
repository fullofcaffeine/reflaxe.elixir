class DebugMapIter {
    static function main() {
        var map = new Map<String, Int>();
        map.set("one", 1);
        map.set("two", 2);
        
        // This is what we want to understand
        for (key => value in map) {
            trace('$key: $value');
        }
        
        // Compare with regular iteration
        for (value in map) {
            trace(value);
        }
    }
}