/**
 * Pattern Matching Compilation Test
 * Tests Haxe switch/match expressions → Elixir case statements
 * Converted from framework-based pattern matching tests to snapshot test
 */

enum Color {
    Red;
    Green;
    Blue;
    RGB(r: Int, g: Int, b: Int);
}

enum Option<T> {
    None;
    Some(value: T);
}

class PatternMatchingTest {
    
    /**
     * Basic enum pattern matching
     */
    public static function matchColor(color: Color): String {
        return switch (color) {
            case Red: "red";
            case Green: "green";  
            case Blue: "blue";
            case RGB(r, g, b): "rgb(" + r + "," + g + "," + b + ")";
        };
    }

    /**
     * Option type pattern matching
     */
    public static function matchOption<T>(option: Option<T>): String {
        return switch (option) {
            case None: "none";
            case Some(value): "some(" + Std.string(value) + ")";
        };
    }

    /**
     * Integer pattern matching with guards
     */
    public static function matchInt(value: Int): String {
        return switch (value) {
            case 0: "zero";
            case 1: "one";
            case n if (n < 0): "negative";
            case n if (n > 100): "large";
            case _: "other";
        };
    }

    /**
     * String pattern matching
     */
    public static function matchString(str: String): String {
        return switch (str) {
            case "": "empty";
            case "hello": "greeting";
            case s if (s.length > 10): "long";
            case _: "other";
        };
    }

    /**
     * Array pattern matching
     */
    public static function matchArray(arr: Array<Int>): String {
        return switch (arr) {
            case []: "empty";
            case [x]: "single(" + x + ")";
            case [x, y]: "pair(" + x + "," + y + ")";
            case [x, y, z]: "triple(" + x + "," + y + "," + z + ")";
            case _: "many";
        };
    }

    /**
     * Nested pattern matching
     */
    public static function matchNested(option: Option<Color>): String {
        return switch (option) {
            case None: "no color";
            case Some(Red): "red color";
            case Some(Green): "green color";
            case Some(Blue): "blue color";
            case Some(RGB(r, g, b)) if (r > 128): "bright rgb";
            case Some(RGB(r, g, b)): "dark rgb";
        };
    }

    /**
     * Boolean pattern matching
     */
    public static function matchBool(flag: Bool, count: Int): String {
        return switch ([flag, count]) {
            case [true, 0]: "true zero";
            case [false, 0]: "false zero";
            case [true, n] if (n > 0): "true positive";
            case [false, n] if (n > 0): "false positive";
            case _: "other combination";
        };
    }

    public static function main() {
        // Test entry point for compilation
        trace("Pattern matching compilation test");
    }
}