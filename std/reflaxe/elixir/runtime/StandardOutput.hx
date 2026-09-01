package reflaxe.elixir.runtime;

import elixir.types.Atom;
import elixir.types.Term;
import elixir.types.Tuple2;
import haxe.io.Bytes;

/**
 * Write bytes to a BEAM standard output device.
 *
 * The adapter gives `Sys.stdout()` and `Sys.stderr()` real
 * `haxe.io.Output` implementations. Closing a shared stream has no effect.
 */
@:native("Reflaxe.Elixir.Runtime.StandardOutput")
class StandardOutput extends haxe.io.Output {
	final device:StandardIODevice;

	public function new(device:StandardIODevice) {
		this.device = device;
	}

	override public function writeByte(c:Int):Void {
		var byte = Bytes.alloc(1);
		byte.set(0, c);
		writeData(byte.getData());
	}

	override public function writeBytes(bytes:Bytes, pos:Int, len:Int):Int {
		if (pos < 0 || len < 0 || pos + len > bytes.length) {
			throw haxe.io.Error.OutsideBounds;
		}
		if (len == 0)
			return 0;

		writeData(bytes.sub(pos, len).getData());
		return len;
	}

	override public function close():Void {}

	function writeData(data:Term):Void {
		var result:Term = elixir.IO.binwriteTo(cast device, data);
		if (result != cast Atom.OK) {
			var error:Tuple2<Atom, Term> = cast result;
			throw "Standard output write error: " + elixir.List.toString(elixir.ErlangFile.formatError(error._1));
		}
	}
}
