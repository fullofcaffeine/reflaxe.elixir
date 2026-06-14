package stdlib_parity;

import haxe.Int32;
import haxe.Int64;
import haxe.CallStack;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.Serializer;
import haxe.Template;
import haxe.Unserializer;
import haxe.crypto.Md5;
import haxe.ds.EnumValueMap;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Eof;
import haxe.iterators.MapKeyValueIterator;
import haxe.test.ExUnit.TestCase;
import haxe.test.Assert;
import reflaxe.elixir.IMap as IMapRuntime;

/**
 * StdlibParityTest
 *
 * BEAM runtime semantic tests for Elixir-target stdlib overrides.
 *
 * These tests are authored in Haxe and compiled to ExUnit modules, then loaded
 * by `test/exunit/test_helper.exs` during the mix test suite.
 */
enum ParityColor {
	Red;
	Green;
}

@:exunit
class StdlibParityTest extends TestCase {
	static function throwCallStackProbe():Void {
		throw "callstack-probe";
	}

	static function makeExceptionWithStack():haxe.Exception {
		return new haxe.Exception("details-probe");
	}

	static function arrayLength<T>(values:Array<T>):Int {
		return untyped __elixir__('length({0})', values);
	}

	static function pairToString<K, V>(pair:{key:K, value:V}):String {
		var keyString:String = cast untyped __elixir__('Kernel.to_string({0})', pair.key);
		var valueString:String = cast untyped __elixir__('Kernel.to_string({0})', pair.value);
		return keyString + ":" + valueString;
	}

	@:describe("haxe.CallStack")
	@:test
	function testCallStackReturnsPrintableStack():Void {
		var stack = CallStack.callStack();
		Assert.isTrue(stack.length > 0);

		var printed = CallStack.toString(stack);
		Assert.containsString(printed, "Called from ");
	}

	@:describe("haxe.CallStack")
	@:test
	function testExceptionStackUsesRescuedBeamStacktrace():Void {
		try {
			throwCallStackProbe();
			Assert.fail("throwCallStackProbe should throw");
		} catch (_:String) {
			var stack = CallStack.exceptionStack(true);
			Assert.isTrue(arrayLength(stack) > 0);

			var printed = CallStack.toString(stack);
			Assert.containsString(printed, "Called from ");
			Assert.containsString(printed, "throw_call_stack_probe");
		}
	}

	@:describe("haxe.CallStack")
	@:test
	function testCallStackSubtractAndExceptionDetails():Void {
		var current:CallStack = CallStack.callStack();
		var same:CallStack = current.copy();
		var diff = current.subtract(same);
		Assert.equals(0, diff.length);

		var exception = makeExceptionWithStack();
		var details = exception.details();
		Assert.containsString(details, "details-probe");
		Assert.containsString(details, "Called from ");
	}

	@:describe("haxe.Serializer / haxe.Unserializer")
	@:test
	function testSerializerPortableDataRoundTrip():Void {
		var wire = Serializer.run(["alpha", 42, true, null]);
		Assert.equals("ay5:alphai42tnh", wire);

		var value:Array<Dynamic> = Unserializer.run(wire);
		Assert.equals("alpha", value[0]);
		Assert.equals(42, value[1]);
		Assert.equals(true, value[2]);
		Assert.isNull(value[3]);
	}

	@:describe("haxe.Serializer / haxe.Unserializer")
	@:test
	function testSerializerNativeMapRoundTrip():Void {
		var map = new StringMap<Int>();
		map.set("one", 1);
		map.set("two", 2);

		var wire = Serializer.run(map);
		var value:StringMap<Int> = Unserializer.run(wire);

		Assert.equals(1, value.get("one"));
		Assert.equals(2, value.get("two"));
	}

	@:describe("haxe.Serializer / haxe.Unserializer")
	@:test
	function testSerializerInstanceBuffer():Void {
		var serializer = new Serializer();
		serializer.serialize("prefix");
		serializer.serialize(7);

		Assert.equals("y6:prefixi7", serializer.toString());
	}

	@:describe("haxe.Template")
	@:test
	function testTemplatePortableRendering():Void {
		var template = new Template("Hello ::user.name::! ::if enabled::on::else::off::end:: ::foreach items::::label::=::value::;::end::");
		var rendered = template.execute({
			enabled: true,
			user: {name: "BEAM"},
			items: [{label: "a", value: 1}, {label: "b", value: 2}]
		});

		Assert.equals("Hello BEAM! on a=1;b=2;", rendered);
	}

	@:describe("haxe.Template")
	@:test
	function testTemplateMacroRendering():Void {
		var template = new Template("$$upper(name)");
		var rendered = template.execute({name: "beam"}, {
			upper: function(resolve:String->String, name:String):String {
				return name.toUpperCase();
			}
		});

		Assert.equals("BEAM", rendered);
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

	@:describe("Reflaxe.Elixir.IMap")
	@:test
	function testIMapUnwrapPlainElixirMap():Void {
		var nativeMap = cast untyped __elixir__('%{"alpha" => 1, "beta" => 2}');
		var pairs:Array<{key:String, value:Int}> = IMapRuntime.unwrap(nativeMap);
		var seenPairs = [pairToString(pairs[0]), pairToString(pairs[1])];
		Assert.equals(2, pairs.length);
		Assert.contains(seenPairs, "alpha:1");
		Assert.contains(seenPairs, "beta:2");
	}

	@:describe("Reflaxe.Elixir.IMap")
	@:test
	function testIMapUnwrapPairList():Void {
		var pairList = cast untyped __elixir__('[{"left", 10}, %{key: "right", value: 20}]');
		var pairs:Array<{key:String, value:Int}> = IMapRuntime.unwrap(pairList);
		var seenPairs = [pairToString(pairs[0]), pairToString(pairs[1])];
		Assert.equals(2, pairs.length);
		Assert.contains(seenPairs, "left:10");
		Assert.contains(seenPairs, "right:20");
	}

	@:describe("Reflaxe.Elixir.IMap")
	@:test
	function testIMapUnwrapRejectsRuntimeStructs():Void {
		var runtimeStruct = cast untyped __elixir__('%{:__reflaxe_class__ => BalancedTree, :root => nil}');
		Assert.raises(() -> {
			IMapRuntime.unwrap(runtimeStruct);
		});
	}

	@:describe("UnicodeString")
	@:test
	function testUnicodeStringIteratesCodepoints():Void {
		var text:UnicodeString = "Aé🌍中";
		Assert.equals(4, text.length);

		var codes:Array<Int> = [];
		for (code in text) {
			codes.push(code);
		}

		Assert.equals(4, codes.length);
		Assert.equals(65, codes[0]);
		Assert.equals(233, codes[1]);
		Assert.equals(0x1F30D, codes[2]);
		Assert.equals(0x4E2D, codes[3]);
	}

	@:describe("UnicodeString")
	@:test
	function testUnicodeStringKeyValueIteratorUsesCharacterIndices():Void {
		var text:UnicodeString = "a🌍b";
		var entries:Array<String> = [];
		for (index => code in text) {
			entries.push(index + ":" + code);
		}

		Assert.equals(3, entries.length);
		Assert.equals("0:97", entries[0]);
		Assert.equals("1:127757", entries[1]);
		Assert.equals("2:98", entries[2]);
	}

	@:describe("UnicodeString")
	@:test
	function testUnicodeStringValidateUtf8():Void {
		var valid = Bytes.ofString("Aé🌍中");
		Assert.isTrue(UnicodeString.validate(valid, UTF8));

		var invalid = Bytes.ofData(cast untyped __elixir__('<<0xC0>>'));
		Assert.isFalse(UnicodeString.validate(invalid, UTF8));
	}

	@:describe("haxe.io.Bytes")
	@:test
	function testBytesCompareUsesBinaryOrdering():Void {
		var alpha = Bytes.ofString("alpha");
		var alphaCopy = Bytes.ofString("alpha");
		var beta = Bytes.ofString("beta");

		Assert.equals(0, alpha.compare(alphaCopy));
		Assert.equals(-1, alpha.compare(beta));
		Assert.equals(1, beta.compare(alpha));
	}

	@:describe("haxe.io.BytesInput/BytesOutput")
	@:test
	function testBytesInputOutputRoundTripAndEof():Void {
		var output = new BytesOutput();
		output.writeByte(0);
		output.writeString("hi");

		var bytes = output.getBytes();
		Assert.equals(3, bytes.length);

		var input = new BytesInput(bytes);
		Assert.equals(0, input.readByte());

		var buffer = Bytes.alloc(2);
		Assert.equals(2, input.readBytes(buffer, 0, 2));
		Assert.equals("hi", buffer.toString());

		Assert.raises(() -> {
			input.readByte();
		});
	}

	@:describe("haxe.io.BytesInput/BytesOutput")
	@:test
	function testBytesInputReadLineHandlesCrLfAndLf():Void {
		var input = new BytesInput(Bytes.ofString("alpha\r\nbeta\n"));
		Assert.equals("alpha", input.readLine());
		Assert.equals("beta", input.readLine());

		try {
			input.readLine();
			Assert.fail("readLine should throw Eof after the final line");
		} catch (_:Eof) {}
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
	function testIntMapOps():Void {
		var m:Map<Int, String> = new Map();
		Assert.isFalse(m.exists(1));

		m.set(1, "one");
		m.set(2, "two");
		Assert.isTrue(m.exists(1));
		Assert.equals("one", m.get(1));
		Assert.equals("two", m.get(2));

		Assert.isTrue(m.remove(1));
		Assert.isFalse(m.exists(1));
		Assert.isNull(m.get(1));
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

	@:describe("haxe.ds.Map (native map backend)")
	@:test
	function testMapToStringMapConversionPreservesEntries():Void {
		var m:Map<String, Int> = new Map();
		m.set("alpha", 1);
		m.set("beta", 2);

		var stringMap:StringMap<Int> = m;
		Assert.equals(1, stringMap.get("alpha"));
		Assert.equals(2, stringMap.get("beta"));

		stringMap.set("gamma", 3);
		Assert.equals(3, stringMap.get("gamma"));
		Assert.isNull(m.get("gamma"));
	}

	@:describe("haxe.ds.Map (native map backend)")
	@:test
	function testStringMapToMapConversionPreservesEntries():Void {
		var stringMap = new StringMap<Int>();
		stringMap.set("alpha", 1);

		var m:Map<String, Int> = stringMap;
		Assert.equals(1, m.get("alpha"));
	}

	@:describe("haxe.ds.Map (native map backend)")
	@:test
	function testMapToIntMapConversionPreservesEntries():Void {
		var m:Map<Int, String> = new Map();
		m.set(1, "one");
		m.set(2, "two");

		var intMap:IntMap<String> = m;
		Assert.equals("one", intMap.get(1));
		Assert.equals("two", intMap.get(2));

		intMap.set(3, "three");
		Assert.equals("three", intMap.get(3));
		Assert.isNull(m.get(3));
	}

	@:describe("haxe.ds.Map (native map backend)")
	@:test
	function testIntMapToMapConversionPreservesEntries():Void {
		var intMap = new IntMap<String>();
		intMap.set(7, "seven");

		var m:Map<Int, String> = intMap;
		Assert.equals("seven", m.get(7));
	}

	@:describe("haxe.ds.Map (native map backend)")
	@:test
	function testMapToEnumValueMapConversionPreservesEntries():Void {
		var m:Map<ParityColor, String> = new Map();
		m.set(Red, "red");
		m.set(Green, "green");

		var enumMap:EnumValueMap<ParityColor, String> = m;
		Assert.equals("red", enumMap.get(Red));
		Assert.equals("green", enumMap.get(Green));
	}

	@:describe("haxe.ds.Map (native map backend)")
	@:test
	function testDirectNativeMapCopyPreservesSnapshot():Void {
		var stringMap = new StringMap<Int>();
		stringMap.set("k", 1);

		var snapshot = stringMap.copy();
		stringMap.set("k", 2);
		stringMap.set("new", 9);

		Assert.equals(1, snapshot.get("k"));
		Assert.isNull(snapshot.get("new"));
		Assert.equals(2, stringMap.get("k"));
	}

	@:describe("haxe.ds.Map (native map backend)")
	@:test
	function testMapValueIterationUsesNativeMapValues():Void {
		var m:Map<String, Int> = new Map();
		m.set("first", 1);
		m.set("second", 2);

		var values:Array<Int> = [];
		for (value in m.iterator()) {
			values.push(value);
		}

		Assert.equals(2, values.length);
		Assert.contains(values, 1);
		Assert.contains(values, 2);
	}

	@:describe("haxe.ds.Map (native map backend)")
	@:test
	function testMapKeyValueIteratorUsesCanonicalRuntime():Void {
		var m:Map<String, Int> = new Map();
		m.set("alpha", 1);
		m.set("beta", 2);

		var iterator = m.keyValueIterator();
		Assert.isTrue(iterator.hasNext());
		var first = pairToString(iterator.next());
		Assert.isTrue(iterator.hasNext());
		var second = pairToString(iterator.next());
		Assert.isFalse(iterator.hasNext());

		var seenPairs = [first, second];
		Assert.contains(seenPairs, "alpha:1");
		Assert.contains(seenPairs, "beta:2");
	}

	@:describe("haxe.ds.Map (native map backend)")
	@:test
	function testMapToStringUsesInspectableNativeMap():Void {
		var m:Map<String, Int> = new Map();
		m.set("alpha", 1);

		var stringValue = m.toString();
		Assert.containsString(stringValue, "alpha");
		Assert.containsString(stringValue, "1");
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
