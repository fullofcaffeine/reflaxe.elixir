package sys;

/**
 * sys.FileStat (Elixir target)
 *
 * WHAT
 * - Haxe stdlib-compatible `FileStat` record returned by `sys.FileSystem.stat`.
 *
 * WHY
 * - Haxe expects `sys.FileSystem.stat/1` to return a record-like structure with
 *   stable field names and types (not an Elixir `%File.Stat{}` struct).
 * - This keeps application code portable while allowing the Elixir target to
 *   implement the underlying filesystem access via BEAM primitives.
 *
 * HOW
 * - `sys.FileSystem.stat` maps Elixir `%File.Stat{}` fields into this typedef.
 * - Times are returned as `Date` (Reflaxe.Elixir's cross-platform `Date`).
 */
typedef FileStat = {
    var gid: Int;
    var uid: Int;
    var atime: Date;
    var mtime: Date;
    var ctime: Date;
    var size: Int;
    var dev: Int;
    var ino: Int;
    var nlink: Int;
    var rdev: Int;
    var mode: Int;
}

