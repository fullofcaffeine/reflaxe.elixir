package sys.ssl;

import elixir.types.Term;
import haxe.io.Bytes;

/**
 * sys.ssl.Digest (Elixir target)
 *
 * WHAT
 * - Digest hashing backed by Erlang/OTP `:crypto`.
 *
 * WHY
 * - Hashing is portable and maps cleanly to BEAM primitives.
 * - Erlang's `:public_key` module signs and verifies the decoded keys that the
 *   target `Key` implementation already owns.
 *
 * HOW
 * - `make()` maps Haxe digest names to `:crypto.hash/2`.
 * - `sign()` and `verify()` use the same digest map with
 *   `:public_key.sign/3` and `:public_key.verify/4`.
 */
class Digest {
	public static function make(data:Bytes, alg:DigestAlgorithm):Bytes {
		return Bytes.ofData(untyped __elixir__(':crypto.hash(Digest.algorithm_atom({1}), {0})', data.getData(), alg));
	}

	public static function sign(data:Bytes, privKey:Key, alg:DigestAlgorithm):Bytes {
		return Bytes.ofData(DigestState.sign(data.getData(), privKey.toSslKey(), algorithmAtom(alg)));
	}

	public static function verify(data:Bytes, signature:Bytes, pubKey:Key, alg:DigestAlgorithm):Bool {
		return DigestState.verify(data.getData(), signature.getData(), pubKey.toSslKey(), algorithmAtom(alg));
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

private class DigestState {
	public static function sign(data:Term, privateKey:Term, algorithm:Term):Term {
		return untyped __elixir__(':public_key.sign({0}, {2}, {1})', data, privateKey, algorithm);
	}

	public static function verify(data:Term, signature:Term, publicKey:Term, algorithm:Term):Bool {
		return untyped __elixir__(':public_key.verify({0}, {3}, {1}, {2})', data, signature, publicKey, algorithm);
	}
}
