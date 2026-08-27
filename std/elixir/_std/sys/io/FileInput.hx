package sys.io;

import elixir.types.Term;
import elixir.types.Atom;
import elixir.ErlangFile.ErlangFilePosition;
import elixir.ErlangFile.ErlangFileReadResult;
import elixir.ErlangFile.ErlangFileResult;
import haxe.io.Eof;
import haxe.io.Bytes;

/**
 * sys.io.FileInput (Elixir target)
 *
 * WHAT
 * - BEAM-backed file reader implementing Haxe's `sys.io.FileInput`.
 *
 * WHY
 * - Haxe libraries use `sys.io.File.read(...)` to obtain an input stream.
 * - For Elixir, we map to an Erlang IO device returned by `File.open!/2`.
 *
 * HOW
 * - Uses Erlang `:file.read/2` and `:file.position/2` under the hood.
 * - Throws `haxe.io.Eof` when the end of file is reached (Haxe contract).
 */
@:native("Sys.IO.FileInput")
class FileInput extends haxe.io.Input {
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

	public function eof():Bool {
		var result = elixir.ErlangFile.read(device, 1);
		if (isEof(result)) {
			return true;
		}

		var data = readData(result);
		position(elixir.ErlangFile.positionAt(ErlangFilePosition.Current, -data.length));
		return false;
	}

	override public function readByte():Int {
		var result = elixir.ErlangFile.read(device, 1);
		if (isEof(result)) {
			throw new Eof();
		}
		return readData(result).get(0);
	}

	override public function readBytes(buf:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > buf.length) {
			throw haxe.io.Error.OutsideBounds;
		}

		if (len == 0)
			return 0;

		var result = elixir.ErlangFile.read(device, len);
		if (isEof(result)) {
			throw new Eof();
		}

		var bytes = readData(result);
		buf.blit(pos, bytes, 0, bytes.length);
		return bytes.length;
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

	/** Validate a native read result before converting its binary payload. */
	static function readData(result:ErlangFileReadResult):Bytes {
		var tagged:ErlangFileResult = cast result;
		if (tagged._0 != cast Atom.OK) {
			throwFileError("read", tagged);
		}
		return Bytes.ofData(cast tagged._1);
	}

	static inline function isEof(result:ErlangFileReadResult):Bool {
		return result == cast ErlangFilePosition.End;
	}

	static function throwFileError(operation:String, result:ErlangFileResult):Void {
		throw 'File $operation error: ' + elixir.ErlangFile.formatError(result._1);
	}
}
