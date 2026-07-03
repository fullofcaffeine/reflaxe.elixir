import haxe.crypto.Hmac;
import haxe.io.Bytes;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Void {
		var empty = Bytes.ofString("");
		assertThat(new Hmac(MD5).make(empty, empty).toHex() == "74e6f7298a9c2d168935f58c001bad88", "hmac md5 empty failed");
		assertThat(new Hmac(SHA1).make(empty, empty).toHex() == "fbdb1d1b18aa6c08324b7d64b71fb76370690e1d", "hmac sha1 empty failed");
		assertThat(new Hmac(SHA256).make(empty, empty).toHex() == "b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad",
			"hmac sha256 empty failed");

		var key = Bytes.ofString("key");
		var msg = Bytes.ofString("The quick brown fox jumps over the lazy dog");
		assertThat(new Hmac(MD5).make(key, msg).toHex() == "80070713463e7749b90c2dc24911e275", "hmac md5 quick fox failed");
		assertThat(new Hmac(SHA1).make(key, msg).toHex() == "de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9", "hmac sha1 quick fox failed");
		assertThat(new Hmac(SHA256).make(key, msg).toHex() == "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8",
			"hmac sha256 quick fox failed");
	}
}
