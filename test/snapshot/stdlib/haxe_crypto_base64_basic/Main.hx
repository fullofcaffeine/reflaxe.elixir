import haxe.crypto.Base64;
import haxe.io.Bytes;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Void {
		var hello = Bytes.ofString("hello");
		assertThat(Base64.encode(hello) == "aGVsbG8=", "standard padded encode failed");
		assertThat(Base64.encode(hello, false) == "aGVsbG8", "standard unpadded encode failed");
		assertThat(Base64.decode("aGVsbG8=").toString() == "hello", "standard padded decode failed");
		assertThat(Base64.decode("aGVsbG8", false).toString() == "hello", "standard unpadded decode failed");

		var url = Bytes.ofString("fo?");
		assertThat(Base64.urlEncode(url) == "Zm8_", "url unpadded encode failed");
		assertThat(Base64.urlDecode("Zm8_").toString() == "fo?", "url unpadded decode failed");

		var shortUrl = Bytes.ofString("fo");
		assertThat(Base64.urlEncode(shortUrl, true) == "Zm8=", "url padded encode failed");
		assertThat(Base64.urlDecode("Zm8=", true).toString() == "fo", "url padded decode failed");

		var binary = Bytes.alloc(3);
		binary.set(0, 0xFB);
		binary.set(1, 0xFF);
		binary.set(2, 0x00);
		assertThat(Base64.encode(binary) == "+/8A", "standard alphabet encode failed");
		assertThat(Base64.urlEncode(binary) == "-_8A", "url alphabet encode failed");
	}
}
