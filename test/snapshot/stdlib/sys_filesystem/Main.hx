package;

import haxe.io.Bytes;
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
		var stream = nested + "/stream.bin";
		var copied = nested + "/copied.bin";
		var createdByUpdate = nested + "/created-by-update.txt";

		if (FileSystem.exists(link)) {
			FileSystem.deleteFile(link);
		}
		if (FileSystem.exists(original)) {
			FileSystem.deleteFile(original);
		}
		if (FileSystem.exists(renamed)) {
			FileSystem.deleteFile(renamed);
		}
		if (FileSystem.exists(stream)) {
			FileSystem.deleteFile(stream);
		}
		if (FileSystem.exists(copied)) {
			FileSystem.deleteFile(copied);
		}
		if (FileSystem.exists(createdByUpdate)) {
			FileSystem.deleteFile(createdByUpdate);
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
		var stream = nested + "/stream.bin";
		var copied = nested + "/copied.bin";
		var createdByUpdate = nested + "/created-by-update.txt";

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

		var output = File.write(stream);
		output.writeByte("a".code);
		assertThat(output.writeBytes(Bytes.ofString("bcde"), 0, 4) == 4, "writeBytes must report the written byte count");
		assertThat(output.tell() == 5, "tell must report the position after a write");
		output.seek(1, SeekBegin);
		assertThat(output.writeBytes(Bytes.ofString("XY"), 0, 2) == 2, "writeBytes must report the written byte count");
		assertThat(output.tell() == 3, "tell must follow an absolute output seek");
		output.close();
		assertThat(File.getContent(stream) == "aXYde", "write must support seeking and overwrite existing bytes");

		var append = File.append(stream);
		append.writeString("fg");
		append.close();
		assertThat(File.getContent(stream) == "aXYdefg", "append must preserve existing content");

		var update = File.update(stream);
		update.seek(-2, SeekEnd);
		update.writeString("HI");
		update.close();
		assertThat(File.getContent(stream) == "aXYdeHI", "update must overwrite without truncating the file");

		var createHandle = File.update(createdByUpdate);
		createHandle.close();
		assertThat(FileSystem.exists(createdByUpdate), "update must create a missing file");

		var input = File.read(stream);
		assertThat(input.tell() == 0, "a new input must start at position zero");
		assertThat(!input.eof(), "eof must be false before reading data");
		assertThat(input.tell() == 0, "eof must not consume input");
		assertThat(input.readByte() == "a".code, "readByte must return the next byte");
		var callerBuffer = Bytes.alloc(6);
		callerBuffer.fill(0, callerBuffer.length, "_".code);
		assertThat(input.readBytes(callerBuffer, 2, 3) == 3, "readBytes must report the bytes copied into the caller buffer");
		assertThat(callerBuffer.toString() == "__XYd_", "readBytes must mutate only the requested caller-buffer range");
		assertThat(input.tell() == 4, "tell must follow caller-buffer reads");
		input.seek(-2, SeekEnd);
		assertThat(input.read(2).toString() == "HI", "input seek must support positions relative to the end");
		assertThat(input.eof(), "eof must be true after the last byte");
		input.close();

		var binary = Bytes.alloc(4);
		binary.set(0, 0);
		binary.set(1, 1);
		binary.set(2, 127);
		binary.set(3, 255);
		File.saveBytes(copied, binary);
		assertThat(File.getBytes(copied).compare(binary) == 0, "saveBytes and getBytes must preserve all byte values");
		File.copy(copied, original);
		assertThat(File.getBytes(original).compare(binary) == 0, "copy must preserve binary content");

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
		FileSystem.deleteFile(original);
		FileSystem.deleteFile(renamed);
		FileSystem.deleteFile(stream);
		FileSystem.deleteFile(copied);
		FileSystem.deleteFile(createdByUpdate);
		FileSystem.deleteDirectory(nested);
		FileSystem.deleteDirectory(root);
		assertThat(!FileSystem.exists(root), "explicit deletion must remove every owned path");
	}
}
