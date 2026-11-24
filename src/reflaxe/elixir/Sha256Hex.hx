package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.ds.Vector;
import haxe.io.Bytes;

/**
 * SHA-256 for the generated-output ownership check, written for Haxe's macro
 * interpreter.
 *
 * WHAT
 * - `sha256Hex(bytes)` returns the SHA-256 digest of `bytes` as 64 lower-case
 *   hex characters, the same text as
 *   `haxe.crypto.Sha256.make(bytes).toHex().toLowerCase()`.
 *
 * WHY
 * - The compiler runs in Haxe's macro interpreter, where the standard
 *   `haxe.crypto.Sha256` is slow: about 30 ms for 30 KB on a loaded machine.
 *   Each publication on a compilation server hashes the whole
 *   `_GeneratedFiles.json` and the generation record, which grow with the
 *   program. On the todo-app that was most of the output transaction of a
 *   one-class edit, and most of the 0.57 s of file hashing of a full build.
 * - The standard code splits each 32-bit addition into two 16-bit halves, so
 *   that it is correct on targets without 32-bit integers. The interpreter has
 *   32-bit integers, and this code adds them directly. It also reads the
 *   message from the bytes one block at a time, without first building an
 *   array of words for the whole message. It is about 2.4 times faster.
 *
 * SAFETY
 * - The digest is the same SHA-256 (FIPS 180-4). The focused test compares it
 *   with `haxe.crypto.Sha256` for standard vectors and for random inputs of
 *   many lengths, including every length around the 55-, 56- and 64-byte
 *   padding limits.
 * - The generation digest of the manifest used `haxe.crypto.Sha256.encode`
 *   on a string. That function gives the message length in characters, not
 *   in UTF-8 bytes, so for non-ASCII text it is not SHA-256 and differs from
 *   the digest that Mix computes (`HaxeGeneratedOutput`). Generated paths are
 *   ASCII Elixir file names, where the two agree. The compiler now hashes
 *   the UTF-8 bytes, as Mix does.
 * - Haxe's `Int` is a 32-bit integer in the macro interpreter, and `+`, `<<`
 *   and `>>>` wrap there as SHA-256 needs. Do not use this function on a
 *   target where `Int` is wider; the compiler only calls it in macro code.
 */
function sha256Hex(bytes:Bytes):String {
	final length = bytes.length;
	// The message, one 0x80 byte, zero bytes, and the 64-bit bit length.
	final paddedLength = ((length + 9 + 63) >> 6) << 6;
	final padded = Bytes.alloc(paddedLength);
	padded.blit(0, bytes, 0, length);
	padded.set(length, 0x80);
	// The bit length is below 2^32 for every input that a Haxe Bytes can hold
	// in the interpreter, so the upper four length bytes stay zero.
	final bitLength = length * 8;
	padded.set(paddedLength - 4, bitLength >>> 24);
	padded.set(paddedLength - 3, (bitLength >>> 16) & 0xff);
	padded.set(paddedLength - 2, (bitLength >>> 8) & 0xff);
	padded.set(paddedLength - 1, bitLength & 0xff);
	padded.set(paddedLength - 5, (length >>> 29) & 0xff);

	var stateA = 0x6a09e667;
	var stateB = 0xbb67ae85;
	var stateC = 0x3c6ef372;
	var stateD = 0xa54ff53a;
	var stateE = 0x510e527f;
	var stateF = 0x9b05688c;
	var stateG = 0x1f83d9ab;
	var stateH = 0x5be0cd19;
	final words = new Vector<Int>(64);
	final constants = ROUND_CONSTANTS;
	var offset = 0;
	while (offset < paddedLength) {
		for (index in 0...16) {
			final at = offset + index * 4;
			words[index] = (padded.get(at) << 24) | (padded.get(at + 1) << 16) | (padded.get(at + 2) << 8) | padded.get(at + 3);
		}
		for (index in 16...64) {
			final early = words[index - 15];
			final late = words[index - 2];
			final wordMixEarly = ((early >>> 7) | (early << 25)) ^ ((early >>> 18) | (early << 14)) ^ (early >>> 3);
			final wordMixLate = ((late >>> 17) | (late << 15)) ^ ((late >>> 19) | (late << 13)) ^ (late >>> 10);
			words[index] = words[index - 16] + wordMixEarly + words[index - 7] + wordMixLate;
		}
		var a = stateA;
		var b = stateB;
		var c = stateC;
		var d = stateD;
		var e = stateE;
		var f = stateF;
		var g = stateG;
		var h = stateH;
		for (index in 0...64) {
			final rotatedE = ((e >>> 6) | (e << 26)) ^ ((e >>> 11) | (e << 21)) ^ ((e >>> 25) | (e << 7));
			final choice = (e & f) ^ (~e & g);
			final roundSumE = h + rotatedE + choice + constants[index] + words[index];
			final rotatedA = ((a >>> 2) | (a << 30)) ^ ((a >>> 13) | (a << 19)) ^ ((a >>> 22) | (a << 10));
			final majority = (a & b) ^ (a & c) ^ (b & c);
			final roundSumA = rotatedA + majority;
			h = g;
			g = f;
			f = e;
			e = d + roundSumE;
			d = c;
			c = b;
			b = a;
			a = roundSumE + roundSumA;
		}
		stateA += a;
		stateB += b;
		stateC += c;
		stateD += d;
		stateE += e;
		stateF += f;
		stateG += g;
		stateH += h;
		offset += 64;
	}

	final digest = Bytes.alloc(32);
	final state = [stateA, stateB, stateC, stateD, stateE, stateF, stateG, stateH];
	for (index in 0...8) {
		final value = state[index];
		digest.set(index * 4, value >>> 24);
		digest.set(index * 4 + 1, (value >>> 16) & 0xff);
		digest.set(index * 4 + 2, (value >>> 8) & 0xff);
		digest.set(index * 4 + 3, value & 0xff);
	}
	return digest.toHex();
}

/** The SHA-256 round constants (FIPS 180-4, section 4.2.2). */
private final ROUND_CONSTANTS:Array<Int> = [
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
];
#end
