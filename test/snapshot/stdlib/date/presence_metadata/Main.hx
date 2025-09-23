import haxe.Log;

class Main {
    public static function main() {
        // Build a presence-like metadata map with a timestamp
        var meta = {
            onlineAt: Date.now().getTime(),
            userName: "alice",
            avatar: null
        };
        Log.trace(Std.string(meta), null);
    }
}
