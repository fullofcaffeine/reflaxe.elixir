class Main {
    public static function main() {
        // Test functions with unused parameters
        testUnusedParameters(5, "test", true);
        callbackExample((x, y) -> x);
    }
    
    // Function where middle parameter is not used
    static function testUnusedParameters(used1: Int, unused: String, used2: Bool): Int {
        if (used2) {
            return used1 * 2;
        }
        return used1;
    }
    
    // Callback function where second parameter is unused  
    static function callbackExample(callback: (Int, String) -> Int): Int {
        return callback(42, "ignored");
    }
    
    // Function where all parameters are unused
    static function fullyUnused(x: Int, y: String, z: Bool): String {
        return "constant";
    }
    
    // Instance method with unused parameters
    public function instanceMethod(used: Int, unused1: String, unused2: Bool): Int {
        return used + 10;
    }
}