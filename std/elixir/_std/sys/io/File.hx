package sys.io;

import elixir.types.Term;
import elixir.File.FileOpenMode;
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
 * - Uses the typed `File.open!/2` extern to create an Erlang IO device for
 *   streaming read/write handles (`FileInput` / `FileOutput`).
 */
@:native("Sys.IO.File")
class File {
	public static function getContent(path:String):String {
		return elixir.File.readBang(path);
	}

	public static function saveContent(path:String, content:String):Void {
		elixir.File.writeBang(path, content);
	}

	public static function getBytes(path:String):Bytes {
		var data = elixir.File.readBang(path);
		return Bytes.ofData(data);
	}

	public static function saveBytes(path:String, bytes:Bytes):Void {
		elixir.File.writeBang(path, bytes.getData());
	}

	public static function read(path:String, binary:Bool = true):FileInput {
		var modes = binary ? [FileOpenMode.Read, FileOpenMode.Binary] : [FileOpenMode.Read];
		var device:Term = elixir.File.openBangWithAtomModes(path, modes);
		return new FileInput(device);
	}

	public static function write(path:String, binary:Bool = true):FileOutput {
		var modes = binary ? [FileOpenMode.Write, FileOpenMode.Binary] : [FileOpenMode.Write];
		var device:Term = elixir.File.openBangWithAtomModes(path, modes);
		return new FileOutput(device);
	}

	public static function append(path:String, binary:Bool = true):FileOutput {
		var modes = binary ? [FileOpenMode.Append, FileOpenMode.Binary] : [FileOpenMode.Append];
		var device:Term = elixir.File.openBangWithAtomModes(path, modes);
		return new FileOutput(device);
	}

	public static function update(path:String, binary:Bool = true):FileOutput {
		var modes = binary ? [FileOpenMode.Read, FileOpenMode.Write, FileOpenMode.Binary] : [FileOpenMode.Read, FileOpenMode.Write];
		var device:Term = elixir.File.openBangWithAtomModes(path, modes);
		return new FileOutput(device);
	}

	public static function copy(srcPath:String, dstPath:String):Void {
		elixir.File.cpBang(srcPath, dstPath);
	}
}
