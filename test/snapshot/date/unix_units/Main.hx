import haxe.Log;

class Main {
    public static function main() {
        var t = Date.now().getTime();
        var d2 = Date.fromTime(t);
        var t2 = d2.getTime();
        Log.trace(Std.string({t: t, t2: t2}), null);
    }
}

