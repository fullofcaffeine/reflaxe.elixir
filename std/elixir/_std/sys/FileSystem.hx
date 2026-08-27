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
 * - `fullPath` walks each path component with `File.lstat!/1` and
 *   `File.read_link!/1` so intermediate and relative symlinks resolve.
 * - `stat` converts `%File.Stat{}` into Haxe's `sys.FileStat` record.
 */
class FileSystem {
	public static function exists(path:String):Bool {
		return File.exists(path);
	}

	public static function rename(path:String, newPath:String):Void {
		File.renameBang(path, newPath);
	}

	public static function stat(path:String):FileStat {
		var statStruct:Term = File.statBang(path);
		return {
			gid: cast untyped __elixir__('Map.fetch!({0}, :gid)', statStruct),
			uid: cast untyped __elixir__('Map.fetch!({0}, :uid)', statStruct),
			atime: toUtcDate(untyped __elixir__('Map.fetch!({0}, :atime)', statStruct)),
			mtime: toUtcDate(untyped __elixir__('Map.fetch!({0}, :mtime)', statStruct)),
			ctime: toUtcDate(untyped __elixir__('Map.fetch!({0}, :ctime)', statStruct)),
			size: cast untyped __elixir__('Map.fetch!({0}, :size)', statStruct),
			// File.Stat exposes the portable device values as major/minor parts.
			dev: cast untyped __elixir__('Map.fetch!({0}, :major_device)', statStruct),
			ino: cast untyped __elixir__('Map.fetch!({0}, :inode)', statStruct),
			nlink: cast untyped __elixir__('Map.fetch!({0}, :links)', statStruct),
			rdev: cast untyped __elixir__('Map.fetch!({0}, :minor_device)', statStruct),
			mode: cast untyped __elixir__('Map.fetch!({0}, :mode)', statStruct),
		};
	}

	public static function fullPath(relPath:String):String {
		return resolveExistingPath(Path.expand(relPath), 0);
	}

	public static function absolutePath(relPath:String):String {
		return Path.expand(relPath);
	}

	public static function isDirectory(path:String):Bool {
		var statStruct:Term = File.statBang(path);
		return untyped __elixir__('Map.fetch!({0}, :type) == :directory', statStruct);
	}

	public static function createDirectory(path:String):Void {
		File.mkdirRecursiveBang(path);
	}

	public static function deleteFile(path:String):Void {
		File.rmBang(path);
	}

	public static function deleteDirectory(path:String):Void {
		File.rmdirBang(path);
	}

	public static function readDirectory(path:String):Array<String> {
		return File.lsBang(path);
	}

	static function toUtcDate(erlDatetime:Term):Date {
		var naive = NaiveDateTime.fromErlBang(erlDatetime);
		return DateTime.fromNaiveBang(naive, "Etc/UTC");
	}

	/**
	 * Resolve every symlink in an existing absolute path.
	 *
	 * `File.lstatBang` preserves native missing and inaccessible-path errors.
	 * A 40-link cap matches common operating-system limits and rejects cycles.
	 */
	static function resolveExistingPath(absolutePath:String, followedLinks:Int):String {
		if (followedLinks >= 40) {
			throw haxe.io.Error.Custom("Too many symbolic links while resolving " + absolutePath);
		}

		var components = Path.split(absolutePath);
		return resolveComponent(components, 1, components[0], followedLinks);
	}

	static function resolveComponent(components:Array<String>, index:Int, current:String, followedLinks:Int):String {
		if (index >= components.length) {
			return current;
		}

		var next = Path.joinTwo(current, components[index]);
		var statStruct:Term = File.lstatBang(next);
		var isSymlink:Bool = untyped __elixir__('Map.fetch!({0}, :type) == :symlink', statStruct);
		if (!isSymlink) {
			return resolveComponent(components, index + 1, next, followedLinks);
		}

		var target = File.readlinkBang(next);
		var resolved = Path.expandRelativeTo(target, Path.dirname(next));
		return appendRemainingComponents(components, index + 1, resolved, followedLinks + 1);
	}

	static function appendRemainingComponents(components:Array<String>, index:Int, resolved:String, followedLinks:Int):String {
		if (index >= components.length) {
			return resolveExistingPath(resolved, followedLinks);
		}
		return appendRemainingComponents(components, index + 1, Path.joinTwo(resolved, components[index]), followedLinks);
	}
}
