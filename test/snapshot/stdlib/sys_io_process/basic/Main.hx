import sys.io.Process;

class Main {
    public static function main() {
        var p = new Process("sh", ["-c", "printf hello"]);
        var out = p.stdout.readAll().toString();
        var code = p.exitCode();
        p.close();

        var detached = new Process("sh", ["-c", "exit 3"], true);
        var detachedCode = detached.exitCode();
        detached.close();

        trace(out);
        trace(code);
        trace(detachedCode);
    }
}

