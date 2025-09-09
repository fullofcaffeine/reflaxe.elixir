import haxe.Log;

class Main {
    public static function main() {
        // Use Log to force dependency on haxe/log.ex and transitively Std
        Log.trace("Hello external bootstrap!", null);
    }
}
