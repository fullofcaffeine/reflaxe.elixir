package tools;

#if macro
import haxe.crypto.Sha256;
import haxe.io.Bytes;
import haxe.macro.Expr;
import reflaxe.elixir.Sha256Hex.sha256Hex;

/**
 * Focused contract for the macro-interpreter SHA-256 of the output ownership
 * check: it must give exactly the digest of `haxe.crypto.Sha256`.
 */
class TestSha256Hex {
	public static function run():Expr {
		// FIPS 180-4 example vectors.
		expect("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
		expect("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
		expect("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");

		// Every length around the padding limits, then random lengths and bytes.
		var seed = 20261123;
		function next():Int {
			seed = (seed * 1103515245 + 12345) & 0x7fffffff;
			return seed;
		}
		var lengths = [for (length in 0...200) length];
		for (_ in 0...60)
			lengths.push(next() % 70000);
		for (length in lengths) {
			var bytes = Bytes.alloc(length);
			for (index in 0...length)
				bytes.set(index, next() & 0xff);
			var expected = Sha256.make(bytes).toHex().toLowerCase();
			var actual = sha256Hex(bytes);
			if (actual != expected)
				throw 'sha256Hex differs from haxe.crypto.Sha256 for $length bytes: $actual != $expected';
		}

		Sys.println("Output digest contract passed (" + (lengths.length + 3) + " inputs)");
		return macro null;
	}

	static function expect(text:String, digest:String):Void {
		var actual = sha256Hex(Bytes.ofString(text));
		if (actual != digest)
			throw 'sha256Hex("$text") = $actual, expected $digest';
	}
}
#end
