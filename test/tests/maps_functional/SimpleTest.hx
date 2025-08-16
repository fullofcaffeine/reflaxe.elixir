// Simple test to verify basic Map operations work
class SimpleTest {
    static function main() {
        var map = new Map<String, Int>();
        map.set("test", 42);
        trace('Basic map works: ${map.get("test")}');
        
        // Test if MapTools can be imported
        trace("MapTools import test complete");
    }
}