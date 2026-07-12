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
	@:describe("upstream Haxe unitstd: Date")
	@:test
	function testDate():Void {
		UpstreamUnitStdMacro.assertSpec("Date.unit.hx");
	}

	@:describe("upstream Haxe unitstd: DateTools")
	@:test
	function testDateTools():Void {
		UpstreamUnitStdMacro.assertSpec("DateTools.unit.hx");
	}

	@:describe("upstream Haxe unitstd: EReg")
	@:test
	function testEReg():Void {
		UpstreamUnitStdMacro.assertSpec("EReg.unit.hx");
	}

	@:describe("upstream Haxe unitstd: StringBuf")
	@:test
	function testStringBuf():Void {
		UpstreamUnitStdMacro.assertSpec("StringBuf.unit.hx");
	}

	@:describe("upstream Haxe unitstd: String")
	@:test
	function testString():Void {
		UpstreamUnitStdMacro.assertSpec("String.unit.hx");
	}

	@:describe("upstream Haxe unitstd: StringTools")
	@:test
	function testStringTools():Void {
		UpstreamUnitStdMacro.assertSpec("StringTools.unit.hx");
	}

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

	@:describe("upstream Haxe unitstd: haxe.crypto.Hmac")
	@:test
	function testHaxeCryptoHmac():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Hmac.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.crypto.Sha1")
	@:test
	function testHaxeCryptoSha1():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Sha1.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.crypto.Sha224")
	@:test
	function testHaxeCryptoSha224():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Sha224.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.crypto.Sha256")
	@:test
	function testHaxeCryptoSha256():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Sha256.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.CallStack")
	@:test
	function testHaxeCallStack():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/CallStack.unit.hx");
	}

	@:describe("upstream Haxe unitstd: IntIterator")
	@:test
	function testIntIterator():Void {
		UpstreamUnitStdMacro.assertSpec("IntIterator.unit.hx");
	}

	@:describe("upstream Haxe unitstd: List")
	@:test
	function testList():Void {
		UpstreamUnitStdMacro.assertSpec("List.unit.hx");
	}

	@:describe("upstream Haxe unitstd: Math")
	@:test
	function testMath():Void {
		UpstreamUnitStdMacro.assertSpec("Math.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.DynamicAccess")
	@:test
	function testHaxeDynamicAccess():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/DynamicAccess.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.ds.GenericStack")
	@:test
	function testHaxeDsGenericStack():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/ds/GenericStack.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.ds.Vector")
	@:test
	function testHaxeDsVector():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/ds/Vector.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.io.BytesBuffer")
	@:test
	function testHaxeIoBytesBuffer():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/io/BytesBuffer.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.io.ArrayBufferView")
	@:test
	function testHaxeIoArrayBufferView():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/io/ArrayBufferView.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.io.FPHelper")
	@:test
	function testHaxeIoFPHelper():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/io/FPHelper.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.io.Float32Array")
	@:test
	function testHaxeIoFloat32Array():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/io/Float32Array.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.io.Float64Array")
	@:test
	function testHaxeIoFloat64Array():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/io/Float64Array.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.io.Int32Array")
	@:test
	function testHaxeIoInt32Array():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/io/Int32Array.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.io.Path")
	@:test
	function testHaxeIoPath():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/io/Path.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.io.UInt8Array")
	@:test
	function testHaxeIoUInt8Array():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/io/UInt8Array.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.io.UInt16Array")
	@:test
	function testHaxeIoUInt16Array():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/io/UInt16Array.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.io.UInt32Array")
	@:test
	function testHaxeIoUInt32Array():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/io/UInt32Array.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.iterators.StringIteratorUnicode")
	@:test
	function testHaxeIteratorsStringIteratorUnicode():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/iterators/StringIteratorUnicode.unit.hx");
	}

	@:describe("upstream Haxe unitstd: haxe.iterators.StringKeyValueIteratorUnicode")
	@:test
	function testHaxeIteratorsStringKeyValueIteratorUnicode():Void {
		UpstreamUnitStdMacro.assertSpec("haxe/iterators/StringKeyValueIteratorUnicode.unit.hx");
	}
}
