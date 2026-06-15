package haxe.crypto;

import haxe.io.Bytes;

/**
 * Sha1 (Elixir target)
 *
 * WHAT
 * - Canonical Haxe `haxe.crypto.Sha1` helpers for SHA-1 hex and raw digest bytes.
 *
 * WHY
 * - SHA-1 is still common in portable code for non-security fingerprints and
 *   protocol compatibility. BEAM provides the primitive directly via `:crypto`.
 *
 * HOW
 * - Runtime delegates to `:crypto.hash(:sha, ...)` and wraps binary output as `Bytes`.
 * - Macro/eval contexts use a pure-Haxe implementation derived from upstream Haxe
 *   stdlib so macro execution does not depend on target-only `__elixir__()` calls.
 */
@:native("Haxe.Crypto.Sha1")
class Sha1 {
	public static function encode(s:String):String {
		#if (macro || (!reflaxe_runtime && !elixir))
		return Sha1Pure.makeHex(Bytes.ofString(s));
		#else
		return untyped __elixir__('Base.encode16(:crypto.hash(:sha, {0}), case: :lower)', s);
		#end
	}

	public static function make(b:Bytes):Bytes {
		#if (macro || (!reflaxe_runtime && !elixir))
		return Sha1Pure.makeBytes(b);
		#else
		var digest = untyped __elixir__(':crypto.hash(:sha, {0})', b.getData());
		return Bytes.ofData(digest);
		#end
	}
}

#if (macro || (!reflaxe_runtime && !elixir))
private class Sha1Pure {
	public static function makeHex(bytes:Bytes):String {
		var sha = new Sha1Pure();
		return sha.hex(sha.doEncode(bytesToBlocks(bytes)));
	}

	public static function makeBytes(bytes:Bytes):Bytes {
		var hash = new Sha1Pure().doEncode(bytesToBlocks(bytes));
		var out = Bytes.alloc(20);
		var position = 0;
		for (index in 0...5) {
			out.set(position++, hash[index] >>> 24);
			out.set(position++, (hash[index] >> 16) & 0xFF);
			out.set(position++, (hash[index] >> 8) & 0xFF);
			out.set(position++, hash[index] & 0xFF);
		}
		return out;
	}

	function new() {}

	function doEncode(blocks:Array<Int>):Array<Int> {
		var words = new Array<Int>();

		var a = 0x67452301;
		var b = 0xEFCDAB89;
		var c = 0x98BADCFE;
		var d = 0x10325476;
		var e = 0xC3D2E1F0;

		var blockIndex = 0;
		while (blockIndex < blocks.length) {
			var oldA = a;
			var oldB = b;
			var oldC = c;
			var oldD = d;
			var oldE = e;

			var round = 0;
			while (round < 80) {
				if (round < 16)
					words[round] = blocks[blockIndex + round];
				else
					words[round] = rotateLeft(words[round - 3] ^ words[round - 8] ^ words[round - 14] ^ words[round - 16], 1);
				var temp = rotateLeft(a, 5) + roundFunction(round, b, c, d) + e + words[round] + roundConstant(round);
				e = d;
				d = c;
				c = rotateLeft(b, 30);
				b = a;
				a = temp;
				round++;
			}

			a += oldA;
			b += oldB;
			c += oldC;
			d += oldD;
			e += oldE;
			blockIndex += 16;
		}
		return [a, b, c, d, e];
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

	function rotateLeft(num:Int, count:Int):Int {
		return (num << count) | (num >>> (32 - count));
	}

	function roundFunction(round:Int, b:Int, c:Int, d:Int):Int {
		if (round < 20)
			return (b & c) | ((~b) & d);
		if (round < 40)
			return b ^ c ^ d;
		if (round < 60)
			return (b & c) | (b & d) | (c & d);
		return b ^ c ^ d;
	}

	function roundConstant(round:Int):Int {
		if (round < 20)
			return 0x5A827999;
		if (round < 40)
			return 0x6ED9EBA1;
		if (round < 60)
			return 0x8F1BBCDC;
		return 0xCA62C1D6;
	}

	function hex(hash:Array<Int>):String {
		var output = "";
		for (word in hash) {
			output += StringTools.hex(word, 8);
		}
		return output.toLowerCase();
	}
}
#end
