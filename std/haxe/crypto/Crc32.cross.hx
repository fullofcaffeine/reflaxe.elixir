package haxe.crypto;

import haxe.io.Bytes;

/**
 * Crc32 (Elixir target)
 *
 * WHAT
 * - Canonical Haxe `haxe.crypto.Crc32` checksum API for full-buffer and
 *   incremental CRC-32 calculation.
 *
 * WHY
 * - CRC-32 is a standard checksum used by portable Haxe code. BEAM provides
 *   native one-shot and incremental implementations via `:erlang.crc32/1,2`,
 *   so generated Elixir should use those primitives instead of carrying the
 *   portable reference loop at runtime.
 *
 * HOW
 * - Runtime stores the public checksum state as a Haxe signed `Int`, converts
 *   to BEAM's unsigned 32-bit input when continuing, and converts native
 *   unsigned results back to Haxe signed `Int` semantics.
 * - Macro/eval contexts use a pure-Haxe implementation derived from upstream
 *   stdlib so macro execution does not depend on target-only `__elixir__()`
 *   calls.
 */
@:native("Haxe.Crypto.Crc32")
class Crc32 {
	var crc:Int;

	public function new() {
		crc = 0;
	}

	public function byte(b:Int):Void {
		#if (macro || (!reflaxe_runtime && !elixir))
		var tmp = ((crc ^ 0xFFFFFFFF) ^ b) & 0xFF;
		for (_ in 0...8)
			tmp = (tmp >>> 1) ^ (-(tmp & 1) & 0xEDB88320);
		crc = ((crc ^ 0xFFFFFFFF) >>> 8) ^ tmp ^ 0xFFFFFFFF;
		#else
		var byteValue = untyped __elixir__(":erlang.band({0}, 255)", b);
		var updated = untyped __elixir__(":erlang.crc32({0}, <<{1}::unsigned-size(8)>>)", unsigned32(crc), byteValue);
		crc = signed32(updated);
		untyped __elixir__("{0}", this);
		#end
	}

	public function update(b:Bytes, pos:Int, len:Int):Void {
		#if (macro || (!reflaxe_runtime && !elixir))
		var data = b.getData();
		var state = crc ^ 0xFFFFFFFF;
		for (i in pos...pos + len) {
			var tmp = (state ^ Bytes.fastGet(data, i)) & 0xFF;
			for (_ in 0...8)
				tmp = (tmp >>> 1) ^ (-(tmp & 1) & 0xEDB88320);
			state = (state >>> 8) ^ tmp;
		}
		crc = state ^ 0xFFFFFFFF;
		#else
		if (len != 0) {
			var slice = untyped __elixir__(":binary.part({0}, {1}, {2})", b.getData(), pos, len);
			var updated = untyped __elixir__(":erlang.crc32({0}, {1})", unsigned32(crc), slice);
			crc = signed32(updated);
			untyped __elixir__("{0}", this);
		} else {
			untyped __elixir__("{0}", this);
		}
		#end
	}

	public function get():Int {
		return crc;
	}

	public static function make(data:Bytes):Int {
		#if (macro || (!reflaxe_runtime && !elixir))
		var c = new Crc32();
		c.update(data, 0, data.length);
		return c.get();
		#else
		return signed32(untyped __elixir__(":erlang.crc32({0})", data.getData()));
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
