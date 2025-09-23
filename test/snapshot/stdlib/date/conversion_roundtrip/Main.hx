import haxe.Log;

class Main {
    public static function main() {
        var d = Date.now();
        var iso = d.toString();
        var parsed = Date.fromString(iso);
        Log.trace(Std.string({
            iso: iso,
            y: parsed.getFullYear(),
            m: parsed.getMonth(),
            dd: parsed.getDate()
        }), null);
    }
}
