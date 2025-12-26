// Test LoopBuilder generates idiomatic Elixir patterns
// Should use Enum.each, ranges, and comprehensions instead of reduce_while

class Main {
    public static function main() {
        // Simple range iteration - should generate Enum.each with Range
        trace("Testing range iteration:");
        for (i in 0...5) {
            trace(i);
        }
    }
}