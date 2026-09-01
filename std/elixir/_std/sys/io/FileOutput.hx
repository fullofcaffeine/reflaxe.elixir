package sys.io;

import elixir.types.Term;
import elixir.types.Atom;
import elixir.ErlangFile.ErlangFilePosition;
import elixir.ErlangFile.ErlangFileResult;
import haxe.io.Bytes;

/**
 * sys.io.FileOutput (Elixir target)
 *
 * WHAT
 * - BEAM-backed file writer implementing Haxe's `sys.io.FileOutput`.
 *
 * WHY
 * - Haxe libraries use `sys.io.File.write/append/update` to obtain output streams.
 *
 * HOW
 * - Uses Erlang `:file.write/2` and `:file.position/2` against the underlying
 *   IO device returned by `File.open!/2`.
 */
@:native("Sys.IO.FileOutput")
class FileOutput extends haxe.io.Output {
	final device:Term;

	public function new(device:Term) {
		this.device = device;
	}

	public function seek(p:Int, pos:FileSeek):Void {
		switch (pos) {
			case SeekBegin:
				position(elixir.ErlangFile.positionAt(ErlangFilePosition.Begin, p));
			case SeekCur:
				position(elixir.ErlangFile.positionAt(ErlangFilePosition.Current, p));
			case SeekEnd:
				position(elixir.ErlangFile.positionAt(ErlangFilePosition.End, p));
		}
	}

	public function tell():Int {
		return position(ErlangFilePosition.Current);
	}

	override public function writeByte(c:Int):Void {
		var byte = Bytes.alloc(1);
		byte.set(0, c);
		writeData(byte.getData());
	}

	override public function writeBytes(b:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > b.length) {
			throw haxe.io.Error.OutsideBounds;
		}
		if (len == 0)
			return 0;

		var slice = b.sub(pos, len).getData();
		writeData(slice);
		return len;
	}

	override public function close():Void {
		var result = elixir.File.close(device);
		if (result != cast Atom.OK) {
			throw "File close error";
		}
	}

	/** Validate a native position result before narrowing its integer value. */
	function position(location:Term):Int {
		var result = elixir.ErlangFile.position(device, location);
		if (result._0 != cast Atom.OK) {
			throwFileError("position", result);
		}
		return cast result._1;
	}

	function writeData(data:Term):Void {
		var result = elixir.ErlangFile.write(device, data);
		var rawResult:Term = result;
		if (rawResult != cast Atom.OK) {
			throwFileError("write", cast result);
		}
	}

	static function throwFileError(operation:String, result:ErlangFileResult):Void {
		throw 'File $operation error: ' + elixir.List.toString(elixir.ErlangFile.formatError(result._1));
	}
}
