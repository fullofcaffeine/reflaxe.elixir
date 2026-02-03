package haxe.crypto;

import haxe.io.Bytes;

/**
 * Md5 (Elixir target override)
 *
 * WHAT
 * - Provides `haxe.crypto.Md5` for Elixir builds with correct behavior and idiomatic output.
 *
 * WHY
 * - The todo-app and compiler tooling use `haxe.crypto.Md5` (e.g. Gravatar URLs, stable hashes).
 * - On BEAM we can (and should) delegate to native `:crypto` instead of emitting a large pure-Haxe
 *   implementation.
 *
 * HOW
 * - Runtime (Elixir): `make(Bytes)` uses `:crypto.hash(:md5, bin)` and `Base.encode16(..., case: :lower)`.
 * - Macro context: falls back to a small, pure-Haxe implementation so macro typing/evaluation never
 *   depends on `__elixir__()`.
 */
class Md5 {
	public static function encode(s:String):String {
		#if (macro || (!reflaxe_runtime && !elixir))
		return Md5Pure.makeHex(Bytes.ofString(s));
		#else
		return untyped __elixir__(
			'Base.encode16(:crypto.hash(:md5, {0}), case: :lower)',
			s
		);
		#end
	}

	public static function make(b:Bytes):Bytes {
		#if (macro || (!reflaxe_runtime && !elixir))
		return Md5Pure.makeBytes(b);
		#else
		var bin = b.getData();
		var digest = untyped __elixir__(
			':crypto.hash(:md5, {0})',
			bin
		);
		return Bytes.ofData(digest);
		#end
	}
}

#if (macro || (!reflaxe_runtime && !elixir))
// Pure Haxe implementation used only in macro context.
// Derived from upstream Haxe stdlib so macro evaluation remains correct even though we override
// the module name for Elixir builds.
private class Md5Pure {
	public static function makeHex(b:Bytes):String {
		var m = new Md5Pure();
		var h = m.doEncode(bytes2blks(b));
		return m.hex(h);
	}

	public static function makeBytes(b:Bytes):Bytes {
		var h = new Md5Pure().doEncode(bytes2blks(b));
		var out = Bytes.alloc(16);
		var position = 0;
		for (i in 0...4) {
			out.set(position++, h[i] & 0xFF);
			out.set(position++, (h[i] >> 8) & 0xFF);
			out.set(position++, (h[i] >> 16) & 0xFF);
			out.set(position++, h[i] >>> 24);
		}
		return out;
	}

	function new() {}

	function bitOR(a:Int, b:Int):Int {
		var lsb = (a & 0x1) | (b & 0x1);
		var msb31 = (a >>> 1) | (b >>> 1);
		return (msb31 << 1) | lsb;
	}

	function bitXOR(a:Int, b:Int):Int {
		var lsb = (a & 0x1) ^ (b & 0x1);
		var msb31 = (a >>> 1) ^ (b >>> 1);
		return (msb31 << 1) | lsb;
	}

	function bitAND(a:Int, b:Int):Int {
		var lsb = (a & 0x1) & (b & 0x1);
		var msb31 = (a >>> 1) & (b >>> 1);
		return (msb31 << 1) | lsb;
	}

	function addme(x:Int, y:Int):Int {
		var lsw = (x & 0xFFFF) + (y & 0xFFFF);
		var msw = (x >> 16) + (y >> 16) + (lsw >> 16);
		return (msw << 16) | (lsw & 0xFFFF);
	}

	function hex(a:Array<Int>):String {
		var str = "";
		var hexChr = "0123456789abcdef";
		for (num in a) {
			for (j in 0...4) {
				str += hexChr.charAt((num >> (j * 8 + 4)) & 0x0F) + hexChr.charAt((num >> (j * 8)) & 0x0F);
			}
		}
		return str;
	}

	static function bytes2blks(b:Bytes):Array<Int> {
		var nblk = ((b.length + 8) >> 6) + 1;
		var blks:Array<Int> = new Array();

		var blksSize = nblk * 16;
		blks[blksSize - 1] = 0;

		for (i in 0...blksSize) blks[i] = 0;

		var i = 0;
		while (i < b.length) {
			blks[i >> 2] |= b.get(i) << ((((b.length << 3) + i) & 3) << 3);
			i++;
		}
		blks[i >> 2] |= 0x80 << (((b.length * 8 + i) % 4) * 8);
		var l = b.length * 8;
		var k = nblk * 16 - 2;
		blks[k] = (l & 0xFF);
		blks[k] |= ((l >>> 8) & 0xFF) << 8;
		blks[k] |= ((l >>> 16) & 0xFF) << 16;
		blks[k] |= ((l >>> 24) & 0xFF) << 24;
		return blks;
	}

	function rol(num:Int, cnt:Int):Int {
		return (num << cnt) | (num >>> (32 - cnt));
	}

	function cmn(q:Int, a:Int, b:Int, x:Int, s:Int, t:Int):Int {
		return addme(rol((addme(addme(a, q), addme(x, t))), s), b);
	}

	function ff(a:Int, b:Int, c:Int, d:Int, x:Int, s:Int, t:Int):Int {
		return cmn(bitOR(bitAND(b, c), bitAND((~b), d)), a, b, x, s, t);
	}

	function gg(a:Int, b:Int, c:Int, d:Int, x:Int, s:Int, t:Int):Int {
		return cmn(bitOR(bitAND(b, d), bitAND(c, (~d))), a, b, x, s, t);
	}

	function hh(a:Int, b:Int, c:Int, d:Int, x:Int, s:Int, t:Int):Int {
		return cmn(bitXOR(bitXOR(b, c), d), a, b, x, s, t);
	}

	function ii(a:Int, b:Int, c:Int, d:Int, x:Int, s:Int, t:Int):Int {
		return cmn(bitXOR(c, bitOR(b, (~d))), a, b, x, s, t);
	}

	function doEncode(x:Array<Int>):Array<Int> {
		var a = 1732584193;
		var b = -271733879;
		var c = -1732584194;
		var d = 271733878;

        var i = 0;
        while (i < x.length) {
            var olda = a;
            var oldb = b;
            var oldc = c;
            var oldd = d;

            a = ff(a, b, c, d, x[i + 0], 7, -680876936);
            d = ff(d, a, b, c, x[i + 1], 12, -389564586);
            c = ff(c, d, a, b, x[i + 2], 17, 606105819);
            b = ff(b, c, d, a, x[i + 3], 22, -1044525330);
            a = ff(a, b, c, d, x[i + 4], 7, -176418897);
            d = ff(d, a, b, c, x[i + 5], 12, 1200080426);
            c = ff(c, d, a, b, x[i + 6], 17, -1473231341);
            b = ff(b, c, d, a, x[i + 7], 22, -45705983);
            a = ff(a, b, c, d, x[i + 8], 7, 1770035416);
            d = ff(d, a, b, c, x[i + 9], 12, -1958414417);
            c = ff(c, d, a, b, x[i + 10], 17, -42063);
            b = ff(b, c, d, a, x[i + 11], 22, -1990404162);
            a = ff(a, b, c, d, x[i + 12], 7, 1804603682);
            d = ff(d, a, b, c, x[i + 13], 12, -40341101);
            c = ff(c, d, a, b, x[i + 14], 17, -1502002290);
            b = ff(b, c, d, a, x[i + 15], 22, 1236535329);
            a = gg(a, b, c, d, x[i + 1], 5, -165796510);
            d = gg(d, a, b, c, x[i + 6], 9, -1069501632);
            c = gg(c, d, a, b, x[i + 11], 14, 643717713);
            b = gg(b, c, d, a, x[i + 0], 20, -373897302);
            a = gg(a, b, c, d, x[i + 5], 5, -701558691);
            d = gg(d, a, b, c, x[i + 10], 9, 38016083);
            c = gg(c, d, a, b, x[i + 15], 14, -660478335);
            b = gg(b, c, d, a, x[i + 4], 20, -405537848);
            a = gg(a, b, c, d, x[i + 9], 5, 568446438);
            d = gg(d, a, b, c, x[i + 14], 9, -1019803690);
            c = gg(c, d, a, b, x[i + 3], 14, -187363961);
            b = gg(b, c, d, a, x[i + 8], 20, 1163531501);
            a = gg(a, b, c, d, x[i + 13], 5, -1444681467);
            d = gg(d, a, b, c, x[i + 2], 9, -51403784);
            c = gg(c, d, a, b, x[i + 7], 14, 1735328473);
            b = gg(b, c, d, a, x[i + 12], 20, -1926607734);
            a = hh(a, b, c, d, x[i + 5], 4, -378558);
            d = hh(d, a, b, c, x[i + 8], 11, -2022574463);
            c = hh(c, d, a, b, x[i + 11], 16, 1839030562);
            b = hh(b, c, d, a, x[i + 14], 23, -35309556);
            a = hh(a, b, c, d, x[i + 1], 4, -1530992060);
            d = hh(d, a, b, c, x[i + 4], 11, 1272893353);
            c = hh(c, d, a, b, x[i + 7], 16, -155497632);
            b = hh(b, c, d, a, x[i + 10], 23, -1094730640);
            a = hh(a, b, c, d, x[i + 13], 4, 681279174);
            d = hh(d, a, b, c, x[i + 0], 11, -358537222);
            c = hh(c, d, a, b, x[i + 3], 16, -722521979);
            b = hh(b, c, d, a, x[i + 6], 23, 76029189);
            a = hh(a, b, c, d, x[i + 9], 4, -640364487);
            d = hh(d, a, b, c, x[i + 12], 11, -421815835);
            c = hh(c, d, a, b, x[i + 15], 16, 530742520);
            b = hh(b, c, d, a, x[i + 2], 23, -995338651);
            a = ii(a, b, c, d, x[i + 0], 6, -198630844);
            d = ii(d, a, b, c, x[i + 7], 10, 1126891415);
            c = ii(c, d, a, b, x[i + 14], 15, -1416354905);
            b = ii(b, c, d, a, x[i + 5], 21, -57434055);
            a = ii(a, b, c, d, x[i + 12], 6, 1700485571);
            d = ii(d, a, b, c, x[i + 3], 10, -1894986606);
            c = ii(c, d, a, b, x[i + 10], 15, -1051523);
            b = ii(b, c, d, a, x[i + 1], 21, -2054922799);
            a = ii(a, b, c, d, x[i + 8], 6, 1873313359);
            d = ii(d, a, b, c, x[i + 15], 10, -30611744);
            c = ii(c, d, a, b, x[i + 6], 15, -1560198380);
            b = ii(b, c, d, a, x[i + 13], 21, 1309151649);
            a = ii(a, b, c, d, x[i + 4], 6, -145523070);
            d = ii(d, a, b, c, x[i + 11], 10, -1120210379);
            c = ii(c, d, a, b, x[i + 2], 15, 718787259);
            b = ii(b, c, d, a, x[i + 9], 21, -343485551);

            a = addme(a, olda);
            b = addme(b, oldb);
            c = addme(c, oldc);
            d = addme(d, oldd);

            i += 16;
        }

        return [a, b, c, d];
    }
}
#end
