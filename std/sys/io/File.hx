package sys.io;

import elixir.File as ElixirFile;
import elixir.types.Term;
import haxe.io.Bytes;

/**
 * sys.io.File (Elixir target)
 *
 * WHAT
 * - File IO convenience API compatible with Haxe's `sys.io.File`.
 *
 * WHY
 * - Many Haxe codebases rely on the standard `sys.io.File` API for reading and
 *   writing both text and bytes.
 *
 * HOW
 * - Uses Elixir `File.*!` operations for simple read/write and copy.
 * - Uses `File.open!/2` (via `untyped __elixir__`) to create an Erlang IO device
 *   for streaming read/write handles (`FileInput` / `FileOutput`).
 */
@:native("Sys.IO.File")
class File {
    public static function getContent(path: String): String {
        return ElixirFile.readBang(path);
    }

    public static function saveContent(path: String, content: String): Void {
        ElixirFile.writeBang(path, content);
    }

    public static function getBytes(path: String): Bytes {
        var data = ElixirFile.readBang(path);
        return Bytes.ofData(data);
    }

    public static function saveBytes(path: String, bytes: Bytes): Void {
        ElixirFile.writeBang(path, bytes.getData());
    }

    public static function read(path: String, binary: Bool = true): FileInput {
        var device: Term = openBang(path, binary ? ["read", "binary"] : ["read"]);
        return new FileInput(device);
    }

    public static function write(path: String, binary: Bool = true): FileOutput {
        var device: Term = openBang(path, binary ? ["write", "binary"] : ["write"]);
        return new FileOutput(device);
    }

    public static function append(path: String, binary: Bool = true): FileOutput {
        var device: Term = openBang(path, binary ? ["append", "binary"] : ["append"]);
        return new FileOutput(device);
    }

    public static function update(path: String, binary: Bool = true): FileOutput {
        var device: Term = openBang(path, binary ? ["read", "write", "binary"] : ["read", "write"]);
        return new FileOutput(device);
    }

    public static function copy(srcPath: String, dstPath: String): Void {
        ElixirFile.cpBang(srcPath, dstPath);
    }

    static function openBang(path: String, modes: Array<String>): Term {
        // Translate string flags into Elixir atoms at runtime.
        return untyped __elixir__('
            atom_modes =
              Enum.map({1}, fn
                "read" -> :read
                "write" -> :write
                "append" -> :append
                "binary" -> :binary
                other -> String.to_atom(other)
              end)
            File.open!({0}, atom_modes)
        ', path, modes);
    }
}
