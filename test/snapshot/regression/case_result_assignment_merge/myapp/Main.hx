package myapp;

/**
 * Regression: Merge `x = init; case x do ... end` into `x = case init do ... end`.
 *
 * The Haxe source uses a switch-expression assigned to a local variable.
 * The intended Elixir shape is a single assignment whose RHS is a `case`.
 */
class CaseResultAssignmentMergeTest {
    public static function chooseBorder(priority:String):String {
        var border = switch (priority) {
            case "high": "border-red-500";
            case "medium": "border-yellow-500";
            case "low": "border-green-500";
            case _: "border-gray-300";
        };
        return border;
    }
}

class Main {
    static function main() {
        var _ = CaseResultAssignmentMergeTest.chooseBorder("medium");
    }
}

