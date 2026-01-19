package;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Bytes;

class Main {
    public static function main() {
        // Ensure sys.FileSystem API is reachable (compiled + emitted).
        var exists = FileSystem.exists("/tmp");
        if (exists) {
            trace("tmp exists");
        }

        // Ensure sys.io.File API is reachable (compiled + emitted).
        var tmpPath = "/tmp/reflaxe_elixir_stdlib_sys_test.txt";
        File.saveContent(tmpPath, "hello");
        var content = File.getContent(tmpPath);
        trace(content);

        var bytes = Bytes.ofString("bin");
        File.saveBytes(tmpPath, bytes);
        var readBytes = File.getBytes(tmpPath);
        trace(readBytes.length);
    }
}

