package;

class Main {
    static function main() {}

    public static function testUtcNow(): String {
        // Produce ISO8601 string using typed externs (no Dynamic)
        return elixir.DateTime.utcNow().to_iso8601();
    }

    public static function passthrough(s: String): String {
        // Ensure typed String flow
        return Date.fromString(s).toString();
    }
}
