package;

class Main {
    static function main() {}

    public static function testUtcNow(): String {
        // Produce ISO8601 string without Dynamic
        return untyped __elixir__('DateTime.to_iso8601(DateTime.utc_now())');
    }

    public static function passthrough(s: String): String {
        // Ensure typed String flow
        return Date.fromString(s).toString();
    }
}
