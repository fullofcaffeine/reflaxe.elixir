package;

using StringTools;

class Main {
    public static function main() {
        var _ = s();
    }

    static function s(): String {
        var a = "  hi  ";
        var b = a.trim();
        var c = StringTools.lpad("7", "0", 3);
        return b + ":" + c;
    }
}
