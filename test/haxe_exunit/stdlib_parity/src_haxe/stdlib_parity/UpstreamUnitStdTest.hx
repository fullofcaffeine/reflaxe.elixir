package stdlib_parity;

import haxe.test.ExUnit.TestCase;
import stdlib_parity.upstream.UpstreamUnitStdMacro;

/**
 * Checked-in upstream Haxe `unitstd` specs compiled to ExUnit on BEAM.
 *
 * This complements snapshots: snapshots lock generated Elixir shape, while
 * these tests prove selected stdlib semantics execute correctly at runtime.
 */
@:exunit
class UpstreamUnitStdTest extends TestCase {
	@:describe("upstream Haxe unitstd: haxe.crypto.Base64")
	@:test
	function testHaxeCryptoBase64():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Base64.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.crypto.Md5")
	@:test
	function testHaxeCryptoMd5():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Md5.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.crypto.Sha1")
	@:test
	function testHaxeCryptoSha1():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Sha1.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.io.Path")
	@:test
	function testHaxeIoPath():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/io/Path.unit.hx");
	}
}
