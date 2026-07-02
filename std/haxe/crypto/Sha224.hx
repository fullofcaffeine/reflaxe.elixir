package haxe.crypto;

import haxe.io.Bytes;

/**
 * Sha224 (Elixir target)
 *
 * WHAT
 * - Canonical Haxe `haxe.crypto.Sha224` helpers for SHA-224 hex and raw digest bytes.
 *
 * WHY
 * - SHA-224 is a standard SHA-2 digest used by portable Haxe code. BEAM provides
 *   this primitive directly via `:crypto`, so generated Elixir should use it instead
 *   of carrying the portable reference implementation at runtime.
 *
 * HOW
 * - Runtime delegates to `:crypto.hash(:sha224, ...)` and wraps binary output as `Bytes`.
 * - Macro/eval contexts use a pure-Haxe implementation derived from upstream Haxe
 *   stdlib so macro execution does not depend on target-only `__elixir__()` calls.
 */
@:native("Haxe.Crypto.Sha224")
class Sha224 {
	public static function encode(s:String):String {
		#if (macro || (!reflaxe_runtime && !elixir))
		return Sha224Pure.makeHex(Bytes.ofString(s));
		#else
		return untyped __elixir__('Base.encode16(:crypto.hash(:sha224, {0}), case: :lower)', s);
		#end
	}

	public static function make(b:Bytes):Bytes {
		#if (macro || (!reflaxe_runtime && !elixir))
		return Sha224Pure.makeBytes(b);
		#else
		var digest = untyped __elixir__(':crypto.hash(:sha224, {0})', b.getData());
		return Bytes.ofData(digest);
		#end
	}
}

#if (macro || (!reflaxe_runtime && !elixir))
private class Sha224Pure {
	static final K:Array<Int> = [
		0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5, 0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
		0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3, 0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
		0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC, 0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
		0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7, 0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
		0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13, 0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
		0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3, 0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
		0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5, 0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
		0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208, 0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2
	];

	public static function makeHex(bytes:Bytes):String {
		var sha = new Sha224Pure();
		return sha.hex(sha.doEncode(bytesToBlocks(bytes)));
	}

	public static function makeBytes(bytes:Bytes):Bytes {
		var hash = new Sha224Pure().doEncode(bytesToBlocks(bytes));
		var out = Bytes.alloc(28);
		var position = 0;
		for (index in 0...7) {
			out.set(position++, hash[index] >>> 24);
			out.set(position++, (hash[index] >> 16) & 0xFF);
			out.set(position++, (hash[index] >> 8) & 0xFF);
			out.set(position++, hash[index] & 0xFF);
		}
		return out;
	}

	function new() {}

	function doEncode(blocks:Array<Int>):Array<Int> {
		var hash = [
			0xC1059ED8, 0x367CD507, 0x3070DD17, 0xF70E5939,
			0xFFC00B31, 0x68581511, 0x64F98FA7, 0xBEFA4FA4
		];
		var words = new Array<Int>();

		var blockIndex = 0;
		while (blockIndex < blocks.length) {
			var a = hash[0];
			var b = hash[1];
			var c = hash[2];
			var d = hash[3];
			var e = hash[4];
			var f = hash[5];
			var g = hash[6];
			var h = hash[7];

			for (round in 0...64) {
				if (round < 16)
					words[round] = blocks[blockIndex + round];
				else
					words[round] = add(add(add(gamma1(words[round - 2]), words[round - 7]), gamma0(words[round - 15])), words[round - 16]);

				var t1 = add(add(add(add(h, sigma1(e)), choose(e, f, g)), K[round]), words[round]);
				var t2 = add(sigma0(a), majority(a, b, c));
				h = g;
				g = f;
				f = e;
				e = add(d, t1);
				d = c;
				c = b;
				b = a;
				a = add(t1, t2);
			}

			hash[0] = add(hash[0], a);
			hash[1] = add(hash[1], b);
			hash[2] = add(hash[2], c);
			hash[3] = add(hash[3], d);
			hash[4] = add(hash[4], e);
			hash[5] = add(hash[5], f);
			hash[6] = add(hash[6], g);
			hash[7] = add(hash[7], h);
			blockIndex += 16;
		}

		return hash;
	}

	static function bytesToBlocks(bytes:Bytes):Array<Int> {
		var blockCount = ((bytes.length + 8) >> 6) + 1;
		var blocks = new Array<Int>();

		for (index in 0...blockCount * 16)
			blocks[index] = 0;
		for (index in 0...bytes.length) {
			var wordIndex = index >> 2;
			blocks[wordIndex] |= bytes.get(index) << (24 - ((index & 3) << 3));
		}
		var byteIndex = bytes.length;
		var wordIndex = byteIndex >> 2;
		blocks[wordIndex] |= 0x80 << (24 - ((byteIndex & 3) << 3));
		blocks[blockCount * 16 - 1] = bytes.length * 8;
		return blocks;
	}

	static inline function rotateRight(value:Int, bits:Int):Int {
		return (value >>> bits) | (value << (32 - bits));
	}

	static inline function shiftRight(value:Int, bits:Int):Int {
		return value >>> bits;
	}

	static inline function choose(x:Int, y:Int, z:Int):Int {
		return (x & y) ^ ((~x) & z);
	}

	static inline function majority(x:Int, y:Int, z:Int):Int {
		return (x & y) ^ (x & z) ^ (y & z);
	}

	static inline function sigma0(x:Int):Int {
		return rotateRight(x, 2) ^ rotateRight(x, 13) ^ rotateRight(x, 22);
	}

	static inline function sigma1(x:Int):Int {
		return rotateRight(x, 6) ^ rotateRight(x, 11) ^ rotateRight(x, 25);
	}

	static inline function gamma0(x:Int):Int {
		return rotateRight(x, 7) ^ rotateRight(x, 18) ^ shiftRight(x, 3);
	}

	static inline function gamma1(x:Int):Int {
		return rotateRight(x, 17) ^ rotateRight(x, 19) ^ shiftRight(x, 10);
	}

	static inline function add(x:Int, y:Int):Int {
		var low = (x & 0xFFFF) + (y & 0xFFFF);
		var high = (x >> 16) + (y >> 16) + (low >> 16);
		return (high << 16) | (low & 0xFFFF);
	}

	function hex(hash:Array<Int>):String {
		var output = "";
		for (index in 0...7)
			output += StringTools.hex(hash[index], 8);
		return output.toLowerCase();
	}
}
#end
