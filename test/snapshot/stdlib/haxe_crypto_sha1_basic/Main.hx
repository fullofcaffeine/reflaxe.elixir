import haxe.crypto.Sha1;
import haxe.io.Bytes;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Void {
		assertThat(Sha1.encode("abc") == "a9993e364706816aba3e25717850c26c9cd0d89d", "sha1 encode abc failed");
		assertThat(Sha1.encode("") == "da39a3ee5e6b4b0d3255bfef95601890afd80709", "sha1 encode empty failed");
		assertThat(Sha1.make(Bytes.ofString("abc")).toHex() == "a9993e364706816aba3e25717850c26c9cd0d89d", "sha1 make abc failed");

		var binary = Bytes.alloc(3);
		binary.set(0, 0x00);
		binary.set(1, 0xFF);
		binary.set(2, 0x10);
		assertThat(Sha1.make(binary).toHex() == "a14c2fba17201c1ead45b6c4af4409fbfc16ba8a", "sha1 make binary failed");
	}
}
