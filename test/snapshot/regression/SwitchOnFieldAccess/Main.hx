package;

import haxe.ds.Option;

class Main {
    static function main() {
        var msg = {type: "test", value: 42};

        // Test 1: Simple switch on field access
        var result1 = parseMessage1(msg);
        trace('Result 1: $result1');

        // Test 2: Switch on field access with early return
        var result2 = parseMessage2(msg);
        trace('Result 2: $result2');
    }

    // Simple switch on field access
    static function parseMessage1(msg: Dynamic): Option<String> {
        return switch (msg.type) {
            case "test": Some("found test");
            case "other": Some("found other");
            case _: None;
        };
    }

    // Switch on field access with early return (like TodoPubSub)
    static function parseMessage2(msg: Dynamic): Option<String> {
        if (msg == null) {
            return None;
        }

        return switch (msg.type) {
            case "test": Some("found test");
            case "other": Some("found other");
            case _: None;
        };
    }
}
