package reflaxe.elixir.runtime;

import elixir.types.Atom;
import elixir.types.Term;
import elixir.types.Tuple2;
import haxe.io.Bytes;
import haxe.io.Eof;

/**
 * Read bytes from the current BEAM standard input device.
 *
 * The adapter gives `Sys.stdin()` a real `haxe.io.Input` implementation.
 * Closing this shared process stream has no effect.
 */
@:native("Reflaxe.Elixir.Runtime.StandardInput")
class StandardInput extends haxe.io.Input {
	public function new() {}

	override public function readByte():Int {
		return readChunk(1).get(0);
	}

	override public function readBytes(buf:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > buf.length) {
			throw haxe.io.Error.OutsideBounds;
		}
		if (len == 0)
			return 0;

		var bytes = readChunk(len);
		buf.blit(pos, bytes, 0, bytes.length);
		return bytes.length;
	}

	override public function readLine():String {
		var request:Term = elixir.ErlangIO.lineReadRequest();
		var result:Term = elixir.ErlangIO.request(cast StandardIODevice.StandardIO, request);
		if (result == cast StandardIODevice.EndOfFile) {
			throw new Eof();
		}
		if (!elixir.Kernel.isBinary(result)) {
			throwReadError(cast result);
		}

		var line:String = cast result;
		if (StringTools.endsWith(line, "\n"))
			line = line.substr(0, line.length - 1);
		if (StringTools.endsWith(line, "\r"))
			line = line.substr(0, line.length - 1);
		return line;
	}

	override public function close():Void {}

	static function readChunk(length:Int):Bytes {
		var request:Term = elixir.ErlangIO.byteReadRequest(length);
		var result:Term = elixir.ErlangIO.request(cast StandardIODevice.StandardIO, request);
		if (result == cast StandardIODevice.EndOfFile) {
			throw new Eof();
		}
		if (!elixir.Kernel.isBinary(result)) {
			throwReadError(cast result);
		}
		return Bytes.ofData(cast result);
	}

	static function throwReadError(error:Tuple2<Atom, Term>):Void {
		throw "Standard input read error: " + elixir.List.toString(elixir.ErlangFile.formatError(error._1));
	}
}
