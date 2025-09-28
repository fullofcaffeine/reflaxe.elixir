package;

enum MessageType {
    Custom(code: String);
    Default(value: Int);
}

class Main {
    static function processMessage(msg: MessageType): String {
        // This generates the problematic g variable pattern
        return switch(msg) {
            case Custom(code): code;
            case Default(value): 'default:$value';
        };
    }
    
    static function main() {
        trace(processMessage(Custom("test")));
        trace(processMessage(Default(42)));
    }
}