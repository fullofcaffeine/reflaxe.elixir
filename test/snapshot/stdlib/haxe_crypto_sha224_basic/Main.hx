import haxe.crypto.Sha224;
import haxe.io.Bytes;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Void {
		assertThat(Sha224.encode("abc") == "23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7", "sha224 encode abc failed");
		assertThat(Sha224.encode("") == "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f", "sha224 encode empty failed");
		assertThat(Sha224.make(Bytes.ofString("abc")).toHex() == "23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7", "sha224 make abc failed");

		var binary = Bytes.alloc(3);
		binary.set(0, 0x00);
		binary.set(1, 0xFF);
		binary.set(2, 0x10);
		assertThat(Sha224.make(binary).toHex() == "fb00d9d04bdeeb4c51a031ab62ad806c6b8d293efafb8456deae0320", "sha224 make binary failed");
	}
}
