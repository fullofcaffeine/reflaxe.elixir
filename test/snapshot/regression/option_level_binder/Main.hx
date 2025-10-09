package;

import haxe.ds.Option;

class Main {
    public static function main() {}

    // Ensure *_level target leads to {:some, level} pattern and safe body usage
    static function useSwitch(alert_level: Option<Int>): Int {
        return switch (alert_level) {
            case Some(level): level + 1;
            case None: 0;
        }
    }

    // Nested case inside if/else to exercise recursion across EIf → ECase
    static function nested(alert_level: Option<Int>, flag: Bool): String {
        if (flag) {
            return switch (alert_level) {
                case Some(level): "L:" + Std.string(level);
                case None: "N";
            }
        } else {
            return "E";
        }
    }
}

