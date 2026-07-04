package stdlib_parity;

import haxe.Int32;
import haxe.Int64;
import haxe.CallStack;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.Serializer;
import haxe.Template;
import haxe.Timer;
import haxe.Unserializer;
import haxe.crypto.BaseCode;
import haxe.crypto.Base64;
import haxe.crypto.Adler32;
import haxe.crypto.Crc32;
import haxe.crypto.Hmac;
import haxe.crypto.Md5;
import haxe.crypto.Sha1;
import haxe.crypto.Sha224;
import haxe.crypto.Sha256;
import haxe.ds.ArraySort;
import haxe.ds.EnumValueMap;
import haxe.ds.GenericStack;
import haxe.ds.HashMap;
import haxe.ds.IntMap;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.exceptions.ArgumentException;
import haxe.exceptions.NotImplementedException;
import haxe.format.JsonParser;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Eof;
import haxe.io.Error;
import haxe.io.FPHelper;
import haxe.io.Path;
import haxe.io.StringInput;
import haxe.iterators.HashMapKeyValueIterator;
import haxe.iterators.MapKeyValueIterator;
import haxe.iterators.StringIterator;
import haxe.iterators.StringKeyValueIterator;
import sys.thread.Thread;
import haxe.test.ExUnit.TestCase;
import haxe.test.Assert;
import elixir.ErlangMath;
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

class SortNode {
	public var key:Int;
	public var label:String;

	public function new(key:Int, label:String) {
		this.key = key;
		this.label = label;
	}
}

class HashKey {
	public var id:Int;
	public var label:String;

	final hash:Int;

	public function new(id:Int, label:String, hash:Int) {
		this.id = id;
		this.label = label;
		this.hash = hash;
	}

	public function hashCode():Int {
		return hash;
	}

	public function toString():String {
		return label;
	}
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

	static function pairIntBool(value:Int, flag:Bool):String {
		return Std.string(value) + ":" + Std.string(flag);
	}

	static function pairIntInt(left:Int, right:Int):String {
		return Std.string(left) + ":" + Std.string(right);
	}

	static function throwPortableNan():Void {
		throw Math.NaN;
	}

	static function progressCurrentThreadEvents(?timeout:Float):Void {
		var actualTimeout = timeout == null ? 0.2 : timeout;
		var events = Thread.current().events;
		Assert.isTrue(events.wait(actualTimeout));
		events.progress();
	}

	@:describe("Haxe Float special values")
	@:test
	function testFloatSpecialConstantsClassifyAndFormat():Void {
		Assert.isTrue(Math.isNaN(Math.NaN));
		Assert.isFalse(Math.isFinite(Math.NaN));
		Assert.isFalse(Math.isFinite(Math.POSITIVE_INFINITY));
		Assert.isFalse(Math.isFinite(Math.NEGATIVE_INFINITY));
		Assert.isTrue(Math.isFinite(1.7976931348623157e308));

		Assert.equals("NaN", Std.string(Math.NaN));
		Assert.equals("Infinity", Std.string(Math.POSITIVE_INFINITY));
		Assert.equals("-Infinity", Std.string(Math.NEGATIVE_INFINITY));
		Assert.equals("null", Std.string(null));
	}

	@:describe("Haxe Float special values")
	@:test
	function testFloatSpecialValuesReflectAsFloats():Void {
		Assert.isTrue(Std.isOfType(Math.NaN, Float));
		Assert.isTrue(Std.isOfType(Math.POSITIVE_INFINITY, Float));
		Assert.equals(Type.ValueType.TFloat, Type.typeof(Math.NaN));
		Assert.equals(Type.ValueType.TFloat, Type.typeof(Math.POSITIVE_INFINITY));
	}

	@:describe("Haxe Float special values")
	@:test
	function testParseFloatInvalidInputReturnsNaN():Void {
		Assert.isTrue(Math.isNaN(Std.parseFloat("not-a-number")));
		Assert.equals(12.5, Std.parseFloat("  12.5px"));
		Assert.equals(7.0, Std.parseFloat("7"));
		Assert.equals(0.5, Std.parseFloat(".5x"));
		Assert.equals(Math.POSITIVE_INFINITY, Std.parseFloat("1e999"));
		Assert.equals(Math.NEGATIVE_INFINITY, Std.parseFloat("-1e999"));
		Assert.isTrue(Math.isNaN(Std.parseFloat("NaN")));
		Assert.isTrue(Math.isNaN(Std.parseFloat("Infinity")));
	}

	@:describe("Haxe Float special values")
	@:test
	function testFloatCatchAcceptsSpecialSentinel():Void {
		try {
			throwPortableNan();
			Assert.fail("throwPortableNan should throw");
		} catch (value:Float) {
			Assert.isTrue(Math.isNaN(value));
		}
	}

	@:describe("Haxe Float special values")
	@:test
	function testFloatSpecialArithmeticAndComparison():Void {
		Assert.isTrue(Math.isNaN(Math.POSITIVE_INFINITY + Math.NEGATIVE_INFINITY));
		Assert.isTrue(Math.isNaN(Math.POSITIVE_INFINITY * 0.0));
		Assert.isTrue(Math.isNaN(0.0 / 0.0));

		Assert.equals("Infinity", Std.string(Math.POSITIVE_INFINITY + 1.0));
		Assert.equals("-Infinity", Std.string(Math.NEGATIVE_INFINITY - 1.0));
		Assert.equals("Infinity", Std.string(1.0 / 0.0));
		Assert.equals("Infinity", Std.string(-Math.NEGATIVE_INFINITY));

		Assert.isFalse(Math.NaN == Math.NaN);
		Assert.isTrue(Math.NaN != Math.NaN);
		Assert.isTrue(Math.NEGATIVE_INFINITY < -1.0);
		Assert.isTrue(Math.POSITIVE_INFINITY > 1.0);
		Assert.isFalse(Math.NaN < 1.0);
	}

	@:describe("Haxe Float special values")
	@:test
	function testFloatSpecialDynamicEqualityUsesHaxeSemantics():Void {
		// Dynamic is intentional here: portable Haxe can hide NaN behind Dynamic values.
		var value:Dynamic = Math.NaN;
		Assert.isFalse(value == value);
		Assert.isTrue(value != value);
	}

	@:describe("Haxe Float special values")
	@:test
	function testFloatSpecialStringConcatAndMutationOperators():Void {
		Assert.equals("special=Infinity", "special=" + Math.POSITIVE_INFINITY);

		var value:Float = Math.POSITIVE_INFINITY;
		value += 1.0;
		Assert.equals("Infinity", Std.string(value));

		var counter:Float = 1.0;
		var oldCounter = counter++;
		Assert.equals(1.0, oldCounter);
		Assert.equals(2.0, counter);

		var newCounter = ++counter;
		Assert.equals(3.0, newCounter);
		Assert.equals(3.0, counter);
	}

	@:describe("Haxe local mutation operators")
	@:test
	function testLocalIncrementInAssertionArgumentsRebindsOuterVariable():Void {
		var counter = 0;

		Assert.equals(0, counter++);
		Assert.equals(1, counter);
		Assert.equals(2, ++counter);
		Assert.equals(2, counter);
	}

	@:describe("Haxe local mutation operators")
	@:test
	function testLocalIncrementInValueExpressionsPreservesOrdering():Void {
		var counter = 0;

		Assert.equals(1, counter++ + counter++);
		Assert.equals(2, counter);
		Assert.equals("2:3", pairIntInt(counter++, counter));
		Assert.equals(3, counter);
	}

	@:describe("Haxe Float special values")
	@:test
	function testFloatSpecialBytesExactIeeeEncoding():Void {
		var doubleBytes = Bytes.alloc(8);
		doubleBytes.setDouble(0, Math.POSITIVE_INFINITY);
		Assert.equals("000000000000f07f", doubleBytes.toHex());
		Assert.equals(Math.POSITIVE_INFINITY, doubleBytes.getDouble(0));

		doubleBytes.setDouble(0, Math.NEGATIVE_INFINITY);
		Assert.equals("000000000000f0ff", doubleBytes.toHex());
		Assert.equals(Math.NEGATIVE_INFINITY, doubleBytes.getDouble(0));

		doubleBytes.setDouble(0, Math.NaN);
		Assert.equals("000000000000f87f", doubleBytes.toHex());
		Assert.isTrue(Math.isNaN(doubleBytes.getDouble(0)));

		doubleBytes.setDouble(0, 1.7976931348623157e308);
		Assert.equals("ffffffffffffef7f", doubleBytes.toHex());
		Assert.isTrue(Math.isFinite(doubleBytes.getDouble(0)));

		var negativeZero = Bytes.ofHex("0000000000000080").getDouble(0);
		doubleBytes.setDouble(0, negativeZero);
		Assert.equals("0000000000000080", doubleBytes.toHex());

		var alternateNaN = Bytes.ofHex("010000000000f87f");
		Assert.isTrue(Math.isNaN(alternateNaN.getDouble(0)));

		var floatBytes = Bytes.alloc(4);
		floatBytes.setFloat(0, Math.POSITIVE_INFINITY);
		Assert.equals("0000807f", floatBytes.toHex());
		Assert.equals(Math.POSITIVE_INFINITY, floatBytes.getFloat(0));

		floatBytes.setFloat(0, Math.NEGATIVE_INFINITY);
		Assert.equals("000080ff", floatBytes.toHex());
		Assert.equals(Math.NEGATIVE_INFINITY, floatBytes.getFloat(0));

		floatBytes.setFloat(0, Math.NaN);
		Assert.equals("0000c07f", floatBytes.toHex());
		Assert.isTrue(Math.isNaN(floatBytes.getFloat(0)));

		floatBytes.setFloat(0, 3.4028234663852886e38);
		Assert.equals("ffff7f7f", floatBytes.toHex());
		Assert.isTrue(Math.isFinite(floatBytes.getFloat(0)));

		var negativeZero32 = Bytes.ofHex("00000080").getFloat(0);
		floatBytes.setFloat(0, negativeZero32);
		Assert.equals("00000080", floatBytes.toHex());

		var alternateNaN32 = Bytes.ofHex("0100c07f");
		Assert.isTrue(Math.isNaN(alternateNaN32.getFloat(0)));
	}

	@:describe("Haxe Float special values")
	@:test
	function testFloatSpecialBytesBufferAndStreamsUseIeeeEncoding():Void {
		var buffer = new BytesBuffer();
		buffer.addFloat(Math.POSITIVE_INFINITY);
		buffer.addFloat(Math.NaN);
		buffer.addDouble(Math.NEGATIVE_INFINITY);
		buffer.addDouble(Math.NaN);
		var bytes = buffer.getBytes();
		Assert.equals("0000807f0000c07f000000000000f0ff000000000000f87f", bytes.toHex());
		Assert.equals(Math.POSITIVE_INFINITY, bytes.getFloat(0));
		Assert.isTrue(Math.isNaN(bytes.getFloat(4)));
		Assert.equals(Math.NEGATIVE_INFINITY, bytes.getDouble(8));
		Assert.isTrue(Math.isNaN(bytes.getDouble(16)));

		var output = new BytesOutput();
		output.writeFloat(Math.POSITIVE_INFINITY);
		output.writeDouble(Math.NEGATIVE_INFINITY);
		var streamBytes = output.getBytes();
		Assert.equals("0000807f000000000000f0ff", streamBytes.toHex());

		var input = new BytesInput(streamBytes);
		Assert.equals(Math.POSITIVE_INFINITY, input.readFloat());
		Assert.equals(Math.NEGATIVE_INFINITY, input.readDouble());
	}

	@:describe("Haxe Float special values")
	@:test
	function testFpHelperUsesHaxeFloatIeeeSemantics():Void {
		Assert.equals(2139095040, FPHelper.floatToI32(Math.POSITIVE_INFINITY));
		Assert.equals(-8388608, FPHelper.floatToI32(Math.NEGATIVE_INFINITY));
		Assert.equals(2143289344, FPHelper.floatToI32(Math.NaN));

		Assert.equals(Math.POSITIVE_INFINITY, FPHelper.i32ToFloat(2139095040));
		Assert.equals(Math.NEGATIVE_INFINITY, FPHelper.i32ToFloat(-8388608));
		Assert.isTrue(Math.isNaN(FPHelper.i32ToFloat(2143289345)));

		Assert.equals("9218868437227405312", Int64.toStr(FPHelper.doubleToI64(Math.POSITIVE_INFINITY)));
		Assert.equals("-4503599627370496", Int64.toStr(FPHelper.doubleToI64(Math.NEGATIVE_INFINITY)));
		Assert.equals("9221120237041090560", Int64.toStr(FPHelper.doubleToI64(Math.NaN)));

		Assert.equals(Math.POSITIVE_INFINITY, FPHelper.i64ToDouble(0, 2146435072));
		Assert.equals(Math.NEGATIVE_INFINITY, FPHelper.i64ToDouble(0, -1048576));
		Assert.isTrue(Math.isNaN(FPHelper.i64ToDouble(1, 2146959360)));
	}

	@:describe("Haxe Float special values")
	@:test
	function testFloatSpecialJsonSerializationUsesNull():Void {
		Assert.equals("null", Json.stringify(Math.NaN));
		Assert.equals("null", Json.stringify(Math.POSITIVE_INFINITY));
		Assert.equals("[null,null,1.5]", Json.stringify([Math.NaN, Math.NEGATIVE_INFINITY, 1.5]));

		var replaced = Json.stringify({value: 1}, function(key, value) {
			return key == "value" ? Math.POSITIVE_INFINITY : value;
		});
		Assert.equals('{"value":null}', replaced);
	}

	@:describe("Haxe Float special values")
	@:test
	function testFloatSpecialSerializerUsesHaxeWireTags():Void {
		Assert.equals("k", Serializer.run(Math.NaN));
		Assert.equals("p", Serializer.run(Math.POSITIVE_INFINITY));
		Assert.equals("m", Serializer.run(Math.NEGATIVE_INFINITY));
		Assert.equals("akpmh", Serializer.run([Math.NaN, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY]));

		Assert.isTrue(Math.isNaN(Unserializer.run("k")));
		Assert.equals(Math.POSITIVE_INFINITY, Unserializer.run("p"));
		Assert.equals(Math.NEGATIVE_INFINITY, Unserializer.run("m"));

		var values:Array<Dynamic> = Unserializer.run("akpmh");
		var firstValue:Dynamic = untyped __elixir__("Enum.at({0}, 0)", values);
		var secondValue:Dynamic = untyped __elixir__("Enum.at({0}, 1)", values);
		var thirdValue:Dynamic = untyped __elixir__("Enum.at({0}, 2)", values);
		Assert.isTrue(Math.isNaN(firstValue));
		Assert.equals(Math.POSITIVE_INFINITY, secondValue);
		Assert.equals(Math.NEGATIVE_INFINITY, thirdValue);
	}

	@:describe("Haxe Float special values")
	@:test
	function testFloatSpecialTemplateRendering():Void {
		var fromContext = new Template("nan=::nan:: inf=::inf:: ninf=::ninf::");
		Assert.equals("nan=NaN inf=Infinity ninf=-Infinity", fromContext.execute({
			nan: Math.NaN,
			inf: Math.POSITIVE_INFINITY,
			ninf: Math.NEGATIVE_INFINITY
		}));

		var fromExpression = new Template("small=::.5:: big=::1e999:: int=::7:: missing=::missing::");
		Assert.equals("small=0.5 big=Infinity int=7 missing=null", fromExpression.execute({}));
	}

	@:describe("Haxe Float special values")
	@:test
	function testNativeElixirMathBoundaryRejectsHaxeSpecialsClearly():Void {
		Assert.equals(4.0, ErlangMath.sqrt(16.0));

		try {
			var rejected = ErlangMath.sqrt(Math.POSITIVE_INFINITY);
			Assert.equals(0.0, rejected);
			Assert.fail("ErlangMath.sqrt should reject Haxe Float Infinity");
		} catch (error:Dynamic) {
			Assert.containsString(Std.string(error), "expected finite native Elixir number");
			Assert.containsString(Std.string(error), ":math.sqrt/1");
			Assert.containsString(Std.string(error), "Infinity");
		}
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

	@:describe("haxe.exceptions upstream fallback")
	@:test
	function testArgumentAndNotImplementedExceptionFallback():Void {
		var previous = new haxe.Exception("previous-cause");

		var argument = new ArgumentException("limit", null, previous);
		Assert.equals("limit", argument.argument);
		Assert.equals('Invalid argument "limit"', argument.message);
		Assert.equals("previous-cause", argument.previous.message);
		Assert.containsString(argument.toString(), 'Invalid argument "limit" in stdlib_parity.StdlibParityTest.testArgumentAndNotImplementedExceptionFallback');

		var customArgument = new ArgumentException("path", "Bad path");
		Assert.equals("Bad path", customArgument.message);
		Assert.isNull(customArgument.previous);

		var notImplementedDefault = new NotImplementedException();
		Assert.equals("Not implemented", notImplementedDefault.message);
		Assert.containsString(notImplementedDefault.toString(),
			"Not implemented in stdlib_parity.StdlibParityTest.testArgumentAndNotImplementedExceptionFallback");
		Assert.isNull(notImplementedDefault.previous);

		var notImplementedCustom = new NotImplementedException("Missing BEAM hook", previous);
		Assert.equals("Missing BEAM hook", notImplementedCustom.message);
		Assert.equals("previous-cause", notImplementedCustom.previous.message);
	}

	@:describe("haxe.exceptions upstream fallback")
	@:test
	function testArgumentAndNotImplementedExceptionThrowCatch():Void {
		try {
			throw new ArgumentException("name");
			Assert.fail("ArgumentException should be catchable by its concrete type");
		} catch (error:ArgumentException) {
			Assert.equals("name", error.argument);
			Assert.equals('Invalid argument "name"', error.message);
		}

		try {
			throw new NotImplementedException("not yet");
			Assert.fail("NotImplementedException should be catchable by its concrete type");
		} catch (error:NotImplementedException) {
			Assert.equals("not yet", error.message);
		}
	}

	@:describe("haxe.ds.ArraySort target override")
	@:test
	function testArraySortStableTargetOverride():Void {
		var values = [
			new SortNode(2, "two-a"),
			new SortNode(1, "one-a"),
			new SortNode(2, "two-b"),
			new SortNode(1, "one-b"),
			new SortNode(3, "three")
		];

		ArraySort.sort(values, function(left, right) {
			return left.key - right.key;
		});

		Assert.equals("one-a", values[0].label);
		Assert.equals("one-b", values[1].label);
		Assert.equals("two-a", values[2].label);
		Assert.equals("two-b", values[3].label);
		Assert.equals("three", values[4].label);
	}

	@:describe("haxe.ds.GenericStack target override")
	@:test
	function testGenericStackIteratorToStringAndReceiverRebinding():Void {
		var stack = new GenericStack<String>();
		stack.add("one");
		stack.add("two");
		stack.add("three");

		var seen:Array<String> = [];
		for (value in stack) {
			seen.push(value);
		}

		Assert.equals(3, arrayLength(seen));
		Assert.equals("three", seen[0]);
		Assert.equals("two", seen[1]);
		Assert.equals("one", seen[2]);
		Assert.equals("{three,two,one}", stack.toString());

		Assert.isTrue(stack.remove("two"));
		Assert.equals("{three,one}", stack.toString());
		Assert.equals("three", stack.pop());
		Assert.equals("{one}", stack.toString());
		Assert.equals("one", stack.pop());
		Assert.isTrue(stack.isEmpty());
		Assert.isFalse(stack.remove("missing"));
		Assert.equals("{}", stack.toString());
	}

	@:describe("haxe.ds.List target override")
	@:test
	function testListMutationIterationFilterAndMap():Void {
		var values = new List<String>();
		Assert.isTrue(values.isEmpty());
		Assert.equals(0, values.length);
		Assert.isNull(values.first());
		Assert.isNull(values.last());
		Assert.isNull(values.pop());

		values.add("one");
		values.add("two");
		values.push("zero");

		Assert.equals(3, values.length);
		Assert.equals("zero", values.first());
		Assert.equals("two", values.last());
		Assert.equals("{zero, one, two}", values.toString());
		Assert.equals("zero|one|two", values.join("|"));

		var seen:Array<String> = [];
		var iterator = values.iterator();
		while (iterator.hasNext()) {
			seen.push(iterator.next());
		}
		Assert.equals("zero,one,two", seen.join(","));

		var entries:Array<String> = [];
		var kvi = values.keyValueIterator();
		while (kvi.hasNext()) {
			var entry = kvi.next();
			entries.push(entry.key + ":" + entry.value);
		}
		Assert.equals("0:zero,1:one,2:two", entries.join(","));

		Assert.isTrue(values.remove("one"));
		Assert.isFalse(values.remove("missing"));
		Assert.equals("{zero, two}", values.toString());
		Assert.equals("zero", values.pop());
		Assert.equals("{two}", values.toString());

		values.clear();
		Assert.isTrue(values.isEmpty());
		Assert.equals(0, values.length);

		var numbers = new List<Int>();
		numbers.add(1);
		numbers.add(2);
		numbers.add(3);

		var filtered = numbers.filter(function(value) return value > 1);
		Assert.equals("{2, 3}", filtered.toString());
		Assert.equals("{1, 2, 3}", numbers.toString());

		var mapped = numbers.map(function(value) return value * 10);
		Assert.equals("{10, 20, 30}", mapped.toString());
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

	@:describe("IntIterator persistent receiver semantics")
	@:test
	function testIntIteratorDirectNextSequence():Void {
		var iterator = new IntIterator(0, 2);
		Assert.isTrue(iterator.hasNext());
		Assert.equals(0, iterator.next());
		Assert.isTrue(iterator.hasNext());
		Assert.equals(1, iterator.next());
		Assert.isFalse(iterator.hasNext());
	}

	@:describe("IntIterator persistent receiver semantics")
	@:test
	function testIntIteratorEmbeddedAssertions():Void {
		var iterator = new IntIterator(0, 2);
		Assert.isTrue(iterator.next() == 0);
		Assert.isTrue(iterator.hasNext());
		Assert.isTrue(iterator.next() == 1);
		Assert.isFalse(iterator.hasNext());
	}

	@:describe("IntIterator persistent receiver semantics")
	@:test
	function testIntIteratorRepeatedCallsPreserveOrder():Void {
		var iterator = new IntIterator(0, 3);
		Assert.equals(1, iterator.next() + iterator.next());
		Assert.equals(2, iterator.next());
		Assert.isFalse(iterator.hasNext());
	}

	@:describe("IntIterator persistent receiver semantics")
	@:test
	function testIntIteratorFunctionArgumentOrdering():Void {
		var iterator = new IntIterator(0, 2);
		Assert.equals("0:true", pairIntBool(iterator.next(), iterator.hasNext()));
		Assert.equals("1:false", pairIntBool(iterator.next(), iterator.hasNext()));
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

	@:describe("haxe.iterators.StringIterator")
	@:test
	function testStringIteratorIteratesCodepoints():Void {
		var iterator = new StringIterator("aé中");
		var codes:Array<Int> = [];
		while (iterator.hasNext()) {
			codes.push(iterator.next());
		}

		Assert.equals(3, codes.length);
		Assert.equals(97, codes[0]);
		Assert.equals(233, codes[1]);
		Assert.equals(0x4E2D, codes[2]);
		Assert.isFalse(iterator.hasNext());
	}

	@:describe("haxe.iterators.StringKeyValueIterator")
	@:test
	function testStringKeyValueIteratorUsesCharacterIndices():Void {
		var iterator = new StringKeyValueIterator("aé中");
		var entries:Array<String> = [];
		while (iterator.hasNext()) {
			var entry = iterator.next();
			entries.push(entry.key + ":" + entry.value);
		}

		Assert.equals(3, entries.length);
		Assert.equals("0:97", entries[0]);
		Assert.equals("1:233", entries[1]);
		Assert.equals("2:20013", entries[2]);
		Assert.isFalse(iterator.hasNext());
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

	@:describe("haxe.io.Error")
	@:test
	function testIoErrorCustomCanBeCaughtAndMatched():Void {
		try {
			throw Error.Custom("unsupported target IO operation");
		} catch (error:Error) {
			switch (error) {
				case Custom(message):
					Assert.equals("unsupported target IO operation", message);
				default:
					Assert.fail("Expected Error.Custom to survive BEAM throw/catch lowering");
			}
		}
	}

	@:describe("haxe.io.BytesBuffer")
	@:test
	function testBytesBufferNoOpMutationsKeepReceiver():Void {
		var buffer = new BytesBuffer();
		buffer.add(Bytes.ofString(""));
		Assert.equals(0, buffer.length);

		buffer.addString("ok");
		buffer.addBytes(Bytes.ofString("ignored"), 0, 0);
		Assert.equals(2, buffer.length);
		Assert.equals("ok", buffer.getBytes().toString());
	}

	@:describe("haxe.io.StringInput")
	@:test
	function testStringInputReadAllReadLineAndEof():Void {
		var allInput = new StringInput("hello");
		Assert.equals("hello", allInput.readAll(2).toString());

		var lineInput = new StringInput("red\r\nblue\n");
		Assert.equals("red", lineInput.readLine());
		Assert.equals("blue", lineInput.readLine());

		Assert.raises(() -> {
			lineInput.readByte();
		});
	}

	@:describe("haxe.io.Path")
	@:test
	function testPathParsingAndNormalization():Void {
		var parsed = new Path("/tmp/archive.tar.gz");
		Assert.equals("/tmp", parsed.dir);
		Assert.equals("archive.tar", parsed.file);
		Assert.equals("gz", parsed.ext);
		Assert.equals("/tmp/archive.tar.gz", parsed.toString());

		Assert.equals("/tmp/file", Path.withoutExtension("/tmp/file.txt"));
		Assert.equals("file.txt", Path.withoutDirectory("/tmp/file.txt"));
		Assert.equals("/tmp", Path.directory("/tmp/file.txt"));
		Assert.equals("txt", Path.extension("/tmp/file.txt"));
		Assert.equals("/tmp/file.log", Path.withExtension("/tmp/file", "log"));
		Assert.equals("/usr/bin", Path.join(["/usr", "local", "../bin"]));
		Assert.equals("/usr/bin/tool", Path.normalize("/usr//local/../bin/./tool"));
		Assert.equals("foo\\bar\\", Path.addTrailingSlash("foo\\bar"));
		Assert.equals("foo", Path.removeTrailingSlashes("foo///"));
		Assert.isTrue(Path.isAbsolute("/tmp"));
		Assert.isTrue(Path.isAbsolute("C:/tmp"));
		Assert.isTrue(Path.isAbsolute("\\\\server\\share"));
		Assert.isFalse(Path.isAbsolute("relative/path"));
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

	@:describe("haxe.ds.HashMap target override")
	@:test
	function testHashMapHashCodeKeyedOpsAndIterators():Void {
		var alpha = new HashKey(1, "alpha", 10);
		var beta = new HashKey(2, "beta", 20);
		var betaReplacement = new HashKey(3, "beta-replacement", 20);
		var missing = new HashKey(4, "missing", 40);

		var map = new HashMap<HashKey, String>();
		Assert.isFalse(map.exists(alpha));
		Assert.isNull(map.get(alpha));

		map.set(alpha, "one");
		map.set(beta, "two");
		Assert.isTrue(map.exists(alpha));
		Assert.equals("one", map.get(alpha));
		Assert.equals("two", map.get(beta));

		map.set(betaReplacement, "twenty");
		Assert.equals("twenty", map.get(beta));
		Assert.equals("twenty", map.get(betaReplacement));

		var keys:Array<String> = [];
		for (key in map.keys()) {
			keys.push(key.label);
		}
		Assert.equals(2, keys.length);
		Assert.contains(keys, "alpha");
		Assert.contains(keys, "beta-replacement");

		var values:Array<String> = [];
		for (value in map.iterator()) {
			values.push(value);
		}
		Assert.equals(2, values.length);
		Assert.contains(values, "one");
		Assert.contains(values, "twenty");

		var pairs:Array<String> = [];
		for (pair in map.keyValueIterator()) {
			pairs.push(pair.key.label + ":" + pair.value);
		}
		Assert.equals(2, pairs.length);
		Assert.contains(pairs, "alpha:one");
		Assert.contains(pairs, "beta-replacement:twenty");

		var explicitPairs:Array<String> = [];
		var explicitIterator = new HashMapKeyValueIterator<HashKey, String>(map);
		while (explicitIterator.hasNext()) {
			var explicitPair = explicitIterator.next();
			explicitPairs.push(explicitPair.key.label + ":" + explicitPair.value);
		}
		Assert.equals(2, explicitPairs.length);
		Assert.contains(explicitPairs, "alpha:one");
		Assert.contains(explicitPairs, "beta-replacement:twenty");

		var snapshot = map.copy();
		Assert.isTrue(map.remove(alpha));
		Assert.isFalse(map.exists(alpha));
		Assert.isFalse(map.remove(missing));
		Assert.equals("one", snapshot.get(alpha));
		Assert.equals("twenty", snapshot.get(beta));

		var printed = map.toString();
		Assert.containsString(printed, "beta-replacement");
		Assert.containsString(printed, "twenty");

		map.clear();
		Assert.isFalse(map.exists(beta));
		Assert.equals("{}", map.toString());
		Assert.equals("twenty", snapshot.get(beta));
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

		var withoutB = Reflect.deleteField(obj, "b");
		Assert.isFalse(Reflect.hasField(withoutB, "b"));
	}

	@:describe("haxe.format.JsonParser")
	@:test
	function testJsonParserUsesNativeDecodeTerms():Void {
		var obj:Dynamic = JsonParser.parse("{\"name\":\"Ada\",\"count\":3,\"items\":[1,true,null],\"escaped\":\"line\\nnext\"}");

		Assert.equals("Ada", cast Reflect.field(obj, "name"));
		Assert.equals(3, cast Reflect.field(obj, "count"));
		Assert.equals("line\nnext", cast Reflect.field(obj, "escaped"));

		var items:Array<Dynamic> = cast Reflect.field(obj, "items");
		var firstItem:Dynamic = untyped __elixir__("Enum.at({0}, 0)", items);
		var secondItem:Dynamic = untyped __elixir__("Enum.at({0}, 1)", items);
		var thirdItem:Dynamic = untyped __elixir__("Enum.at({0}, 2)", items);
		Assert.equals(3, arrayLength(items));
		Assert.equals(1, firstItem);
		Assert.equals(true, secondItem);
		Assert.isNull(thirdItem);

		var topLevelString:String = cast JsonParser.parse("\"ok\"");
		Assert.equals("ok", topLevelString);
		Assert.isNull(JsonParser.parse("null"));
	}

	@:describe("haxe.format.JsonParser")
	@:test
	function testJsonParserRaisesOnInvalidJson():Void {
		try {
			JsonParser.parse("{\"unterminated\":");
			Assert.fail("JsonParser.parse should raise for invalid JSON");
		} catch (error:Dynamic) {
			Assert.isNotNull(error);
		}
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

		var withoutBar = Reflect.deleteField(obj, "bar");
		Assert.isFalse(Reflect.hasField(withoutBar, "bar"));

		var fields = Reflect.fields(obj);
		Assert.contains(fields, "foo");
		Assert.contains(fields, "baz");
	}

	@:describe("Reflect.compare")
	@:test
	function testReflectCompareUsesNumericOrdering():Void {
		Assert.isTrue(Reflect.compare(99, 101) < 0);
		Assert.isTrue(Reflect.compare(101, 99) > 0);
		Assert.equals(0, Reflect.compare(42, 42));
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

	@:describe("haxe.Timer")
	@:test
	function testTimerStampMeasureAndManualRunRebinding():Void {
		var timer = new Timer(1000);
		timer.run = function() {
			Thread.current().sendMessage("timer-manual-1");
		};
		timer.run();
		Assert.equals("timer-manual-1", Thread.readMessage(false));

		var runRef = timer.run;
		runRef();
		Assert.equals("timer-manual-1", Thread.readMessage(false));

		timer.run = function() {
			Thread.current().sendMessage("timer-manual-2");
		};
		timer.run();
		Assert.equals("timer-manual-2", Thread.readMessage(false));
		timer.stop();

		var startedAt = Timer.stamp();
		Sys.sleep(0.001);
		Assert.isTrue(Timer.stamp() >= startedAt);
		Assert.equals("timer-result", Timer.measure(function() return "timer-result"));
	}

	@:describe("haxe.Timer")
	@:test
	function testTimerDelayAndRepeatUseEventLoop():Void {
		var repeated = new Timer(1);
		repeated.run = function() {
			Thread.current().sendMessage("timer-repeat");
		};
		progressCurrentThreadEvents();
		Assert.equals("timer-repeat", Thread.readMessage(false));
		progressCurrentThreadEvents();
		Assert.equals("timer-repeat", Thread.readMessage(false));
		repeated.stop();

		Timer.delay(function() {
			Thread.current().sendMessage("timer-delay");
		}, 1);
		progressCurrentThreadEvents();
		Assert.equals("timer-delay", Thread.readMessage(false));
	}

	@:describe("haxe.crypto.Md5")
	@:test
	function testMd5EncodeLowerHex():Void {
		Assert.equals("098f6bcd4621d373cade4e832627b4f6", Md5.encode("test"));
	}

	@:describe("haxe.crypto.Hmac")
	@:test
	function testHmacMakeUsesNativeDigestAlgorithms():Void {
		var empty = Bytes.ofString("");
		Assert.equals("74e6f7298a9c2d168935f58c001bad88", new Hmac(MD5).make(empty, empty).toHex());
		Assert.equals("fbdb1d1b18aa6c08324b7d64b71fb76370690e1d", new Hmac(SHA1).make(empty, empty).toHex());
		Assert.equals("b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad", new Hmac(SHA256).make(empty, empty).toHex());

		var key = Bytes.ofString("key");
		var message = Bytes.ofString("The quick brown fox jumps over the lazy dog");
		Assert.equals("80070713463e7749b90c2dc24911e275", new Hmac(MD5).make(key, message).toHex());
		Assert.equals("de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9", new Hmac(SHA1).make(key, message).toHex());
		Assert.equals("f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8", new Hmac(SHA256).make(key, message).toHex());
	}

	@:describe("haxe.crypto.BaseCode")
	@:test
	function testBaseCodeArbitraryPowerOfTwoDictionaries():Void {
		var hex = new BaseCode(Bytes.ofString("0123456789abcdef"));
		var binary = Bytes.ofHex("00ff10");
		var encodedHex = hex.encodeBytes(binary);
		Assert.equals("00ff10", encodedHex.toString());
		Assert.equals("00ff10", hex.decodeBytes(Bytes.ofString("00ff10")).toHex());

		Assert.equals("01000001", BaseCode.encode("A", "01"));
		Assert.equals("A", BaseCode.decode("01000001", "01"));

		try {
			new BaseCode(Bytes.ofString("abc"));
			Assert.fail("BaseCode should reject non-power-of-two dictionaries");
		} catch (error:Dynamic) {
			Assert.equals("BaseCode : base length must be a power of two.", Std.string(error));
		}

		try {
			hex.decodeBytes(Bytes.ofString("0g"));
			Assert.fail("BaseCode should reject characters outside the dictionary");
		} catch (error:Dynamic) {
			Assert.equals("BaseCode : invalid encoded char", Std.string(error));
		}
	}

	@:describe("haxe.crypto.Base64")
	@:test
	function testBase64StandardAndUrlSafe():Void {
		var hello = Bytes.ofString("hello");
		Assert.equals("aGVsbG8=", Base64.encode(hello));
		Assert.equals("aGVsbG8", Base64.encode(hello, false));
		Assert.equals("hello", Base64.decode("aGVsbG8=").toString());
		Assert.equals("hello", Base64.decode("aGVsbG8", false).toString());

		var url = Bytes.ofString("fo?");
		Assert.equals("Zm8_", Base64.urlEncode(url));
		Assert.equals("fo?", Base64.urlDecode("Zm8_").toString());

		var shortUrl = Bytes.ofString("fo");
		Assert.equals("Zm8=", Base64.urlEncode(shortUrl, true));
		Assert.equals("fo", Base64.urlDecode("Zm8=", true).toString());

		var binary = Bytes.alloc(3);
		binary.set(0, 0xFB);
		binary.set(1, 0xFF);
		binary.set(2, 0x00);
		Assert.equals("+/8A", Base64.encode(binary));
		Assert.equals("-_8A", Base64.urlEncode(binary));
	}

	@:describe("haxe.crypto.Crc32")
	@:test
	function testCrc32StaticAndIncrementalSignedIntSemantics():Void {
		Assert.equals(0, Crc32.make(Bytes.ofString("")));
		Assert.equals(891568578, Crc32.make(Bytes.ofString("abc")));

		var c = new Crc32();
		var prefix = Bytes.ofString("ab");
		c.update(prefix, 0, prefix.length);
		c.byte("c".code);
		Assert.equals(891568578, c.get());

		c.update(Bytes.ofString("ignored"), 0, 0);
		Assert.equals(891568578, c.get());

		var highBit = Bytes.alloc(1);
		highBit.set(0, 0);
		Assert.equals(-771559539, Crc32.make(highBit));
	}

	@:describe("haxe.crypto.Adler32")
	@:test
	function testAdler32StaticIncrementalReadAndSignedIntSemantics():Void {
		Assert.equals(1, Adler32.make(Bytes.ofString("")));
		Assert.equals(38600999, Adler32.make(Bytes.ofString("abc")));

		var a = new Adler32();
		var prefix = Bytes.ofString("ab");
		a.update(prefix, 0, prefix.length);
		var suffix = Bytes.ofString("c");
		a.update(suffix, 0, suffix.length);
		Assert.equals(38600999, a.get());
		Assert.equals("0000024D00000127", a.toString());

		a.update(Bytes.ofString("ignored"), 0, 0);
		Assert.equals(38600999, a.get());

		var read = Adler32.read(new BytesInput(Bytes.ofHex("024d0127")));
		Assert.equals(a.get(), read.get());
		Assert.isTrue(read.equals(a));

		var highBit = Bytes.alloc(16);
		for (i in 0...highBit.length)
			highBit.set(i, 255);
		Assert.equals(-2021126159, Adler32.make(highBit));
	}

	@:describe("haxe.crypto.Sha1")
	@:test
	function testSha1EncodeAndMake():Void {
		Assert.equals("a9993e364706816aba3e25717850c26c9cd0d89d", Sha1.encode("abc"));
		Assert.equals("da39a3ee5e6b4b0d3255bfef95601890afd80709", Sha1.encode(""));
		Assert.equals("a9993e364706816aba3e25717850c26c9cd0d89d", Sha1.make(Bytes.ofString("abc")).toHex());

		var binary = Bytes.alloc(3);
		binary.set(0, 0x00);
		binary.set(1, 0xFF);
		binary.set(2, 0x10);
		Assert.equals("a14c2fba17201c1ead45b6c4af4409fbfc16ba8a", Sha1.make(binary).toHex());
	}

	@:describe("haxe.crypto.Sha256")
	@:test
	function testSha256EncodeAndMake():Void {
		Assert.equals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", Sha256.encode("abc"));
		Assert.equals("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", Sha256.encode(""));
		Assert.equals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", Sha256.make(Bytes.ofString("abc")).toHex());

		var binary = Bytes.alloc(3);
		binary.set(0, 0x00);
		binary.set(1, 0xFF);
		binary.set(2, 0x10);
		Assert.equals("2da45f2cd1f9c8e69a67abf7a6b26c282533d0a7686787a9533265418680d4d2", Sha256.make(binary).toHex());
	}

	@:describe("haxe.crypto.Sha224")
	@:test
	function testSha224EncodeAndMake():Void {
		Assert.equals("23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7", Sha224.encode("abc"));
		Assert.equals("d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f", Sha224.encode(""));
		Assert.equals("23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7", Sha224.make(Bytes.ofString("abc")).toHex());

		var binary = Bytes.alloc(3);
		binary.set(0, 0x00);
		binary.set(1, 0xFF);
		binary.set(2, 0x10);
		Assert.equals("fb00d9d04bdeeb4c51a031ab62ad806c6b8d293efafb8456deae0320", Sha224.make(binary).toHex());
	}
}
