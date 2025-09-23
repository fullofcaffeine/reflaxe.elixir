import haxe.Log;

class Main {
    public static function main() {
        // Validate Date.now().getTime() compiles inside a map literal
        var meta = {
            onlineAt: Date.now().getTime(),
            userName: "bob"
        };
        Log.trace(Std.string(meta), null);
    }
}

