import haxe.crypto.BaseCode;
import haxe.io.Bytes;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Void {
		var hex = new BaseCode(Bytes.ofString("0123456789abcdef"));
		var binary = Bytes.ofHex("00ff10");
		var encodedHex = hex.encodeBytes(binary);
		assertThat(encodedHex.toString() == "00ff10", "hex encode failed");
		assertThat(hex.decodeBytes(Bytes.ofString("00ff10")).toHex() == "00ff10", "hex decode failed");

		assertThat(BaseCode.encode("A", "01") == "01000001", "binary string encode failed");
		assertThat(BaseCode.decode("01000001", "01") == "A", "binary string decode failed");

		try {
			new BaseCode(Bytes.ofString("abc"));
			assertThat(false, "non-power-of-two dictionary should throw");
		} catch (error:Dynamic) {
			assertThat(Std.string(error) == "BaseCode : base length must be a power of two.", "invalid base length error mismatch");
		}

		try {
			hex.decodeBytes(Bytes.ofString("0g"));
			assertThat(false, "invalid encoded character should throw");
		} catch (error:Dynamic) {
			assertThat(Std.string(error) == "BaseCode : invalid encoded char", "invalid encoded character error mismatch");
		}
	}
}
