package sys;

import elixir.File;
import elixir.Path;
import elixir.DateTime.NaiveDateTime;
import elixir.DateTime.DateTime;
import elixir.types.Term;

/**
 * sys.FileSystem (Elixir target)
 *
 * WHAT
 * - BEAM-backed implementation of Haxe's `sys.FileSystem` API.
 *
 * WHY
 * - The Haxe stdlib models filesystem access through `sys.*`.
 * - For Reflaxe.Elixir, we want Haxe code to be able to use the familiar `sys.*`
 *   APIs while mapping cleanly to Elixir/Erlang primitives (`File`, `Path`, `:file`).
 *
 * HOW
 * - Delegates to Elixir `File` / `Path` for most operations.
 * - `fullPath` uses `File.realpath!/1` to resolve symlinks when possible.
 * - `stat` converts `%File.Stat{}` into Haxe's `sys.FileStat` record.
 */
class FileSystem {
    public static function exists(path: String): Bool {
        return File.exists(path);
    }

    public static function rename(path: String, newPath: String): Void {
        File.renameBang(path, newPath);
    }

    public static function stat(path: String): FileStat {
        var statStruct: Term = File.statBang(path);
        return {
            gid: cast untyped __elixir__('Map.fetch!({0}, :gid)', statStruct),
            uid: cast untyped __elixir__('Map.fetch!({0}, :uid)', statStruct),
            atime: toUtcDate(untyped __elixir__('Map.fetch!({0}, :atime)', statStruct)),
            mtime: toUtcDate(untyped __elixir__('Map.fetch!({0}, :mtime)', statStruct)),
            ctime: toUtcDate(untyped __elixir__('Map.fetch!({0}, :ctime)', statStruct)),
            size: cast untyped __elixir__('Map.fetch!({0}, :size)', statStruct),
            dev: cast untyped __elixir__('Map.fetch!({0}, :dev)', statStruct),
            ino: cast untyped __elixir__('Map.fetch!({0}, :ino)', statStruct),
            nlink: cast untyped __elixir__('Map.fetch!({0}, :nlink)', statStruct),
            rdev: cast untyped __elixir__('Map.fetch!({0}, :rdev)', statStruct),
            mode: cast untyped __elixir__('Map.fetch!({0}, :mode)', statStruct),
        };
    }

    public static function fullPath(relPath: String): String {
        return File.realpathBang(relPath);
    }

    public static function absolutePath(relPath: String): String {
        return Path.expand(relPath);
    }

    public static function isDirectory(path: String): Bool {
        var statStruct: Term = File.statBang(path);
        return untyped __elixir__('Map.fetch!({0}, :type) == :directory', statStruct);
    }

    public static function createDirectory(path: String): Void {
        File.mkdirRecursiveBang(path);
    }

    public static function deleteFile(path: String): Void {
        File.rmBang(path);
    }

    public static function deleteDirectory(path: String): Void {
        File.rmdirBang(path);
    }

    public static function readDirectory(path: String): Array<String> {
        return File.lsBang(path);
    }

    static function toUtcDate(erlDatetime: Term): Date {
        var naive = NaiveDateTime.fromErlBang(erlDatetime);
        return DateTime.fromNaiveBang(naive, "Etc/UTC");
    }
}
