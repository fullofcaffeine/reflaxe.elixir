package;

enum TestEnum {
    Created(content: String);
    Updated(content: String, timestamp: Int);
    Deleted;
}

class Main {
    // Static method with direct switch return - this is what we're fixing
    public static function processEnum(msg: TestEnum): String {
        return switch(msg) {
            case Created(content):
                'Created: $content';
            case Updated(content, ts):
                'Updated at $ts: $content';
            case Deleted:
                'Deleted';
        };
    }

    // Test with variable assignment
    public static function processWithVariable(msg: TestEnum): String {
        var result = switch(msg) {
            case Created(content):
                'Created: $content';
            case Updated(content, ts):
                'Updated at $ts: $content';
            case Deleted:
                'Deleted';
        };
        return result;
    }

    public static function main() {
        trace(processEnum(Created("Hello")));
        trace(processEnum(Updated("World", 1234)));
        trace(processEnum(Deleted));

        trace(processWithVariable(Created("Test")));
    }
}