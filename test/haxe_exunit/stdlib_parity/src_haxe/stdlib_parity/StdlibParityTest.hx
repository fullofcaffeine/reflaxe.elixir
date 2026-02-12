package stdlib_parity;

import haxe.Int32;
import haxe.Int64;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.crypto.Md5;
import haxe.iterators.MapKeyValueIterator;
import haxe.test.ExUnit.TestCase;
import haxe.test.Assert;

/**
 * StdlibParityTest
 *
 * BEAM runtime semantic tests for Elixir-target stdlib overrides.
 *
 * These tests are authored in Haxe and compiled to ExUnit modules, then loaded
 * by `test/exunit/test_helper.exs` during the mix test suite.
 */
@:exunit
class StdlibParityTest extends TestCase {
	static function pairToString<K, V>(pair:{key:K, value:V}):String {
		var keyString:String = cast untyped __elixir__('Kernel.to_string({0})', pair.key);
		var valueString:String = cast untyped __elixir__('Kernel.to_string({0})', pair.value);
		return keyString + ":" + valueString;
	}

	@:describe("haxe.iterators.ArrayIterator runtime semantics")
	@:test
	function testArrayIteratorManualLoop():Void {
		var iterator = [1, 2, 3].iterator();
		Assert.isTrue(iterator.hasNext());
		Assert.equals(1, iterator.next());
		Assert.isTrue(iterator.hasNext());
		Assert.equals(2, iterator.next());
		Assert.isTrue(iterator.hasNext());
		Assert.equals(3, iterator.next());
		Assert.isFalse(iterator.hasNext());
	}

	@:describe("haxe.iterators.MapKeyValueIterator runtime semantics")
	@:test
	function testMapKeyValueIteratorWithHaxeMapWrapper():Void {
		var wrappedMap:Map<String, Int> = new Map();
		wrappedMap.set("alpha", 1);
		wrappedMap.set("beta", 2);

		var iterator = new MapKeyValueIterator<String, Int>(cast wrappedMap);
		Assert.isTrue(iterator.hasNext());
		var first = pairToString(iterator.next());
		Assert.isTrue(iterator.hasNext());
		var second = pairToString(iterator.next());
		Assert.isFalse(iterator.hasNext());
		var seenPairs = [first, second];
		Assert.equals(2, seenPairs.length);
		Assert.contains(seenPairs, "alpha:1");
		Assert.contains(seenPairs, "beta:2");
	}

	@:describe("haxe.iterators.MapKeyValueIterator runtime semantics")
	@:test
	function testMapKeyValueIteratorWithPairListInput():Void {
		var pairList:haxe.Constraints.IMap<String, Int> = cast untyped __elixir__('[{"left", 10}, {"right", 20}]');
		var iterator = new MapKeyValueIterator<String, Int>(pairList);
		Assert.isTrue(iterator.hasNext());
		var first = pairToString(iterator.next());
		Assert.isTrue(iterator.hasNext());
		var second = pairToString(iterator.next());
		Assert.isFalse(iterator.hasNext());
		var seenPairs = [first, second];
		Assert.equals(2, seenPairs.length);
		Assert.contains(seenPairs, "left:10");
		Assert.contains(seenPairs, "right:20");
	}

	@:describe("haxe.iterators.MapKeyValueIterator runtime semantics")
	@:test
	function testMapKeyValueIteratorWithPlainElixirMap():Void {
		var nativeMap:haxe.Constraints.IMap<String, Int> = cast untyped __elixir__('%{"alpha" => 1, "beta" => 2}');
		var iterator = new MapKeyValueIterator<String, Int>(nativeMap);
		Assert.isTrue(iterator.hasNext());
		var first = pairToString(iterator.next());
		Assert.isTrue(iterator.hasNext());
		var second = pairToString(iterator.next());
		Assert.isFalse(iterator.hasNext());
		var seenPairs = [first, second];
		Assert.equals(2, seenPairs.length);
		Assert.contains(seenPairs, "alpha:1");
		Assert.contains(seenPairs, "beta:2");
	}

	@:describe("haxe.Int64")
	@:test
	function testInt64WrapOverflow():Void {
		var max = Int64.parseString("9223372036854775807");
		var wrapped = max + Int64.ofInt(1);
		Assert.equals("-9223372036854775808", Int64.toStr(wrapped));
	}

	@:describe("haxe.Int64")
	@:test
	function testInt64WrapUnderflow():Void {
		var min = Int64.parseString("-9223372036854775808");
		var wrapped = min - Int64.ofInt(1);
		Assert.equals("9223372036854775807", Int64.toStr(wrapped));
	}

	@:describe("haxe.Int64")
	@:test
	function testInt64HighLowRoundTrip():Void {
		var high = Int32.ofInt(305419896); // 0x12345678
		var low = Int32.ofInt(-1698898192); // 0x9ABCDEF0 (signed)
		var x = Int64.make(high, low);
		Assert.equals((high : Int), (x.high : Int));
		Assert.equals((low : Int), (x.low : Int));
	}

	@:describe("haxe.Int64")
	@:test
	function testInt64UnsignedShiftRight():Void {
		var negOne = Int64.ofInt(-1);
		var shifted = negOne >>> 1;
		Assert.equals("9223372036854775807", Int64.toStr(shifted));
	}

	@:describe("haxe.Int64")
	@:test
	function testInt64ToIntOverflowRaises():Void {
		Assert.doesNotRaise(() -> {
			var ok = Int64.toInt(Int64.parseString("2147483647"));
			Assert.equals(2147483647, ok);
		});

		Assert.raises(() -> {
			Int64.toInt(Int64.parseString("2147483648"));
		});
	}

	@:describe("haxe.ds.Map (native map backend)")
	@:test
	function testStringMapOps():Void {
		var m:Map<String, Int> = new Map();
		Assert.isFalse(m.exists("a"));

		m.set("a", 1);
		Assert.isTrue(m.exists("a"));
		Assert.equals(1, m.get("a"));

		m.set("a", 2);
		Assert.equals(2, m.get("a"));

		Assert.isTrue(m.remove("a"));
		Assert.isFalse(m.exists("a"));
		Assert.isNull(m.get("a"));
	}

	@:describe("haxe.ds.Map (native map backend)")
	@:test
	function testMapCopyIsPersistentValue():Void {
		var m:Map<String, Int> = new Map();
		m.set("k", 1);

		var snapshot = m.copy();
		m.set("k", 2);
		m.set("new", 9);

		Assert.equals(1, snapshot.get("k"));
		Assert.isNull(snapshot.get("new"));
		Assert.equals(2, m.get("k"));
	}

	@:describe("Reflect + JSON string keys")
	@:test
	function testReflectJsonStringKeys():Void {
		var obj:Dynamic = Json.parse("{\"a\":1,\"b\":2}");
		Assert.isTrue(Reflect.hasField(obj, "a"));
		Assert.isFalse(Reflect.hasField(obj, "c"));

		var a:Int = cast Reflect.field(obj, "a");
		Assert.equals(1, a);

		Reflect.setField(obj, "c", 3);
		var c:Int = cast Reflect.field(obj, "c");
		Assert.equals(3, c);

		Assert.isTrue(Reflect.deleteField(obj, "b"));
		Assert.isFalse(Reflect.hasField(obj, "b"));
	}

	@:describe("Reflect + object literal atom keys")
	@:test
	function testReflectObjectLiteralAtomKeys():Void {
		var obj = {foo: 1, bar: 2};

		var foo:Int = cast Reflect.field(obj, "foo");
		Assert.equals(1, foo);

		Reflect.setField(obj, "baz", 3);
		var baz:Int = cast Reflect.field(obj, "baz");
		Assert.equals(3, baz);

		Assert.isTrue(Reflect.deleteField(obj, "bar"));
		Assert.isFalse(Reflect.hasField(obj, "bar"));

		var fields = Reflect.fields(obj);
		Assert.contains(fields, "foo");
		Assert.contains(fields, "baz");
	}

	@:describe("haxe.DynamicAccess (uses Reflect on Elixir)")
	@:test
	function testDynamicAccessJsonPayload():Void {
		var payload:DynamicAccess<Int> = cast Json.parse("{\"x\":5}");
		Assert.equals(5, payload.get("x"));

		payload.set("y", 7);
		Assert.isTrue(payload.exists("y"));
		Assert.equals(7, payload.get("y"));

		Assert.isTrue(payload.remove("x"));
		Assert.isFalse(payload.exists("x"));
		Assert.isNull(payload.get("x"));
	}

	@:describe("haxe.crypto.Md5")
	@:test
	function testMd5EncodeLowerHex():Void {
		Assert.equals("098f6bcd4621d373cade4e832627b4f6", Md5.encode("test"));
	}
}
