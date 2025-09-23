import haxe.Log;

class Main {
    public static function main() {
        var d = new Date(2024, 0, 15, 10, 30, 45);
        var obj = {
            y: d.getFullYear(),
            m: d.getMonth(),
            dd: d.getDate(),
            dow: d.getDay(),
            hh: d.getHours(),
            mm: d.getMinutes(),
            ss: d.getSeconds()
        };
        Log.trace(Std.string(obj), null);
    }
}

