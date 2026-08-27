package;

import sys.FileSystem;
import sys.io.File;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition) {
			throw message;
		}
	}

	/** Remove only the files owned by this bounded runtime contract. */
	static function clean(root:String):Void {
		var nested = root + "/nested";
		var link = root + "/nested-link";
		var original = nested + "/original.txt";
		var renamed = nested + "/renamed.txt";

		if (FileSystem.exists(link)) {
			FileSystem.deleteFile(link);
		}
		if (FileSystem.exists(original)) {
			FileSystem.deleteFile(original);
		}
		if (FileSystem.exists(renamed)) {
			FileSystem.deleteFile(renamed);
		}
		if (FileSystem.exists(nested)) {
			FileSystem.deleteDirectory(nested);
		}
		if (FileSystem.exists(root)) {
			FileSystem.deleteDirectory(root);
		}
	}

	/** Native filesystem failures do not have one portable Haxe exception type. */
	static function assertNonEmptyDeleteFails(path:String):Void {
		try {
			FileSystem.deleteDirectory(path);
			throw "deleting a non-empty directory must fail";
		} catch (error:Dynamic) {
			if (Std.isOfType(error, String)) {
				throw error;
			}
			assertThat(FileSystem.exists(path), "failed deletion must keep the non-empty directory");
		}
	}

	static function assertStat(stat:sys.FileStat):Void {
		assertThat(stat.size == 5, "stat size must match the file content");
		var integerFields:Array<Int> = [stat.gid, stat.uid, stat.dev, stat.ino, stat.nlink, stat.rdev, stat.mode];
		for (value in integerFields) {
			assertThat(Std.isOfType(value, Int), "every integer FileStat field must be present");
		}
		assertThat(stat.nlink >= 1, "stat must report at least one hard link");

		var dateFields:Array<Date> = [stat.atime, stat.mtime, stat.ctime];
		for (value in dateFields) {
			assertThat(value != null, "every Date FileStat field must be present");
			assertThat(value.getTime() > 0, "every FileStat date must be a usable Haxe Date");
		}
	}

	public static function main() {
		var root = "_tmp/reflaxe_filesystem_snapshot_contract";
		var nested = root + "/nested";
		var link = root + "/nested-link";
		var original = nested + "/original.txt";
		var renamed = nested + "/renamed.txt";

		clean(root);
		assertThat(!FileSystem.exists(root), "cleanup must remove the contract directory");

		FileSystem.createDirectory(nested);
		assertThat(FileSystem.exists(nested), "recursive directory creation must succeed");
		assertThat(FileSystem.isDirectory(nested), "the created path must be a directory");

		File.saveContent(original, "hello");
		assertThat(FileSystem.exists(original), "the created file must exist");
		assertThat(!FileSystem.isDirectory(original), "a regular file must not be a directory");
		assertThat(FileSystem.readDirectory(nested).join(",") == "original.txt", "directory listing must contain the file name");
		assertNonEmptyDeleteFails(nested);

		FileSystem.rename(original, renamed);
		assertThat(!FileSystem.exists(original), "rename must remove the old path");
		assertThat(FileSystem.exists(renamed), "rename must create the new path");
		assertStat(FileSystem.stat(renamed));

		// Link creation is target-specific setup for the portable fullPath contract.
		elixir.File.lnSymbolicBang("nested", link);
		assertThat(FileSystem.isDirectory(link), "isDirectory must follow a directory symlink");
		assertThat(FileSystem.fullPath(link + "/renamed.txt") == FileSystem.fullPath(renamed), "fullPath must resolve an intermediate relative symlink");

		var absolute = FileSystem.absolutePath(root);
		var resolved = FileSystem.fullPath(root);
		assertThat(haxe.io.Path.isAbsolute(absolute), "absolutePath must return an absolute path");
		assertThat(haxe.io.Path.isAbsolute(resolved), "fullPath must return an absolute path");
		assertThat(StringTools.endsWith(absolute, root), "absolutePath must preserve the relative suffix");
		assertThat(StringTools.endsWith(resolved, root), "fullPath must preserve the resolved suffix");

		FileSystem.deleteFile(link);
		FileSystem.deleteFile(renamed);
		FileSystem.deleteDirectory(nested);
		FileSystem.deleteDirectory(root);
		assertThat(!FileSystem.exists(root), "explicit deletion must remove every owned path");
	}
}
