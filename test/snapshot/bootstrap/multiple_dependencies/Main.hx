import haxe.Log;
import StringTools;

class Main {
    static function main() {
        var numbers = [1, 2, 3];
        var text = Std.string(numbers);
        var trimmed = StringTools.trim("  hello  ");
        Log.trace('Numbers: $text, Trimmed: $trimmed', null);
        
        // Test that we can actually run the generated script
        Sys.println("Bootstrap test complete!");
    }
}