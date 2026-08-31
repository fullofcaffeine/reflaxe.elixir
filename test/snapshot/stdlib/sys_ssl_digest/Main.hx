import haxe.io.Bytes;
import haxe.crypto.Base64;
import sys.ssl.Digest;
import sys.ssl.DigestAlgorithm;
import sys.ssl.Key;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function pem(label:String, body:String):String {
		var lines:Array<String> = [];
		var offset = 0;
		while (offset < body.length) {
			lines.push(body.substr(offset, 64));
			offset += 64;
		}
		return "-----BEGIN " + label + "-----\n" + lines.join("\n") + "\n-----END " + label + "-----\n";
	}

	public static function main() {
		assertThat(Digest.make(Bytes.ofString("abc"), DigestAlgorithm.MD5).toHex() == "900150983cd24fb0d6963f7d28e17f72",
			"MD5 digest should match the standard vector");
		assertThat(Digest.make(Bytes.ofString("abc"), DigestAlgorithm.SHA1).toHex() == "a9993e364706816aba3e25717850c26c9cd0d89d",
			"SHA1 digest should match the standard vector");
		assertThat(Digest.make(Bytes.ofString("abc"), DigestAlgorithm.SHA224).toHex() == "23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7",
			"SHA224 digest should match the standard vector");
		assertThat(Digest.make(Bytes.ofString("abc"), DigestAlgorithm.SHA256).toHex() == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
			"SHA256 digest should match the standard vector");
		assertThat(Digest.make(Bytes.ofString("abc"), DigestAlgorithm.SHA384)
			.toHex() == "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7",
			"SHA384 digest should match the standard vector");
		assertThat(Digest.make(Bytes.ofString("abc"), DigestAlgorithm.SHA512)
			.toHex() == "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f",
			"SHA512 digest should match the standard vector");
		assertThat(Digest.make(Bytes.ofString("abc"), DigestAlgorithm.RIPEMD160).toHex() == "8eb208f7e05d987a9b044a8e98c6b087f15a0bfc",
			"RIPEMD160 digest should match the standard vector");

		// This fixed RSA key is test data. It does not protect a system.
		var privateBody = "MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAMjQa1RTzP4JTemH9uOrATsOABsYGkOihKqe4r9FBuB8lJy4wmSIQIjA4o/TAPcdWYEJLujZ0jiFw5HjdbOgp+TS5bzfSDNeV/7uZaN09EpIlND0km+ZvauKU/qGSlq0eyZIrWRbmQGcreM1W9OhYhxnAFkTLdCImgfETDQUwTxbAgMBAAECgYBRsvGnqjxhMhnfo/BfKchjZUvHuiOdVrZQ0DmCBaxJkoXHySdVTVWsDYVfbEIdR3SNmdXa6But4UXyya6uOPN03ZZFAGIPVzPOGMMw92r4ti8cZtPYqWQxWeMwVbxH7doXtsytn2nGifLWkb2xYOr9ZSax9TMLJF8nFfgD4YltSQJBAOPMeT6AXxp25p2AeV/c6+/txx/UMoXgu/M2pwN0ixLU+ENpgiV5gAqhl/wqdo1tTswenO8CFk+mvxtxpCEjcd8CQQDhrLwb1xGxHyexHekpebkk/U9sB1uH26Rmzhz57wSLBMQ7+D//CVZPQfNdow06Pid7SuWrAwFEq7ObhrI7jl0FAkEArlNnIY6JuS3us++CcvsUz2qurMvt0gg2rRxQ2VMRrtquFqCiiV0ewIQDVGWGjhptZ8WxoTJ+snvP2gewa++9DwJAR19xEsD/SGxZCkwybLqhkpBGqRzeluYhZZ40TduJLUpxoaHO46MZV/G8vVWPHmd/5x916ZMGuKgxIrQD9I/+3QJBAIUwCoU84cF5L024f2SaxDQIvGmdkvKeHJTnzfXso/xhm4M0mdSbKKU1e4/tBhYkf5JDV1+eOMALiBRbVQx6Sfs=";
		var publicBody = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDI0GtUU8z+CU3ph/bjqwE7DgAbGBpDooSqnuK/RQbgfJScuMJkiECIwOKP0wD3HVmBCS7o2dI4hcOR43WzoKfk0uW830gzXlf+7mWjdPRKSJTQ9JJvmb2rilP6hkpatHsmSK1kW5kBnK3jNVvToWIcZwBZEy3QiJoHxEw0FME8WwIDAQAB";
		var privateDer = Base64.decode(privateBody);
		var publicDer = Base64.decode(publicBody);
		var privateKey = Key.readDER(privateDer, false);
		var publicKey = Key.readDER(publicDer, true);
		var pkcs1PrivateKey = Key.readDER(Base64.decode("MIICXQIBAAKBgQDI0GtUU8z+CU3ph/bjqwE7DgAbGBpDooSqnuK/RQbgfJScuMJkiECIwOKP0wD3HVmBCS7o2dI4hcOR43WzoKfk0uW830gzXlf+7mWjdPRKSJTQ9JJvmb2rilP6hkpatHsmSK1kW5kBnK3jNVvToWIcZwBZEy3QiJoHxEw0FME8WwIDAQABAoGAUbLxp6o8YTIZ36PwXynIY2VLx7ojnVa2UNA5ggWsSZKFx8knVU1VrA2FX2xCHUd0jZnV2ugbreFF8smurjjzdN2WRQBiD1czzhjDMPdq+LYvHGbT2KlkMVnjMFW8R+3aF7bMrZ9pxony1pG9sWDq/WUmsfUzCyRfJxX4A+GJbUkCQQDjzHk+gF8aduadgHlf3Ovv7ccf1DKF4LvzNqcDdIsS1PhDaYIleYAKoZf8KnaNbU7MHpzvAhZPpr8bcaQhI3HfAkEA4ay8G9cRsR8nsR3pKXm5JP1PbAdbh9ukZs4c+e8EiwTEO/g//wlWT0HzXaMNOj4ne0rlqwMBRKuzm4ayO45dBQJBAK5TZyGOibkt7rPvgnL7FM9qrqzL7dIINq0cUNlTEa7arhagooldHsCEA1Rlho4abWfFsaEyfrJ7z9oHsGvvvQ8CQEdfcRLA/0hsWQpMMmy6oZKQRqkc3pbmIWWeNE3biS1KcaGhzuOjGVfxvL1Vjx5nf+cfdemTBrioMSK0A/SP/t0CQQCFMAqFPOHBeS9NuH9kmsQ0CLxpnZLynhyU58317KP8YZuDNJnUmyilNXuP7QYWJH+SQ1dfnjjAC4gUW1UMekn7"),
			false);
		var pkcs1PublicKey = Key.readDER(Base64.decode("MIGJAoGBAMjQa1RTzP4JTemH9uOrATsOABsYGkOihKqe4r9FBuB8lJy4wmSIQIjA4o/TAPcdWYEJLujZ0jiFw5HjdbOgp+TS5bzfSDNeV/7uZaN09EpIlND0km+ZvauKU/qGSlq0eyZIrWRbmQGcreM1W9OhYhxnAFkTLdCImgfETDQUwTxbAgMBAAE="),
			true);
		var message = Bytes.ofString("signed by ordinary Haxe");
		var signature = Digest.sign(message, privateKey, DigestAlgorithm.SHA256);
		assertThat(signature.length > 0, "Digest.sign should produce a signature");
		assertThat(Digest.verify(message, signature, publicKey, DigestAlgorithm.SHA256), "Digest.verify should accept the signed message");
		assertThat(!Digest.verify(Bytes.ofString("changed"), signature, publicKey, DigestAlgorithm.SHA256), "Digest.verify should reject changed data");
		var pkcs1Signature = Digest.sign(message, pkcs1PrivateKey, DigestAlgorithm.SHA256);
		assertThat(Digest.verify(message, pkcs1Signature, pkcs1PublicKey, DigestAlgorithm.SHA256), "Key.readDER should decode PKCS1 public and private keys");

		var privatePem = pem("PRIVATE KEY", privateBody);
		var publicPem = pem("PUBLIC KEY", publicBody);
		var encryptedPrivatePem = "-----BEGIN ENCRYPTED PRIVATE KEY-----\n"
			+ "MIIC5TBfBgkqhkiG9w0BBQ0wUjAxBgkqhkiG9w0BBQwwJAQQQpeDvIQjlTxrKxgn\n"
			+ "/btTRgICCAAwDAYIKoZIhvcNAgkFADAdBglghkgBZQMEASoEECsaOY5BCgXJdCmJ\n"
			+ "neDMFIcEggKA7TtMwBxUR1CO/GCtITAHK9cuCZd6OZZqoTjwEY9RpfXRNBD4NyGG\n"
			+ "K6ZuY/pUJP2xwXq0lqVkqJlGGrlI+OB2OP42bkCM9YtoZJR3EvSHKzEA8o9NArog\n"
			+ "XAiQBRp3Kh70jyraq7ckEt/qYIM1HncbQe79GSMjXTJ9tY0BIOd2thbyrBMobR/v\n"
			+ "0igLYrHC6r8J7i1BjmUunAir4wTwMGrhe0XqvpWXN6CDz8yKeyUkWPzetE0VUCUx\n"
			+ "cqLrRq2x8xpjaUS5aRajdejxx1/jT3PdD6U5Ji5s+rKJPc6W58veOZj3CLRraveT\n"
			+ "DxNQdGzQhfOeyfImXaic7Q4xY2Xsgft54I+VgVwo9lituF2M0tNrvsaa0I+oFISP\n"
			+ "7WjeTHOviguTuVZsMnLTupHd/zn+rwuoN+SNP0XLKtAmqnauJeCQHmXZt2U7Ix2Q\n"
			+ "0Hlmh3MqAqb3rxfNV4mlo5RyIBSIdlBVjYA+6/xBeMIilOoJGzkM41fPPKXsWLLH\n"
			+ "OV1CY6YQ9VkWsZfddxSy0b1fyQRMs+Utz4mOBnbqerHJPuNIW8WKnXsEHUYAMwPr\n"
			+ "Ah9Pyl2bMit8+UC1NfUec4A++PaKn37iHLBWBJkeGMssK2IcyQx+RtnIF6Oiv9LU\n"
			+ "o9rtn5dd/GAsNbMd8F0uMdXPl5aJj1tBx2rYdUx1IYNXulDprQxh5AdG/S5e/aBI\n"
			+ "ZWTaUW5VgGtVz+rHmuMi5f04m6/QPckRYEXDwPkDzrUI2TdVf4JJWfhIqpsvEJav\n"
			+ "xekP2PgIJZUoyceyKeYi5eq+slJCQ4avCELSiVPXHh/AWliXmPIQDfyLlIlrtIad\n"
			+ "kE+7MKp4FO/19vVes9zEuNIKp6BUaw8W6g==\n"
			+ "-----END ENCRYPTED PRIVATE KEY-----\n";
		var pemPrivateKey = Key.readPEM(privatePem, false);
		var pemPublicKey = Key.readPEM(publicPem, true);
		var pemSignature = Digest.sign(message, pemPrivateKey, DigestAlgorithm.SHA256);
		assertThat(Digest.verify(message, pemSignature, pemPublicKey, DigestAlgorithm.SHA256), "Key.readPEM should decode public and private keys");
		var encryptedPrivateKey = Key.readPEM(encryptedPrivatePem, false, "haxe-test-pass");
		var encryptedSignature = Digest.sign(message, encryptedPrivateKey, DigestAlgorithm.SHA256);
		assertThat(Digest.verify(message, encryptedSignature, pemPublicKey, DigestAlgorithm.SHA256),
			"Key.readPEM should decode an encrypted private key with its passphrase");

		var privatePath = "sys_ssl_key_private.pem";
		var publicPath = "sys_ssl_key_public.der";
		var encryptedPath = "sys_ssl_key_private_encrypted.pem";
		sys.io.File.saveContent(privatePath, privatePem);
		sys.io.File.saveBytes(publicPath, publicDer);
		sys.io.File.saveContent(encryptedPath, encryptedPrivatePem);
		var filePrivateKey = Key.loadFile(privatePath);
		var filePublicKey = Key.loadFile(publicPath, true);
		var fileEncryptedKey = Key.loadFile(encryptedPath, false, "haxe-test-pass");
		var fileSignature = Digest.sign(message, filePrivateKey, DigestAlgorithm.SHA256);
		assertThat(Digest.verify(message, fileSignature, filePublicKey, DigestAlgorithm.SHA256), "Key.loadFile should detect PEM and DER files");
		var fileEncryptedSignature = Digest.sign(message, fileEncryptedKey, DigestAlgorithm.SHA256);
		assertThat(Digest.verify(message, fileEncryptedSignature, filePublicKey, DigestAlgorithm.SHA256), "Key.loadFile should pass a private-key passphrase");
		sys.FileSystem.deleteFile(privatePath);
		sys.FileSystem.deleteFile(publicPath);
		sys.FileSystem.deleteFile(encryptedPath);
	}
}
