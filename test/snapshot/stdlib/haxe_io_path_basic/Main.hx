package;

import haxe.io.Path;

/**
 * Snapshot: haxe.io.Path
 *
 * Exercises the pure Haxe path helper surface that must compile both in macro
 * contexts and generated Elixir target code.
 */
class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main() {
		var parsed = new Path("/tmp/archive.tar.gz");
		trace(parsed.dir);
		trace(parsed.file);
		trace(parsed.ext);

		assertThat(parsed.dir == "/tmp", "directory parse failed");
		assertThat(parsed.file == "archive.tar", "file parse failed");
		assertThat(parsed.ext == "gz", "extension parse failed");
		assertThat(parsed.toString() == "/tmp/archive.tar.gz", "toString failed");

		assertThat(Path.withoutExtension("/tmp/file.txt") == "/tmp/file", "withoutExtension failed");
		assertThat(Path.withoutDirectory("/tmp/file.txt") == "file.txt", "withoutDirectory failed");
		assertThat(Path.directory("/tmp/file.txt") == "/tmp", "directory helper failed");
		assertThat(Path.extension("/tmp/file.txt") == "txt", "extension helper failed");
		assertThat(Path.withExtension("/tmp/file", "log") == "/tmp/file.log", "withExtension failed");
		assertThat(Path.join(["/usr", "local", "../bin"]) == "/usr/bin", "join normalize failed");
		assertThat(Path.normalize("/usr//local/../bin/./tool") == "/usr/bin/tool", "normalize failed");
		assertThat(Path.addTrailingSlash("foo\\bar") == "foo\\bar\\", "addTrailingSlash backslash failed");
		assertThat(Path.removeTrailingSlashes("foo///") == "foo", "removeTrailingSlashes failed");
		assertThat(Path.isAbsolute("/tmp"), "unix absolute failed");
		assertThat(Path.isAbsolute("C:/tmp"), "drive absolute failed");
		assertThat(Path.isAbsolute("\\\\server\\share"), "unc absolute failed");
		assertThat(!Path.isAbsolute("relative/path"), "relative path failed");
	}
}
