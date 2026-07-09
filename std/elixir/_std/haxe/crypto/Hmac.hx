package haxe.crypto;

import haxe.io.Bytes;

/**
 * Hash methods for HMAC calculation.
 */
enum HashMethod {
	MD5;
	SHA1;
	SHA256;
}

/**
 * Hmac (Elixir target)
 *
 * WHAT
 * - Canonical Haxe `haxe.crypto.Hmac` API for MD5, SHA-1, and SHA-256 HMAC
 *   digests.
 *
 * WHY
 * - HMAC is a common portable stdlib surface for signatures and protocol
 *   compatibility. BEAM exposes native HMAC primitives through `:crypto`, so
 *   generated Elixir should use those directly instead of emitting the portable
 *   byte-loop implementation.
 *
 * HOW
 * - Runtime delegates to `:crypto.mac(:hmac, algorithm, key, message)` and
 *   wraps the returned binary as `haxe.io.Bytes`.
 * - Macro/eval contexts use the upstream-compatible pure-Haxe construction and
 *   the local pure digest fallbacks so macro execution remains target-free.
 */
@:native("Haxe.Crypto.Hmac")
class Hmac {
	var method:HashMethod;

	public function new(hashMethod:HashMethod) {
		method = hashMethod;
	}

	public function make(key:Bytes, msg:Bytes):Bytes {
		#if (macro || (!reflaxe_runtime && !elixir))
		var blockSize = switch (method) {
			case MD5, SHA1, SHA256: 64;
		}

		if (key.length > blockSize) {
			key = doHash(key);
		}
		key = nullPad(key, blockSize);

		var ki = new haxe.io.BytesBuffer();
		var ko = new haxe.io.BytesBuffer();
		for (i in 0...key.length) {
			ko.addByte(key.get(i) ^ 0x5c);
			ki.addByte(key.get(i) ^ 0x36);
		}
		ki.add(msg);
		ko.add(doHash(ki.getBytes()));
		return doHash(ko.getBytes());
		#else
		var digest = untyped __elixir__(":crypto.mac(:hmac, {0}, {1}, {2})", nativeAlgorithm(), key.getData(), msg.getData());
		return Bytes.ofData(digest);
		#end
	}

	#if (macro || (!reflaxe_runtime && !elixir))
	function doHash(b:Bytes):Bytes {
		return switch (method) {
			case MD5: Md5.make(b);
			case SHA1: Sha1.make(b);
			case SHA256: Sha256.make(b);
		}
	}

	function nullPad(s:Bytes, chunkLen:Int):Bytes {
		var r = chunkLen - (s.length % chunkLen);
		if (r == chunkLen && s.length != 0)
			return s;
		var sb = new haxe.io.BytesBuffer();
		sb.add(s);
		for (_ in 0...r)
			sb.addByte(0);
		return sb.getBytes();
	}
	#else
	function nativeAlgorithm():Dynamic {
		return switch (method) {
			case MD5: untyped __elixir__(":md5");
			case SHA1: untyped __elixir__(":sha");
			case SHA256: untyped __elixir__(":sha256");
		}
	}
	#end
}
