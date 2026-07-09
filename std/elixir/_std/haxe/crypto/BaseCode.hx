package haxe.crypto;

import haxe.io.Bytes;

/**
 * BaseCode (Elixir target)
 *
 * WHAT
 * - Canonical Haxe `haxe.crypto.BaseCode` byte/string encoding over a
 *   power-of-two dictionary.
 *
 * WHY
 * - BEAM has native helpers for common encodings like Base64, but no generic
 *   primitive for arbitrary caller-provided base dictionaries.
 *
 * HOW
 * - Runtime builds BEAM binaries directly so mutable `Bytes` output never leaks
 *   into generated loops.
 * - Macro/eval uses a small pure-Haxe path and legacy Neko native branches are
 *   intentionally omitted.
 */
@:native("Haxe.Crypto.BaseCode")
class BaseCode {
	var base:Bytes;
	var nbits:Int;

	public function new(base:Bytes) {
		var len = base.length;
		var candidateBits = 1;
		while (len > 1 << candidateBits)
			candidateBits = candidateBits + 1;
		if (candidateBits > 8 || len != 1 << candidateBits)
			throw "BaseCode : base length must be a power of two.";
		this.base = base;
		this.nbits = candidateBits;
	}

	public function encodeBytes(bytes:Bytes):Bytes {
		#if (macro || (!reflaxe_runtime && !elixir))
		return encodeBytesPure(bytes);
		#else
		var data = untyped __elixir__('
			reflaxe_basecode_input = {0}
			reflaxe_basecode_base = {1}
			reflaxe_basecode_nbits = {2}
			reflaxe_basecode_bit_count = byte_size(reflaxe_basecode_input) * 8
			reflaxe_basecode_size = div(reflaxe_basecode_bit_count, reflaxe_basecode_nbits)
			reflaxe_basecode_mask = Bitwise.bsl(1, reflaxe_basecode_nbits) - 1

			reflaxe_basecode_read = fn reflaxe_basecode_read, buf, curbits, pin ->
				if curbits < reflaxe_basecode_nbits do
					reflaxe_basecode_read.(
						reflaxe_basecode_read,
						Bitwise.bor(Bitwise.bsl(buf, 8), :binary.at(reflaxe_basecode_input, pin)),
						curbits + 8,
						pin + 1
					)
				else
					{buf, curbits, pin}
				end
			end

			reflaxe_basecode_encode = fn reflaxe_basecode_encode, remaining, out, buf, curbits, pin ->
				if remaining == 0 do
					{out, buf, curbits, pin}
				else
					{buf, curbits, pin} = reflaxe_basecode_read.(reflaxe_basecode_read, buf, curbits, pin)
					curbits = curbits - reflaxe_basecode_nbits
					value = :binary.at(reflaxe_basecode_base, Bitwise.band(Bitwise.bsr(buf, curbits), reflaxe_basecode_mask))
					reflaxe_basecode_encode.(reflaxe_basecode_encode, remaining - 1, [value | out], buf, curbits, pin)
				end
			end

			{reflaxe_basecode_out, reflaxe_basecode_buf, reflaxe_basecode_curbits, _} =
				reflaxe_basecode_encode.(reflaxe_basecode_encode, reflaxe_basecode_size, [], 0, 0, 0)

			reflaxe_basecode_out =
				if reflaxe_basecode_curbits > 0 do
					value =
						:binary.at(
							reflaxe_basecode_base,
							Bitwise.band(Bitwise.bsl(reflaxe_basecode_buf, reflaxe_basecode_nbits - reflaxe_basecode_curbits), reflaxe_basecode_mask)
						)
					[value | reflaxe_basecode_out]
				else
					reflaxe_basecode_out
				end

			:erlang.list_to_binary(Enum.reverse(reflaxe_basecode_out))
		', bytes.getData(), base.getData(), nbits);
		return Bytes.ofData(data);
		#end
	}

	#if (macro || (!reflaxe_runtime && !elixir))
	function encodeBytesPure(bytes:Bytes):Bytes {
		var nbits = this.nbits;
		var base = this.base;
		var size = Std.int(bytes.length * 8 / nbits);
		var out = Bytes.alloc(size + (((bytes.length * 8) % nbits == 0) ? 0 : 1));
		var buf = 0;
		var curbits = 0;
		var mask = (1 << nbits) - 1;
		var pin = 0;
		var pout = 0;
		while (pout < size) {
			while (curbits < nbits) {
				curbits += 8;
				buf <<= 8;
				buf |= bytes.get(pin);
				pin += 1;
			}
			curbits -= nbits;
			out.set(pout, base.get((buf >> curbits) & mask));
			pout += 1;
		}
		if (curbits > 0) {
			out.set(pout, base.get((buf << (nbits - curbits)) & mask));
			pout += 1;
		}
		return out;
	}

	function decodeByte(byte:Int):Int {
		var index = 0;
		while (index < base.length) {
			if (base.get(index) == byte)
				return index;
			index += 1;
		}
		return -1;
	}
	#end

	public function decodeBytes(bytes:Bytes):Bytes {
		#if (macro || (!reflaxe_runtime && !elixir))
		return decodeBytesPure(bytes);
		#else
		var data = untyped __elixir__('
			reflaxe_basecode_input = {0}
			reflaxe_basecode_base = {1}
			reflaxe_basecode_nbits = {2}
			reflaxe_basecode_size = div(byte_size(reflaxe_basecode_input) * reflaxe_basecode_nbits, 8)

			reflaxe_basecode_find = fn byte ->
				Enum.find_value(0..(byte_size(reflaxe_basecode_base) - 1)//1, -1, fn index ->
					if :binary.at(reflaxe_basecode_base, index) == byte do
						index
					else
						false
					end
				end)
			end

			reflaxe_basecode_read = fn reflaxe_basecode_read, buf, curbits, pin ->
				if curbits < 8 do
					value = reflaxe_basecode_find.(:binary.at(reflaxe_basecode_input, pin))
					if value == -1 do
						raise Reflaxe.Elixir.HaxeThrow, [value: "BaseCode : invalid encoded char"]
					end
					reflaxe_basecode_read.(
						reflaxe_basecode_read,
						Bitwise.bor(Bitwise.bsl(buf, reflaxe_basecode_nbits), value),
						curbits + reflaxe_basecode_nbits,
						pin + 1
					)
				else
					{buf, curbits, pin}
				end
			end

			reflaxe_basecode_decode = fn reflaxe_basecode_decode, remaining, out, buf, curbits, pin ->
				if remaining == 0 do
					out
				else
					{buf, curbits, pin} = reflaxe_basecode_read.(reflaxe_basecode_read, buf, curbits, pin)
					curbits = curbits - 8
					value = Bitwise.band(Bitwise.bsr(buf, curbits), 0xFF)
					reflaxe_basecode_decode.(reflaxe_basecode_decode, remaining - 1, [value | out], buf, curbits, pin)
				end
			end

			:erlang.list_to_binary(Enum.reverse(reflaxe_basecode_decode.(reflaxe_basecode_decode, reflaxe_basecode_size, [], 0, 0, 0)))
		', bytes.getData(), base.getData(), nbits);
		return Bytes.ofData(data);
		#end
	}

	#if (macro || (!reflaxe_runtime && !elixir))
	function decodeBytesPure(bytes:Bytes):Bytes {
		var nbits = this.nbits;
		var size = (bytes.length * nbits) >> 3;
		var out = Bytes.alloc(size);
		var buf = 0;
		var curbits = 0;
		var pin = 0;
		var pout = 0;
		while (pout < size) {
			while (curbits < 8) {
				curbits += nbits;
				buf <<= nbits;
				var i = decodeByte(bytes.get(pin));
				pin += 1;
				if (i == -1)
					throw "BaseCode : invalid encoded char";
				buf |= i;
			}
			curbits -= 8;
			out.set(pout, (buf >> curbits) & 0xFF);
			pout += 1;
		}
		return out;
	}
	#end

	public function encodeString(s:String):String {
		return encodeBytes(Bytes.ofString(s)).toString();
	}

	public function decodeString(s:String):String {
		return decodeBytes(Bytes.ofString(s)).toString();
	}

	public static function encode(s:String, base:String):String {
		var b = new BaseCode(Bytes.ofString(base));
		return b.encodeString(s);
	}

	public static function decode(s:String, base:String):String {
		var b = new BaseCode(Bytes.ofString(base));
		return b.decodeString(s);
	}
}
