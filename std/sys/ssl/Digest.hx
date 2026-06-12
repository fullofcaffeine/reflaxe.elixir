package sys.ssl;

import haxe.io.Bytes;
import haxe.io.Error;

/**
 * sys.ssl.Digest (Elixir target)
 *
 * WHAT
 * - Digest hashing backed by Erlang/OTP `:crypto`.
 *
 * WHY
 * - Hashing is portable and maps cleanly to BEAM primitives.
 * - Signature operations require key algorithm inference and padding semantics
 *   that Haxe's generic `Key` API does not expose precisely enough yet.
 *
 * HOW
 * - `make()` maps Haxe digest names to `:crypto.hash/2`.
 * - `sign()` and `verify()` fail explicitly instead of guessing.
 */
class Digest {
	public static function make(data:Bytes, alg:DigestAlgorithm):Bytes {
		return Bytes.ofData(untyped __elixir__(':crypto.hash(Digest.algorithm_atom({1}), {0})', data.getData(), alg));
	}

	public static function sign(data:Bytes, privKey:Key, alg:DigestAlgorithm):Bytes {
		throw Error.Custom("sys.ssl.Digest.sign is not supported on the Elixir target yet; key algorithm/padding must be modeled explicitly before lowering to :public_key.sign/3");
	}

	public static function verify(data:Bytes, signature:Bytes, pubKey:Key, alg:DigestAlgorithm):Bool {
		throw Error.Custom("sys.ssl.Digest.verify is not supported on the Elixir target yet; key algorithm/padding must be modeled explicitly before lowering to :public_key.verify/4");
	}

	@:noCompletion public static function algorithmAtom(alg:DigestAlgorithm):elixir.types.Term {
		return untyped __elixir__('(
            case {0} do
              "MD5" -> :md5
              "SHA1" -> :sha
              "SHA224" -> :sha224
              "SHA256" -> :sha256
              "SHA384" -> :sha384
              "SHA512" -> :sha512
              "RIPEMD160" -> :ripemd160
              other -> raise "sys.ssl.Digest: unsupported digest algorithm #{inspect(other)}"
            end
        )', alg);
	}
}
