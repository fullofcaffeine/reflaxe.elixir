package haxe.crypto;

import haxe.io.Bytes;
import haxe.io.Input;

/**
 * Adler32 (Elixir target)
 *
 * WHAT
 * - Canonical Haxe `haxe.crypto.Adler32` checksum API for full-buffer and
 *   incremental Adler-32 calculation.
 *
 * WHY
 * - Adler-32 is used by portable compression/checksum code. BEAM provides
 *   native one-shot and incremental implementations via `:erlang.adler32/1,2`,
 *   so generated Elixir should use those primitives instead of carrying the
 *   portable reference loop at runtime.
 *
 * HOW
 * - Runtime stores the public checksum state as a Haxe signed `Int`, converts
 *   to BEAM's unsigned 32-bit input when continuing, and converts native
 *   unsigned results back to Haxe signed `Int` semantics.
 * - Macro/eval contexts use the small pure-Haxe Adler-32 loop derived from
 *   upstream stdlib so macro execution does not depend on target-only
 *   `__elixir__()` calls.
 */
@:native("Haxe.Crypto.Adler32")
class Adler32 {
	var adler:Int;

	public function new() {
		adler = 1;
	}

	public function get():Int {
		return adler;
	}

	public function update(b:Bytes, pos:Int, len:Int):Void {
		#if (macro || (!reflaxe_runtime && !elixir))
		var a1 = adler & 0xFFFF;
		var a2 = adler >>> 16;
		for (p in pos...pos + len) {
			var c = b.get(p);
			a1 = (a1 + c) % 65521;
			a2 = (a2 + a1) % 65521;
		}
		adler = (a2 << 16) | a1;
		#else
		if (len != 0) {
			var slice = untyped __elixir__(":binary.part({0}, {1}, {2})", b.getData(), pos, len);
			var updated = untyped __elixir__(":erlang.adler32({0}, {1})", unsigned32(adler), slice);
			adler = signed32(updated);
			untyped __elixir__("{0}", this);
		} else {
			untyped __elixir__("{0}", this);
		}
		#end
	}

	public function equals(a:Adler32):Bool {
		return a.adler == adler;
	}

	public function toString():String {
		#if (macro || (!reflaxe_runtime && !elixir))
		var a1 = adler & 0xFFFF;
		var a2 = adler >>> 16;
		return StringTools.hex(a2, 8) + StringTools.hex(a1, 8);
		#else
		var unsigned = unsigned32(adler);
		var a1 = untyped __elixir__(":erlang.band({0}, 65535)", unsigned);
		var a2 = untyped __elixir__(":erlang.bsr({0}, 16)", unsigned);
		return StringTools.hex(a2, 8) + StringTools.hex(a1, 8);
		#end
	}

	public static function read(i:Input):Adler32 {
		var a = new Adler32();
		var a2a = i.readByte();
		var a2b = i.readByte();
		var a1a = i.readByte();
		var a1b = i.readByte();
		a.adler = signed32((a2a << 24) | (a2b << 16) | (a1a << 8) | a1b);
		return a;
	}

	public static function make(b:Bytes):Int {
		#if (macro || (!reflaxe_runtime && !elixir))
		var a = new Adler32();
		a.update(b, 0, b.length);
		return a.get();
		#else
		return signed32(untyped __elixir__(":erlang.adler32({0})", b.getData()));
		#end
	}

	static inline function signed32(value:Int):Int {
		#if (macro || (!reflaxe_runtime && !elixir))
		return value;
		#else
		return
			untyped __elixir__("(if :erlang.band({0}, 4294967295) >= 2147483648, do: :erlang.band({0}, 4294967295) - 4294967296, else: :erlang.band({0}, 4294967295))",
				value);
		#end
	}

	static inline function unsigned32(value:Int):Int {
		#if (macro || (!reflaxe_runtime && !elixir))
		return value;
		#else
		return untyped __elixir__("if {0} < 0, do: {0} + 4294967296, else: {0}", value);
		#end
	}
}
