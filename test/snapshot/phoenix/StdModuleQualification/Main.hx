package;

@:native("MyAppWeb.Sample")
class Main {
    static function main() {}

    public static function enumMapGuard(): Int {
        var xs = [1, 2, 3];
        // Should use Enum.map, not MyApp.Enum.map
        var ys = xs.map(function(x) return x + 1);
        return ys[0];
    }

    public static function stringLenGuard(s: String): Int {
        // String functions should remain unqualified
        return s.length;
    }

    public static function reflectMapGet(): Dynamic {
        var m: Dynamic = {};
        // Map access should remain unqualified (Map.get in Elixir)
        return Reflect.field(m, "a");
    }
}

