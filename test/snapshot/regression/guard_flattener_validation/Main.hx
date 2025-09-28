// Test to ensure guard flattener doesn't affect regular case statements
class Main {
    static function main() {
        // Regular case without guards
        var value = 5;
        var result1 = switch(value) {
            case 1: "one";
            case 2: "two";
            case 5: "five";
            case _: "other";
        }
        trace(result1);
        
        // Case with simple guards
        var result2 = switch(value) {
            case x if (x < 3): "small";
            case x if (x < 10): "medium";
            case _: "large";
        }
        trace(result2);
    }
}
