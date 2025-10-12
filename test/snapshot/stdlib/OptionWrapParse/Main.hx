package;

class Main {
    static function main() {}

    // Should wrap to {:some, :ok} | :none
    public static function parseTag(s: String) {
        return switch (s) {
            case "ok": untyped __elixir__(':ok');
            default: untyped __elixir__(':none');
        }
    }

    // Should wrap to {:some, {:ok, Int}} | :none
    public static function parseTuple(n: Int) {
        return switch (n) {
            case 1: untyped __elixir__('{:ok, 1}');
            default: untyped __elixir__(':none');
        }
    }
}

