import haxe.io.Bytes;
import sys.ssl.Digest;
import sys.ssl.DigestAlgorithm;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function rejectUnsupportedSign():Void {
		try {
			Digest.sign(Bytes.ofString("abc"), null, DigestAlgorithm.SHA256);
			throw "Digest.sign should fail explicitly on the Elixir target";
		} catch (error:haxe.io.Error) {
			switch (error) {
				case Custom(message):
					assertThat(message != "", "Digest.sign should explain unsupported status");
				default:
					throw "Digest.sign should raise Error.Custom";
			}
		}
	}

	public static function main() {
		var digest = Digest.make(Bytes.ofString("abc"), DigestAlgorithm.SHA256);
		assertThat(digest.toHex() == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "SHA256 digest should match :crypto.hash output");
		rejectUnsupportedSign();
	}
}
