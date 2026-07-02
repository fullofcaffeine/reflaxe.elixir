import haxe.crypto.Sha256;
import haxe.io.Bytes;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Void {
		assertThat(Sha256.encode("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "sha256 encode abc failed");
		assertThat(Sha256.encode("") == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "sha256 encode empty failed");
		assertThat(Sha256.make(Bytes.ofString("abc")).toHex() == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "sha256 make abc failed");

		var binary = Bytes.alloc(3);
		binary.set(0, 0x00);
		binary.set(1, 0xFF);
		binary.set(2, 0x10);
		assertThat(Sha256.make(binary).toHex() == "2da45f2cd1f9c8e69a67abf7a6b26c282533d0a7686787a9533265418680d4d2", "sha256 make binary failed");
	}
}
