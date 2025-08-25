/**
 * Test case for temp_result switch expression compilation bug
 * 
 * This test reproduces the exact issue found in TodoPubSub.topicToString:
 * - Switch expressions that should return values directly
 * - Instead generate temp_result = nil wrapper but case branches return directly
 * - Should either: optimize away the temp_result OR make branches assign to temp_result
 */
enum TestTopic {
    TopicA;
    TopicB;
    TopicC;
}

class Main {
    /**
     * This function should generate clean case expression without temp_result wrapper
     * or if temp_result is used, the branches should assign to it
     */
    private static function topicToString(topic: TestTopic): String {
        return switch (topic) {
            case TopicA: "topic_a";
            case TopicB: "topic_b";  
            case TopicC: "topic_c";
        };
    }
    
    /**
     * Another test - switch in expression context (should be optimized)
     */
    private static function getValue(input: Int): String {
        var result = switch (input) {
            case 1: "one";
            case 2: "two";
            default: "other";
        };
        return result;
    }
    
    public static function main(): Void {
        // Test the functions
        trace(topicToString(TopicA)); // Should print "topic_a"
        trace(getValue(1));           // Should print "one"
    }
}