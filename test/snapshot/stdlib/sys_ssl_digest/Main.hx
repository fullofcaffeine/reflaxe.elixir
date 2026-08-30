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
		var privateDer = Base64.decode("MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAMjQa1RTzP4JTemH9uOrATsOABsYGkOihKqe4r9FBuB8lJy4wmSIQIjA4o/TAPcdWYEJLujZ0jiFw5HjdbOgp+TS5bzfSDNeV/7uZaN09EpIlND0km+ZvauKU/qGSlq0eyZIrWRbmQGcreM1W9OhYhxnAFkTLdCImgfETDQUwTxbAgMBAAECgYBRsvGnqjxhMhnfo/BfKchjZUvHuiOdVrZQ0DmCBaxJkoXHySdVTVWsDYVfbEIdR3SNmdXa6But4UXyya6uOPN03ZZFAGIPVzPOGMMw92r4ti8cZtPYqWQxWeMwVbxH7doXtsytn2nGifLWkb2xYOr9ZSax9TMLJF8nFfgD4YltSQJBAOPMeT6AXxp25p2AeV/c6+/txx/UMoXgu/M2pwN0ixLU+ENpgiV5gAqhl/wqdo1tTswenO8CFk+mvxtxpCEjcd8CQQDhrLwb1xGxHyexHekpebkk/U9sB1uH26Rmzhz57wSLBMQ7+D//CVZPQfNdow06Pid7SuWrAwFEq7ObhrI7jl0FAkEArlNnIY6JuS3us++CcvsUz2qurMvt0gg2rRxQ2VMRrtquFqCiiV0ewIQDVGWGjhptZ8WxoTJ+snvP2gewa++9DwJAR19xEsD/SGxZCkwybLqhkpBGqRzeluYhZZ40TduJLUpxoaHO46MZV/G8vVWPHmd/5x916ZMGuKgxIrQD9I/+3QJBAIUwCoU84cF5L024f2SaxDQIvGmdkvKeHJTnzfXso/xhm4M0mdSbKKU1e4/tBhYkf5JDV1+eOMALiBRbVQx6Sfs=");
		var publicDer = Base64.decode("MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDI0GtUU8z+CU3ph/bjqwE7DgAbGBpDooSqnuK/RQbgfJScuMJkiECIwOKP0wD3HVmBCS7o2dI4hcOR43WzoKfk0uW830gzXlf+7mWjdPRKSJTQ9JJvmb2rilP6hkpatHsmSK1kW5kBnK3jNVvToWIcZwBZEy3QiJoHxEw0FME8WwIDAQAB");
		var privateKey = Key.readDER(privateDer, false);
		var publicKey = Key.readDER(publicDer, true);
		var message = Bytes.ofString("signed by ordinary Haxe");
		var signature = Digest.sign(message, privateKey, DigestAlgorithm.SHA256);
		assertThat(signature.length > 0, "Digest.sign should produce a signature");
		assertThat(Digest.verify(message, signature, publicKey, DigestAlgorithm.SHA256), "Digest.verify should accept the signed message");
		assertThat(!Digest.verify(Bytes.ofString("changed"), signature, publicKey, DigestAlgorithm.SHA256), "Digest.verify should reject changed data");
	}
}
