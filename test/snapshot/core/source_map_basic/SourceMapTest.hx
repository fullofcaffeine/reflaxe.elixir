// Basic test for source mapping functionality
class SourceMapTest {
    public function new() {
        // Simple constructor for source mapping test
    }
    
    public function simpleMethod(): String {
        return "test";
    }
    
    public function conditionalMethod(value: Int): Bool {
        if (value > 0) {
            return true;
        } else {
            return false;
        }
    }
    
    public static function main() {
        var test = new SourceMapTest();
        var result = test.simpleMethod();
        var condition = test.conditionalMethod(42);
        trace("Source mapping test: " + result + " " + condition);
    }
}