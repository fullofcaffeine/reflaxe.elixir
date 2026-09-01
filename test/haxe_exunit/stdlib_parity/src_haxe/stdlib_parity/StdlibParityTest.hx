package stdlib_parity;

import haxe.Int32;
import haxe.Int64;
import haxe.CallStack;
import haxe.NativeStackTrace;
import haxe.PosInfos;
import haxe.DynamicAccess;
import haxe.EnumFlags;
import haxe.EnumTools.EnumValueTools;
import haxe.Json;
import haxe.Serializer;
import haxe.Template;
import haxe.Timer;
import haxe.Utf8;
import haxe.Ucs2;
import haxe.Unserializer;
import haxe.ValueException;
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
import haxe.ds.Either;
import haxe.ds.EnumValueMap;
import haxe.ds.GenericStack;
import haxe.ds.HashMap;
import haxe.ds.IntMap;
import haxe.ds.List;
import haxe.ds.Option;
import haxe.ds.OptionTools;
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
import haxe.io.Mime;
import haxe.io.Path;
import haxe.io.Scheme;
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

enum ParityTone {
	Warm(label:String, intensity:Int);
	Cool(label:String);
	Neutral;
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

class ConstraintConstructibleValue {
	public final marker:Int;

	public function new() {
		marker = 17;
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

	static function capturePosition(?position:PosInfos):PosInfos {
		return position;
	}

	static function arrayLength<T>(values:Array<T>):Int {
		return untyped __elixir__('length({0})', values);
	}

	static function pairToString<K, V>(pair:{key:K, value:V}):String {
		var keyString:String = cast untyped __elixir__('Kernel.to_string({0})', pair.key);
		var valueString:String = cast untyped __elixir__('Kernel.to_string({0})', pair.value);
		return keyString + ":" + valueString;
	}

	static function describeStringIntEither(either:Either<String, Int>):String {
		return switch (either) {
			case Left(value): "left:" + value;
			case Right(value): "right:" + value;
		};
	}

	static function describePayloadEither(either:Either<{key:String, value:Int}, Array<String>>):String {
		return switch (either) {
			case Left(value): value.key + ":" + value.value;
			case Right(values): values.join(",");
		};
	}

	static function describeStringOption(option:Option<String>):String {
		return switch (option) {
			case Some(value): "some:" + value;
			case None: "none";
		};
	}

	static function describePayloadOption(option:Option<{key:String, value:Int}>):String {
		return switch (option) {
			case Some(value): value.key + ":" + value.value;
			case None: "none";
		};
	}

	static function describeIntArrayOption(option:Option<Array<Int>>):String {
		return switch (option) {
			case Some(values): "some:" + values.join(",");
			case None: "none";
		};
	}

	static function describeIntResult(result:haxe.functional.Result<Int, String>):String {
		return switch (result) {
			case Ok(value): "ok:" + value;
			case Error(message): "error:" + message;
		};
	}

	static function pairIntBool(value:Int, flag:Bool):String {
		return Std.string(value) + ":" + Std.string(flag);
	}

	static function pairIntInt(left:Int, right:Int):String {
		return Std.string(left) + ":" + Std.string(right);
	}

	static function sumUntilNegative(values:Array<Int>):Int {
		var total = 0;
		for (value in values) {
			if (value < 0) {
				return -1;
			}
			total += value;
		}
		return total;
	}

	static function callConstraintFunction(fn:haxe.Constraints.Function, left:Int, right:Int):Int {
		return cast Reflect.callMethod(null, fn, [left, right]);
	}

	static function preserveFlatEnum<T:haxe.Constraints.FlatEnum>(value:T):T {
		return value;
	}

	static function preserveNotVoid<T:haxe.Constraints.NotVoid>(value:T):T {
		return value;
	}

	static function preserveConstructible<T:haxe.Constraints.Constructible<() -> Void>>(value:T):T {
		return value;
	}

	static function sumIterator(iterator:Iterator<Int>):Int {
		var result = 0;
		while (iterator.hasNext()) {
			result += iterator.next();
		}
		return result;
	}

	static function sumIterable(iterable:Iterable<Int>):Int {
		return sumIterator(iterable.iterator());
	}

	// ArrayAccess is an extern-only marker. Keeping this typed boundary proves
	// that the target accepts the official compile-time contract.
	@:keep static function acceptArrayAccess<T>(value:ArrayAccess<T>):Void {}

	static function returnVoid():Void {}

	static function throwPortableNan():Void {
		throw Math.NaN;
	}

	static function progressCurrentThreadEvents(?timeout:Float):Void {
		var actualTimeout = timeout == null ? 1.0 : timeout;
		var events = Thread.current().events;
		Assert.isTrue(events.wait(actualTimeout));
		events.progress();
	}

	@:describe("haxe.EnumTools")
	@:test
	function testEnumToolsFallbackUsesTypeReflection():Void {
		var constructors = haxe.EnumTools.getConstructors(ParityTone);
		Assert.equals("Warm", constructors[0]);
		Assert.equals("Cool", constructors[1]);
		Assert.equals("Neutral", constructors[2]);

		var warm = haxe.EnumTools.createByName(ParityTone, "Warm", ["amber", 7]);
		Assert.equals("Warm", EnumValueTools.getName(warm));
		Assert.equals(0, EnumValueTools.getIndex(warm));
		Assert.equals("amber", EnumValueTools.getParameters(warm)[0]);
		Assert.equals(7, EnumValueTools.getParameters(warm)[1]);

		var cool = haxe.EnumTools.createByIndex(ParityTone, 1, ["blue"]);
		Assert.equals("Cool", EnumValueTools.getName(cool));
		Assert.isTrue(EnumValueTools.equals(cool, Cool("blue")));
		Assert.isFalse(EnumValueTools.equals(cool, Cool("green")));

		var noArg = haxe.EnumTools.createAll(ParityTone);
		Assert.equals(1, noArg.length);
		Assert.equals("Neutral", EnumValueTools.getName(noArg[0]));
	}

	@:describe("haxe.EnumFlags")
	@:test
	function testEnumFlagsFallbackUsesEnumIndices():Void {
		var flags = new EnumFlags<ParityColor>();
		Assert.isFalse(flags.has(Red));
		Assert.isFalse(flags.has(Green));

		flags.set(Red);
		Assert.isTrue(flags.has(Red));
		Assert.isFalse(flags.has(Green));
		Assert.equals(1, flags.toInt());

		flags.setTo(Green, true);
		Assert.isTrue(flags.has(Green));
		Assert.equals(3, flags.toInt());

		flags.unset(Red);
		Assert.isFalse(flags.has(Red));
		Assert.isTrue(flags.has(Green));
		Assert.equals(2, flags.toInt());

		var restored:EnumFlags<ParityColor> = EnumFlags.ofInt(3);
		Assert.isTrue(restored.has(Red));
		Assert.isTrue(restored.has(Green));
	}

	@:describe("Std compatibility aliases")
	@:test
	function testStdCompatibilityAliases():Void {
		var values = [1, 2];
		Assert.isTrue(Std.is(values, Array));
		Assert.equals(values, Std.instance(values, Array));
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

	@:describe("Haxe loop return semantics")
	@:test
	function testReturnInsideAccumulatorLoopExitsEnclosingFunction():Void {
		Assert.equals(6, sumUntilNegative([1, 2, 3]));
		Assert.equals(-1, sumUntilNegative([1, -2, 3]));
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

	@:describe("haxe.NativeStackTrace")
	@:test
	function testNativeStackTraceConvertsAndSkipsBeamFrames():Void {
		var native = NativeStackTrace.callStack();
		var full = NativeStackTrace.toHaxe(native);
		Assert.isTrue(full.length > 0);

		var skipped = NativeStackTrace.toHaxe(native, 1);
		Assert.equals(full.length - 1, skipped.length);
	}

	@:describe("haxe.NativeStackTrace")
	@:test
	function testNativeStackTraceSavesRescuedExceptionStack():Void {
		try {
			throwCallStackProbe();
			Assert.fail("throwCallStackProbe should throw");
		} catch (error:Dynamic) {
			NativeStackTrace.saveStack(error);
			var saved = NativeStackTrace.toHaxe(NativeStackTrace.exceptionStack());
			Assert.isTrue(saved.length > 0);
			Assert.containsString(CallStack.toString(cast saved), "throw_call_stack_probe");
		}
	}

	@:describe("haxe.PosInfos")
	@:test
	function testPosInfosPreservesInjectedAndExplicitFields():Void {
		var injected = capturePosition();
		Assert.equals("stdlib_parity/StdlibParityTest.hx", injected.fileName);
		Assert.equals(662, injected.lineNumber);
		Assert.equals("stdlib_parity.StdlibParityTest", injected.className);
		Assert.equals("testPosInfosPreservesInjectedAndExplicitFields", injected.methodName);

		var explicit:PosInfos = {
			fileName: "portable/source.hx",
			lineNumber: 27,
			className: "Portable.Source",
			methodName: "run",
			customParams: ["detail", 9]
		};
		var preserved = capturePosition(explicit);
		Assert.equals("portable/source.hx", preserved.fileName);
		Assert.equals(27, preserved.lineNumber);
		Assert.equals("Portable.Source", preserved.className);
		Assert.equals("run", preserved.methodName);
		Assert.equals("detail", preserved.customParams[0]);
		Assert.equals(9, preserved.customParams[1]);
	}

	@:describe("haxe.Log")
	@:test
	function testLogFormatOutputPreservesPositionAndParameters():Void {
		var position:PosInfos = {
			fileName: "portable/log.hx",
			lineNumber: 12,
			className: "Portable.LogProbe",
			methodName: "run",
			customParams: ["extra", 4]
		};
		Assert.equals("portable/log.hx:12: value, extra, 4", haxe.Log.formatOutput("value", position));
		Assert.equals("value", haxe.Log.formatOutput("value", null));
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

	@:describe("haxe.ValueException upstream fallback")
	@:test
	function testValueExceptionFallback():Void {
		var previous = new haxe.Exception("previous-cause");

		var stringException = new ValueException("raw-value", previous);
		var stringValue:String = cast stringException.value;
		var base:haxe.Exception = stringException;

		Assert.equals("raw-value", stringValue);
		Assert.equals("raw-value", stringException.message);
		Assert.equals("raw-value", stringException.toString());
		Assert.equals("previous-cause", stringException.previous.message);
		Assert.equals("raw-value", base.message);

		var intException = new ValueException(42);
		var intValue:Int = cast intException.value;

		Assert.equals(42, intValue);
		Assert.equals("42", intException.message);
		Assert.isNull(intException.previous);
	}

	@:describe("haxe.ValueException upstream fallback")
	@:test
	function testValueExceptionThrowCatch():Void {
		try {
			throw new ValueException("typed-value");
			Assert.fail("ValueException should be catchable by its concrete type");
		} catch (error:ValueException) {
			var value:String = cast error.value;
			Assert.equals("typed-value", value);
			Assert.equals("typed-value", error.message);
		}

		try {
			throw new ValueException(7);
			Assert.fail("ValueException should preserve arbitrary values when thrown");
		} catch (error:ValueException) {
			var value:Int = cast error.value;
			Assert.equals(7, value);
			Assert.equals("7", error.message);
		}
	}

	@:describe("haxe.Constraints upstream fallback")
	@:test
	function testConstraintsFunctionAliasCallMethod():Void {
		var fn:haxe.Constraints.Function = function(left:Int, right:Int):Int {
			return left + right;
		};

		Assert.equals(7, callConstraintFunction(fn, 3, 4));
	}

	@:describe("haxe.Constraints upstream fallback")
	@:test
	function testConstraintsIMapAliasUsesTargetRuntimeBoundary():Void {
		var nativeMap:haxe.Constraints.IMap<String, Int> = cast untyped __elixir__('%{"one" => 1, "two" => 2}');
		var pairs:Array<{key:String, value:Int}> = IMapRuntime.unwrap(nativeMap);
		var seenPairs = [pairToString(pairs[0]), pairToString(pairs[1])];

		Assert.equals(2, pairs.length);
		Assert.contains(seenPairs, "one:1");
		Assert.contains(seenPairs, "two:2");
	}

	@:describe("haxe.Constraints upstream fallback")
	@:test
	function testConstraintTypes():Void {
		Assert.equals(Red, preserveFlatEnum(Red));
		Assert.equals(12, preserveNotVoid(12));
		Assert.equals(17, preserveConstructible(new ConstraintConstructibleValue()).marker);

		var map:haxe.Constraints.IMap<String, Int> = new StringMap<Int>();
		map.set("one", 1);
		map.set("two", 2);
		Assert.equals(1, map.get("one"));
		Assert.isTrue(map.exists("two"));
		Assert.equals(3, sumIterator(map.iterator()));

		var keys = [];
		for (key in map.keys()) {
			keys.push(key);
		}
		Assert.contains(keys, "one");
		Assert.contains(keys, "two");

		var pairs = [];
		var pairIterator = map.keyValueIterator();
		while (pairIterator.hasNext()) {
			pairs.push(pairToString(pairIterator.next()));
		}
		Assert.contains(pairs, "one:1");
		Assert.contains(pairs, "two:2");
		var printed = map.toString();
		Assert.isTrue(StringTools.contains(printed, "one"));

		var copy = map.copy();
		Assert.isTrue(copy.remove("one"));
		Assert.isFalse(copy.exists("one"));
		copy.clear();
		Assert.isFalse(copy.exists("two"));
	}

	@:describe("StdTypes structural contracts")
	@:test
	function testStdTypesIteratorsAndCoreValues():Void {
		var boolValue:Bool = true;
		var intValue:Int = 4;
		var floatValue:Float = 2.5;
		// Dynamic is the public contract under test at this boundary.
		var dynamicValue:Dynamic = "dynamic-value";
		Assert.isTrue(boolValue);
		Assert.equals(4, intValue);
		Assert.equals(2.5, floatValue);
		Assert.equals("dynamic-value", (dynamicValue : String));
		returnVoid();

		var values = new StringMap<Int>();
		values.set("two", 2);
		values.set("three", 3);
		values.set("five", 5);
		var iterable:Iterable<Int> = {
			iterator: () -> values.iterator()
		};
		Assert.equals(10, sumIterable(iterable));

		var entries = new StringMap<Int>();
		entries.set("answer", 42);
		var keyValueIterable:KeyValueIterable<String, Int> = {
			keyValueIterator: () -> entries.keyValueIterator()
		};
		var keyValues:KeyValueIterator<String, Int> = keyValueIterable.keyValueIterator();
		Assert.isTrue(keyValues.hasNext());
		var entry = keyValues.next();
		Assert.equals("answer", entry.key);
		Assert.equals(42, entry.value);

		var nullable:Null<Int> = null;
		Assert.isNull(nullable);
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

	@:describe("haxe.ds.Either upstream fallback")
	@:test
	function testEitherPatternMatchingAndPayloads():Void {
		var left:Either<String, Int> = Left("missing");
		var right:Either<String, Int> = Right(42);

		Assert.equals("left:missing", describeStringIntEither(left));
		Assert.equals("right:42", describeStringIntEither(right));
	}

	@:describe("haxe.ds.Either upstream fallback")
	@:test
	function testEitherPreservesGenericPayloads():Void {
		var payload = {key: "alpha", value: 3};
		var either:Either<{key:String, value:Int}, Array<String>> = Left(payload);

		Assert.equals("alpha:3", describePayloadEither(either));

		either = Right(["x", "y"]);
		Assert.equals("x,y", describePayloadEither(either));
	}

	@:describe("haxe.ds.Option target surface")
	@:test
	function testOptionPatternMatchingAndPayloads():Void {
		var some:Option<String> = Some("ready");
		var none:Option<String> = None;

		Assert.equals("some:ready", describeStringOption(some));
		Assert.equals("none", describeStringOption(none));

		var payload:Option<{key:String, value:Int}> = Some({key: "alpha", value: 5});
		Assert.equals("alpha:5", describePayloadOption(payload));
	}

	@:describe("haxe.ds.Option target surface")
	@:test
	function testOptionToolsTransformAndExtractValues():Void {
		var value:Option<Int> = Some(21);
		var empty:Option<Int> = None;

		Assert.isTrue(OptionTools.isSome(value));
		Assert.isTrue(OptionTools.isNone(empty));
		Assert.equals("some:42", describeStringOption(OptionTools.map(value, function(n) return Std.string(n * 2))));
		Assert.equals(21, OptionTools.unwrap(value, 0));
		Assert.equals(7, OptionTools.unwrap(empty, 7));
		Assert.equals(99, OptionTools.lazyUnwrap(empty, function() return 99));
	}

	@:describe("haxe.ds.Option target surface")
	@:test
	function testOptionToolsCollectionAndResultBridges():Void {
		var allPresent = OptionTools.all([Some(1), Some(2), Some(3)]);
		var withMissing = OptionTools.all([Some(1), None, Some(3)]);
		var values = OptionTools.values([Some(4), None, Some(6)]);

		Assert.equals("some:1,2,3", describeIntArrayOption(allPresent));
		Assert.equals("none", describeIntArrayOption(withMissing));
		Assert.equals("4,6", values.join(","));
		Assert.equals("some:from-nullable", describeStringOption(OptionTools.fromNullable("from-nullable")));
		Assert.equals("none", describeStringOption(OptionTools.fromNullable(null)));
		Assert.equals("ok:8", describeIntResult(OptionTools.toResult(Some(8), "missing")));
		Assert.equals("error:missing", describeIntResult(OptionTools.toResult(None, "missing")));
		Assert.equals("some:9", describeStringOption(OptionTools.map(OptionTools.fromResult(Ok(9)), function(n) return Std.string(n))));
		Assert.equals("none", describeStringOption(OptionTools.fromResult(Error("bad"))));
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

	@:describe("haxe.Utf8")
	@:test
	function testUtf8UnicodeTargetFallback():Void {
		var buffer = new Utf8();
		buffer.addChar(0x41);
		buffer.addChar(0x1F30D);
		Assert.equals("A🌍", buffer.toString());

		var current = Thread.current();
		Utf8.iter("Aé🌍", code -> current.sendMessage(code));
		Assert.equals(65, Thread.readMessage(false));
		Assert.equals(233, Thread.readMessage(false));
		Assert.equals(0x1F30D, Thread.readMessage(false));
		Assert.equals(3, Utf8.length("Aé🌍"));
		Assert.equals(0x1F30D, Utf8.charCodeAt("Aé🌍", 2));
		Assert.equals("é🌍", Utf8.sub("Aé🌍", 1, 2));
		Assert.isTrue(Utf8.validate("Aé🌍"));
		// Malformed UTF-8 cannot be written as a Haxe String literal. Keep the
		// target escape at the exact binary representation boundary under test.
		var invalidUtf8:String = untyped __elixir__('<<0xC0>>');
		Assert.isFalse(Utf8.validate(invalidUtf8));
		Assert.raises(() -> Utf8.charCodeAt("A", 1));
		Assert.equals(-1, Utf8.compare("a", "b"));
		Assert.equals(0, Utf8.compare("a", "a"));
		Assert.equals(1, Utf8.compare("b", "a"));
	}

	@:describe("haxe.Utf8")
	@:test
	function testUtf8LegacyTranscodingFailsFast():Void {
		Assert.raises(() -> Utf8.encode("é"));
		Assert.raises(() -> Utf8.decode("é"));
	}

	@:describe("haxe.Ucs2")
	@:test
	function testUcs2FailsFastWithoutNativeTargetSupport():Void {
		try {
			Ucs2.fromCharCode(65);
			Assert.fail("Ucs2 should reject targets without native UCS-2 strings");
		} catch (error:Dynamic) {
			Assert.equals("Ucs2 String not supported on this platform", Std.string(error));
		}
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
	function testIoErrorConstructorsAndPayload():Void {
		var simpleErrors = [Error.Blocked, Error.Overflow, Error.OutsideBounds];
		var matched = 0;
		for (error in simpleErrors) {
			switch (error) {
				case Blocked | Overflow | OutsideBounds:
					matched++;
				case Custom(_):
					Assert.fail("Expected a payload-free IO error");
			}
		}
		Assert.equals(3, matched);

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

	@:describe("haxe.io.Encoding")
	@:test
	function testIoEncodingPortableConstructors():Void {
		var utf8 = haxe.io.Encoding.UTF8;
		var raw = haxe.io.Encoding.RawNative;

		Assert.isTrue(switch (utf8) {
			case UTF8: true;
			default: false;
		});
		Assert.isTrue(switch (raw) {
			case RawNative: true;
			default: false;
		});
	}

	@:describe("haxe.io.Eof")
	@:test
	function testIoEofConstructorAndCatch():Void {
		var eof = new Eof();
		Assert.equals("Eof", eof.toString());

		try {
			throw eof;
			Assert.fail("Expected the Eof value to be caught");
		} catch (caught:Eof) {
			Assert.equals("Eof", caught.toString());
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

	@:describe("haxe.io.Mime and haxe.io.Scheme")
	@:test
	function testMimeAndSchemeOfficialFallback():Void {
		var json:String = Mime.ApplicationJson;
		var html:String = Mime.TextHtml;
		var customMime:Mime = "application/vnd.example+json";
		var customMimeText:String = customMime;

		var https:String = Scheme.Https;
		var mailTo:String = Scheme.MailTo;
		var customScheme:Scheme = "web+demo";
		var customSchemeText:String = customScheme;

		Assert.equals("application/json", json);
		Assert.equals("text/html", html);
		Assert.equals("application/vnd.example+json", customMimeText);
		Assert.equals("https", https);
		Assert.equals("mailto", mailTo);
		Assert.equals("web+demo", customSchemeText);
	}

	@:describe("haxe.http.HttpMethod")
	@:test
	function testHttpMethodOfficialFallback():Void {
		var methods:Array<haxe.http.HttpMethod> = [
			haxe.http.HttpMethod.Post,
			haxe.http.HttpMethod.Get,
			haxe.http.HttpMethod.Head,
			haxe.http.HttpMethod.Put,
			haxe.http.HttpMethod.Delete,
			haxe.http.HttpMethod.Trace,
			haxe.http.HttpMethod.Options,
			haxe.http.HttpMethod.Connect,
			haxe.http.HttpMethod.Patch
		];
		var expected = ["POST", "GET", "HEAD", "PUT", "DELETE", "TRACE", "OPTIONS", "CONNECT", "PATCH"];

		Assert.equals(expected.length, methods.length);
		for (index in 0...expected.length) {
			var actual:String = methods[index];
			Assert.equals(expected[index], actual);
		}

		var custom:haxe.http.HttpMethod = "PURGE";
		var customText:String = custom;
		Assert.equals("PURGE", customText);
	}

	@:describe("haxe.http.HttpStatus")
	@:test
	function testHttpStatusOfficialFallback():Void {
		var statuses:Array<haxe.http.HttpStatus> = [
			haxe.http.HttpStatus.Continue,
			haxe.http.HttpStatus.SwitchingProtocols,
			haxe.http.HttpStatus.Processing,
			haxe.http.HttpStatus.OK,
			haxe.http.HttpStatus.Created,
			haxe.http.HttpStatus.Accepted,
			haxe.http.HttpStatus.NonAuthoritativeInformation,
			haxe.http.HttpStatus.NoContent,
			haxe.http.HttpStatus.ResetContent,
			haxe.http.HttpStatus.PartialContent,
			haxe.http.HttpStatus.MultiStatus,
			haxe.http.HttpStatus.AlreadyReported,
			haxe.http.HttpStatus.IMUsed,
			haxe.http.HttpStatus.MultipleChoices,
			haxe.http.HttpStatus.MovedPermanently,
			haxe.http.HttpStatus.Found,
			haxe.http.HttpStatus.SeeOther,
			haxe.http.HttpStatus.NotModified,
			haxe.http.HttpStatus.UseProxy,
			haxe.http.HttpStatus.SwitchProxy,
			haxe.http.HttpStatus.TemporaryRedirect,
			haxe.http.HttpStatus.PermanentRedirect,
			haxe.http.HttpStatus.BadRequest,
			haxe.http.HttpStatus.Unauthorized,
			haxe.http.HttpStatus.PaymentRequired,
			haxe.http.HttpStatus.Forbidden,
			haxe.http.HttpStatus.NotFound,
			haxe.http.HttpStatus.MethodNotAllowed,
			haxe.http.HttpStatus.NotAcceptable,
			haxe.http.HttpStatus.ProxyAuthenticationRequired,
			haxe.http.HttpStatus.RequestTimeout,
			haxe.http.HttpStatus.Conflict,
			haxe.http.HttpStatus.Gone,
			haxe.http.HttpStatus.LengthRequired,
			haxe.http.HttpStatus.PreconditionFailed,
			haxe.http.HttpStatus.PayloadTooLarge,
			haxe.http.HttpStatus.URITooLong,
			haxe.http.HttpStatus.UnsupportedMediaType,
			haxe.http.HttpStatus.RangeNotSatisfiable,
			haxe.http.HttpStatus.ExpectationFailed,
			haxe.http.HttpStatus.ImATeapot,
			haxe.http.HttpStatus.MisdirectedRequest,
			haxe.http.HttpStatus.UnprocessableEntity,
			haxe.http.HttpStatus.Locked,
			haxe.http.HttpStatus.FailedDependency,
			haxe.http.HttpStatus.UpgradeRequired,
			haxe.http.HttpStatus.PreconditionRequired,
			haxe.http.HttpStatus.TooManyRequests,
			haxe.http.HttpStatus.RequestHeaderFieldsTooLarge,
			haxe.http.HttpStatus.UnavailableForLegalReasons,
			haxe.http.HttpStatus.InternalServerError,
			haxe.http.HttpStatus.NotImplemented,
			haxe.http.HttpStatus.BadGateway,
			haxe.http.HttpStatus.ServiceUnavailable,
			haxe.http.HttpStatus.GatewayTimeout,
			haxe.http.HttpStatus.HTTPVersionNotSupported,
			haxe.http.HttpStatus.VariantAlsoNegotiates,
			haxe.http.HttpStatus.InsufficientStorage,
			haxe.http.HttpStatus.LoopDetected,
			haxe.http.HttpStatus.NotExtended,
			haxe.http.HttpStatus.NetworkAuthenticationRequired
		];
		var expected = [
			100, 101, 102, 200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308, 400, 401, 402, 403, 404, 405, 406,
			407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 421, 422, 423, 424, 426, 428, 429, 431, 451, 500, 501, 502, 503, 504, 505, 506, 507,
			508, 510, 511
		];

		Assert.equals(expected.length, statuses.length);
		for (index in 0...expected.length) {
			var actual:Int = statuses[index];
			Assert.equals(expected[index], actual);
		}

		var custom:haxe.http.HttpStatus = 599;
		var customCode:Int = custom;
		Assert.equals(599, customCode);
	}

	@:describe("haxe.Http and sys.Http")
	@:test
	function testHttpGetCallbacksParametersAndHeaders():Void {
		var port = HttpContractServer.start("GET", "/search?name=a%20b%26c%3Dd%2F%2B%3F%20%C3%A9", 200, "get-ok");
		var http = new haxe.Http('http://127.0.0.1:$port/search');
		var testThread = Thread.current();

		http.setParameter("name", "a b&c=d/+? é");
		http.onStatus = nextStatus -> testThread.sendMessage('status:$nextStatus');
		http.onData = nextData -> testThread.sendMessage('data:$nextData');
		http.onBytes = nextBytes -> testThread.sendMessage('bytes:${nextBytes.toString()}');
		http.request(false);

		Assert.equals("status:200", Thread.readMessage(false));
		Assert.equals("data:get-ok", Thread.readMessage(false));
		Assert.equals("bytes:get-ok", Thread.readMessage(false));
		Assert.equals("get-ok", http.responseData);
		Assert.equals("get-ok", http.responseBytes.toString());
		Assert.equals("two", http.responseHeaders.get("x-test"));
		Assert.equals(["one", "two"], http.getResponseHeaderValues("x-test"));
		Assert.isNull(http.getResponseHeaderValues("missing"));
	}

	@:describe("haxe.Http and sys.Http")
	@:test
	function testHttpPostReuseCustomMethodAndStatusError():Void {
		var firstPort = HttpContractServer.start("POST", "payload&value", 201, "first-post");
		var http = new sys.Http('http://127.0.0.1:$firstPort/submit');
		var testThread = Thread.current();
		http.onData = nextData -> testThread.sendMessage(nextData);
		http.setPostData("payload&value");
		http.request(true);
		Assert.equals("first-post", Thread.readMessage(false));

		var secondPort = HttpContractServer.start("POST", "payload&value", 200, "second-post");
		http.url = 'http://127.0.0.1:$secondPort/submit-again';
		http.request(true);
		Assert.equals("second-post", Thread.readMessage(false));

		var putPort = HttpContractServer.start("PUT", "custom-body", 200, "put-ok");
		var custom = new sys.Http('http://127.0.0.1:$putPort/resource');
		var output = new BytesOutput();
		custom.setPostBytes(Bytes.ofString("custom-body"));
		custom.customRequest(false, output, null, "PUT");
		Assert.equals("put-ok", output.getBytes().toString());

		var errorPort = HttpContractServer.start("GET", "/missing", 404, "missing-body");
		var failed = new haxe.Http('http://127.0.0.1:$errorPort/missing');
		failed.onStatus = nextStatus -> testThread.sendMessage('status:$nextStatus');
		failed.onError = nextMessage -> testThread.sendMessage('error:$nextMessage');
		failed.request(false);
		Assert.equals("status:404", Thread.readMessage(false));
		Assert.equals("error:Http Error #404", Thread.readMessage(false));
		Assert.equals("missing-body", failed.responseBytes.toString());
	}

	@:describe("haxe.Http and sys.Http")
	@:test
	function testHttpMultipartFileTransfer():Void {
		var port = HttpContractServer.startWithNeedles("POST", [
			"multipart/form-data; boundary=",
			'name="note"\r\n\r\nhello\r\n',
			'name="upload"; filename="sample.txt"\r\nContent-Type: text/plain\r\n\r\nfile-data\r\n--'
		], 201, "multipart-ok");
		var http = new haxe.Http('http://127.0.0.1:$port/upload');
		http.setParameter("note", "hello");
		http.fileTransfer("upload", "sample.txt", new haxe.io.BytesInput(Bytes.ofString("file-data-ignored")), 9, "text/plain");
		http.request(false);

		Assert.equals("multipart-ok", http.responseData);
	}

	@:describe("sys.io.FileSeek")
	@:test
	function testFileSeekConstructors():Void {
		var origins = [sys.io.FileSeek.SeekBegin, sys.io.FileSeek.SeekCur, sys.io.FileSeek.SeekEnd];
		var expected = ["SeekBegin", "SeekCur", "SeekEnd"];

		Assert.equals(expected.length, origins.length);
		for (index in 0...expected.length) {
			Assert.equals(expected[index], Type.enumConstructor(origins[index]));
			Assert.equals(index, Type.enumIndex(origins[index]));
		}
	}

	@:describe("sys.ssl.DigestAlgorithm")
	@:test
	function testDigestAlgorithmValues():Void {
		var algorithms:Array<sys.ssl.DigestAlgorithm> = [
			sys.ssl.DigestAlgorithm.MD5,
			sys.ssl.DigestAlgorithm.SHA1,
			sys.ssl.DigestAlgorithm.SHA224,
			sys.ssl.DigestAlgorithm.SHA256,
			sys.ssl.DigestAlgorithm.SHA384,
			sys.ssl.DigestAlgorithm.SHA512,
			sys.ssl.DigestAlgorithm.RIPEMD160
		];
		var expected = ["MD5", "SHA1", "SHA224", "SHA256", "SHA384", "SHA512", "RIPEMD160"];

		Assert.equals(expected.length, algorithms.length);
		for (index in 0...expected.length) {
			var actual:String = algorithms[index];
			Assert.equals(expected[index], actual);
		}
	}

	@:describe("sys.ssl.Digest")
	@:test
	function testDigestHashSignAndVerify():Void {
		// This fixed RSA key is test data. It does not protect a system.
		var privateDer = Base64.decode("MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAMjQa1RTzP4JTemH9uOrATsOABsYGkOihKqe4r9FBuB8lJy4wmSIQIjA4o/TAPcdWYEJLujZ0jiFw5HjdbOgp+TS5bzfSDNeV/7uZaN09EpIlND0km+ZvauKU/qGSlq0eyZIrWRbmQGcreM1W9OhYhxnAFkTLdCImgfETDQUwTxbAgMBAAECgYBRsvGnqjxhMhnfo/BfKchjZUvHuiOdVrZQ0DmCBaxJkoXHySdVTVWsDYVfbEIdR3SNmdXa6But4UXyya6uOPN03ZZFAGIPVzPOGMMw92r4ti8cZtPYqWQxWeMwVbxH7doXtsytn2nGifLWkb2xYOr9ZSax9TMLJF8nFfgD4YltSQJBAOPMeT6AXxp25p2AeV/c6+/txx/UMoXgu/M2pwN0ixLU+ENpgiV5gAqhl/wqdo1tTswenO8CFk+mvxtxpCEjcd8CQQDhrLwb1xGxHyexHekpebkk/U9sB1uH26Rmzhz57wSLBMQ7+D//CVZPQfNdow06Pid7SuWrAwFEq7ObhrI7jl0FAkEArlNnIY6JuS3us++CcvsUz2qurMvt0gg2rRxQ2VMRrtquFqCiiV0ewIQDVGWGjhptZ8WxoTJ+snvP2gewa++9DwJAR19xEsD/SGxZCkwybLqhkpBGqRzeluYhZZ40TduJLUpxoaHO46MZV/G8vVWPHmd/5x916ZMGuKgxIrQD9I/+3QJBAIUwCoU84cF5L024f2SaxDQIvGmdkvKeHJTnzfXso/xhm4M0mdSbKKU1e4/tBhYkf5JDV1+eOMALiBRbVQx6Sfs=");
		var publicDer = Base64.decode("MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDI0GtUU8z+CU3ph/bjqwE7DgAbGBpDooSqnuK/RQbgfJScuMJkiECIwOKP0wD3HVmBCS7o2dI4hcOR43WzoKfk0uW830gzXlf+7mWjdPRKSJTQ9JJvmb2rilP6hkpatHsmSK1kW5kBnK3jNVvToWIcZwBZEy3QiJoHxEw0FME8WwIDAQAB");
		var privateKey = sys.ssl.Key.readDER(privateDer, false);
		var publicKey = sys.ssl.Key.readDER(publicDer, true);
		var message = Bytes.ofString("signed by ordinary Haxe");
		var signature = sys.ssl.Digest.sign(message, privateKey, sys.ssl.DigestAlgorithm.SHA256);

		Assert.equals("900150983cd24fb0d6963f7d28e17f72", sys.ssl.Digest.make(Bytes.ofString("abc"), sys.ssl.DigestAlgorithm.MD5).toHex());
		Assert.equals("a9993e364706816aba3e25717850c26c9cd0d89d", sys.ssl.Digest.make(Bytes.ofString("abc"), sys.ssl.DigestAlgorithm.SHA1).toHex());
		Assert.equals("23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7",
			sys.ssl.Digest.make(Bytes.ofString("abc"), sys.ssl.DigestAlgorithm.SHA224).toHex());
		Assert.equals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
			sys.ssl.Digest.make(Bytes.ofString("abc"), sys.ssl.DigestAlgorithm.SHA256).toHex());
		Assert.equals("cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7",
			sys.ssl.Digest.make(Bytes.ofString("abc"), sys.ssl.DigestAlgorithm.SHA384).toHex());
		Assert.equals("ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f",
			sys.ssl.Digest.make(Bytes.ofString("abc"), sys.ssl.DigestAlgorithm.SHA512).toHex());
		Assert.equals("8eb208f7e05d987a9b044a8e98c6b087f15a0bfc", sys.ssl.Digest.make(Bytes.ofString("abc"), sys.ssl.DigestAlgorithm.RIPEMD160).toHex());
		Assert.isTrue(signature.length > 0);
		Assert.isTrue(sys.ssl.Digest.verify(message, signature, publicKey, sys.ssl.DigestAlgorithm.SHA256));
		Assert.isFalse(sys.ssl.Digest.verify(Bytes.ofString("changed"), signature, publicKey, sys.ssl.DigestAlgorithm.SHA256));
	}

	@:describe("sys.ssl.Certificate")
	@:test
	function testSslCertificateMetadataFilesAndChain():Void {
		// These fixed certificates are test data. They do not identify a live service.
		var leafPem = sslPem("CERTIFICATE", sslLeafCertificateBody());
		var rootPem = sslPem("CERTIFICATE", sslRootCertificateBody());
		var certificate = sys.ssl.Certificate.fromString(leafPem);

		Assert.equals("example.test", certificate.subject("CN"));
		Assert.equals("Reflaxe Elixir Tests", certificate.subject("organizationName"));
		Assert.equals("Compiler", certificate.subject("2.5.4.11"));
		Assert.equals(null, certificate.subject("missing-field"));
		Assert.equals("Reflaxe Root CA", certificate.issuer("CN"));
		Assert.equals("example.test", certificate.commonName);
		Assert.equals("example.test,www.example.test", certificate.altNames.join(","));
		Assert.equals(2026, certificate.notBefore.getUTCFullYear());
		Assert.equals(7, certificate.notBefore.getUTCMonth());
		Assert.equals(31, certificate.notBefore.getUTCDate());
		Assert.equals(5, certificate.notBefore.getUTCHours());
		Assert.equals(2027, certificate.notAfter.getUTCFullYear());
		Assert.equals(null, certificate.next());

		certificate.addDER(Base64.decode(sslRootCertificateBody()));
		var appended = certificate.next();
		Assert.isNotNull(appended, "Certificate.addDER and next should expose the appended certificate");
		Assert.equals("Reflaxe Root CA", appended.commonName);
		Assert.equals(null, appended.next());

		var directory = "_tmp/reflaxe_ssl_certificate_exunit_contract";
		if (!sys.FileSystem.exists(directory))
			sys.FileSystem.createDirectory(directory);
		var leafPath = directory + "/leaf.pem";
		var rootPath = directory + "/root.pem";
		sys.io.File.saveContent(leafPath, leafPem);
		sys.io.File.saveContent(rootPath, rootPem);
		Assert.equals("example.test", sys.ssl.Certificate.loadFile(leafPath).commonName);
		var pathCertificate = sys.ssl.Certificate.loadPath(directory);
		var pathNames:Array<String> = [];
		while (pathCertificate != null) {
			pathNames.push(pathCertificate.commonName);
			pathCertificate = pathCertificate.next();
		}
		Assert.equals(2, pathNames.length);
		Assert.isTrue(pathNames.indexOf("Reflaxe Root CA") >= 0);
		Assert.isTrue(pathNames.indexOf("example.test") >= 0);
		sys.FileSystem.deleteFile(leafPath);
		sys.FileSystem.deleteFile(rootPath);
		sys.FileSystem.deleteDirectory(directory);
	}

	@:describe("sys.ssl.Key")
	@:test
	function testSslKeyPemDerFileAndProcessTransfer():Void {
		// This fixed RSA key is test data. It does not protect a system.
		var privateBody = "MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAMjQa1RTzP4JTemH9uOrATsOABsYGkOihKqe4r9FBuB8lJy4wmSIQIjA4o/TAPcdWYEJLujZ0jiFw5HjdbOgp+TS5bzfSDNeV/7uZaN09EpIlND0km+ZvauKU/qGSlq0eyZIrWRbmQGcreM1W9OhYhxnAFkTLdCImgfETDQUwTxbAgMBAAECgYBRsvGnqjxhMhnfo/BfKchjZUvHuiOdVrZQ0DmCBaxJkoXHySdVTVWsDYVfbEIdR3SNmdXa6But4UXyya6uOPN03ZZFAGIPVzPOGMMw92r4ti8cZtPYqWQxWeMwVbxH7doXtsytn2nGifLWkb2xYOr9ZSax9TMLJF8nFfgD4YltSQJBAOPMeT6AXxp25p2AeV/c6+/txx/UMoXgu/M2pwN0ixLU+ENpgiV5gAqhl/wqdo1tTswenO8CFk+mvxtxpCEjcd8CQQDhrLwb1xGxHyexHekpebkk/U9sB1uH26Rmzhz57wSLBMQ7+D//CVZPQfNdow06Pid7SuWrAwFEq7ObhrI7jl0FAkEArlNnIY6JuS3us++CcvsUz2qurMvt0gg2rRxQ2VMRrtquFqCiiV0ewIQDVGWGjhptZ8WxoTJ+snvP2gewa++9DwJAR19xEsD/SGxZCkwybLqhkpBGqRzeluYhZZ40TduJLUpxoaHO46MZV/G8vVWPHmd/5x916ZMGuKgxIrQD9I/+3QJBAIUwCoU84cF5L024f2SaxDQIvGmdkvKeHJTnzfXso/xhm4M0mdSbKKU1e4/tBhYkf5JDV1+eOMALiBRbVQx6Sfs=";
		var publicBody = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDI0GtUU8z+CU3ph/bjqwE7DgAbGBpDooSqnuK/RQbgfJScuMJkiECIwOKP0wD3HVmBCS7o2dI4hcOR43WzoKfk0uW830gzXlf+7mWjdPRKSJTQ9JJvmb2rilP6hkpatHsmSK1kW5kBnK3jNVvToWIcZwBZEy3QiJoHxEw0FME8WwIDAQAB";
		var privateDer = Base64.decode(privateBody);
		var publicDer = Base64.decode(publicBody);
		var pkcs1PrivateDer = Base64.decode("MIICXQIBAAKBgQDI0GtUU8z+CU3ph/bjqwE7DgAbGBpDooSqnuK/RQbgfJScuMJkiECIwOKP0wD3HVmBCS7o2dI4hcOR43WzoKfk0uW830gzXlf+7mWjdPRKSJTQ9JJvmb2rilP6hkpatHsmSK1kW5kBnK3jNVvToWIcZwBZEy3QiJoHxEw0FME8WwIDAQABAoGAUbLxp6o8YTIZ36PwXynIY2VLx7ojnVa2UNA5ggWsSZKFx8knVU1VrA2FX2xCHUd0jZnV2ugbreFF8smurjjzdN2WRQBiD1czzhjDMPdq+LYvHGbT2KlkMVnjMFW8R+3aF7bMrZ9pxony1pG9sWDq/WUmsfUzCyRfJxX4A+GJbUkCQQDjzHk+gF8aduadgHlf3Ovv7ccf1DKF4LvzNqcDdIsS1PhDaYIleYAKoZf8KnaNbU7MHpzvAhZPpr8bcaQhI3HfAkEA4ay8G9cRsR8nsR3pKXm5JP1PbAdbh9ukZs4c+e8EiwTEO/g//wlWT0HzXaMNOj4ne0rlqwMBRKuzm4ayO45dBQJBAK5TZyGOibkt7rPvgnL7FM9qrqzL7dIINq0cUNlTEa7arhagooldHsCEA1Rlho4abWfFsaEyfrJ7z9oHsGvvvQ8CQEdfcRLA/0hsWQpMMmy6oZKQRqkc3pbmIWWeNE3biS1KcaGhzuOjGVfxvL1Vjx5nf+cfdemTBrioMSK0A/SP/t0CQQCFMAqFPOHBeS9NuH9kmsQ0CLxpnZLynhyU58317KP8YZuDNJnUmyilNXuP7QYWJH+SQ1dfnjjAC4gUW1UMekn7");
		var pkcs1PublicDer = Base64.decode("MIGJAoGBAMjQa1RTzP4JTemH9uOrATsOABsYGkOihKqe4r9FBuB8lJy4wmSIQIjA4o/TAPcdWYEJLujZ0jiFw5HjdbOgp+TS5bzfSDNeV/7uZaN09EpIlND0km+ZvauKU/qGSlq0eyZIrWRbmQGcreM1W9OhYhxnAFkTLdCImgfETDQUwTxbAgMBAAE=");
		var privatePem = sslPem("PRIVATE KEY", privateBody);
		var publicPem = sslPem("PUBLIC KEY", publicBody);
		var encryptedPem = encryptedPrivateKeyPem();
		var message = Bytes.ofString("portable sys.ssl.Key");
		var publicKey = sys.ssl.Key.readPEM(publicPem, true);

		var privateKey = sys.ssl.Key.readPEM(privatePem, false);
		var encryptedKey = sys.ssl.Key.readPEM(encryptedPem, false, "haxe-test-pass");
		Assert.raises(() -> sys.ssl.Key.readPEM(encryptedPem, false, "wrong-pass"));
		Assert.isTrue(sys.ssl.Digest.verify(message, sys.ssl.Digest.sign(message, privateKey, sys.ssl.DigestAlgorithm.SHA256), publicKey,
			sys.ssl.DigestAlgorithm.SHA256));
		Assert.isTrue(sys.ssl.Digest.verify(message, sys.ssl.Digest.sign(message, encryptedKey, sys.ssl.DigestAlgorithm.SHA256), publicKey,
			sys.ssl.DigestAlgorithm.SHA256));
		var pkcs1PrivateKey = sys.ssl.Key.readDER(pkcs1PrivateDer, false);
		var pkcs1PublicKey = sys.ssl.Key.readDER(pkcs1PublicDer, true);
		Assert.isTrue(sys.ssl.Digest.verify(message, sys.ssl.Digest.sign(message, pkcs1PrivateKey, sys.ssl.DigestAlgorithm.SHA256), pkcs1PublicKey,
			sys.ssl.DigestAlgorithm.SHA256));

		var root = "_tmp/reflaxe_ssl_key_exunit_contract";
		if (!sys.FileSystem.exists(root))
			sys.FileSystem.createDirectory(root);
		var privatePath = root + "/private.pem";
		var publicPath = root + "/public.der";
		var encryptedPath = root + "/private-encrypted.pem";
		sys.io.File.saveContent(privatePath, privatePem);
		sys.io.File.saveBytes(publicPath, publicDer);
		sys.io.File.saveContent(encryptedPath, encryptedPem);
		var filePrivateKey = sys.ssl.Key.loadFile(privatePath);
		var filePublicKey = sys.ssl.Key.loadFile(publicPath, true);
		var fileEncryptedKey = sys.ssl.Key.loadFile(encryptedPath, false, "haxe-test-pass");
		Assert.isTrue(sys.ssl.Digest.verify(message, sys.ssl.Digest.sign(message, filePrivateKey, sys.ssl.DigestAlgorithm.SHA256), filePublicKey,
			sys.ssl.DigestAlgorithm.SHA256));
		Assert.isTrue(sys.ssl.Digest.verify(message, sys.ssl.Digest.sign(message, fileEncryptedKey, sys.ssl.DigestAlgorithm.SHA256), filePublicKey,
			sys.ssl.DigestAlgorithm.SHA256));
		sys.FileSystem.deleteFile(privatePath);
		sys.FileSystem.deleteFile(publicPath);
		sys.FileSystem.deleteFile(encryptedPath);
		sys.FileSystem.deleteDirectory(root);

		var derPrivateKey = sys.ssl.Key.readDER(privateDer, false);
		var derPublicKey = sys.ssl.Key.readDER(publicDer, true);
		var parent = Thread.current();
		Thread.create(function() {
			try {
				var signature = sys.ssl.Digest.sign(message, derPrivateKey, sys.ssl.DigestAlgorithm.SHA256);
				parent.sendMessage(sys.ssl.Digest.verify(message, signature, derPublicKey, sys.ssl.DigestAlgorithm.SHA256));
			} catch (_:haxe.Exception) {
				parent.sendMessage(false);
			}
		});
		Assert.equals(true, Thread.readMessage(true));
	}

	static function sslPem(label:String, body:String):String {
		var lines:Array<String> = [];
		var offset = 0;
		while (offset < body.length) {
			lines.push(body.substr(offset, 64));
			offset += 64;
		}
		return "-----BEGIN " + label + "-----\n" + lines.join("\n") + "\n-----END " + label + "-----\n";
	}

	static function sslLeafCertificateBody():String {
		return "MIIDkjCCAnqgAwIBAgIUZ64+bFTy8FCv3/YLmULejl7ZiwcwDQYJKoZIhvcNAQEL"
			+ "BQAwQTELMAkGA1UEBhMCTVgxGDAWBgNVBAoMD1JlZmxheGUgVGVzdCBDQTEYMBYG"
			+ "A1UEAwwPUmVmbGF4ZSBSb290IENBMB4XDTI2MDgzMTA1MzIzNVoXDTI3MDgzMTA1"
			+ "MzIzNVowVjELMAkGA1UEBhMCTVgxHTAbBgNVBAoMFFJlZmxheGUgRWxpeGlyIFRl"
			+ "c3RzMREwDwYDVQQLDAhDb21waWxlcjEVMBMGA1UEAwwMZXhhbXBsZS50ZXN0MIIB"
			+ "IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0AS+3gZjXa5Qxon9ix+SnLsa"
			+ "GjwtS7n27GDkaUMWJLj/HSJgjAWbuZEgGRacU3SMcpxxj6kbnB/VLyvh6ZFdmEnX"
			+ "mSm18UiO5WUTpJxWIh8eGtCG6kBDmwjsxafi0SDpq/hY6bfe7rw3XFAdbFUQTBlN"
			+ "GJS8cXJUO8LMUII51VTO6HafyanooFVmJqvIcP9Jc0WpkC+Pf4kTdCUD0gvgbsQn"
			+ "H4Qmn9D1MMGsI7cHv1TuBTaiJWDpTXvf6cWDlh/nBWC9pUbd2d7qSYUJe/J592/u"
			+ "1kGvE7bD37GD1AlGR8iuLeSKbCW3+vZJshAMmOpVSMeCf89eRp0P+apiySMMjwID"
			+ "AQABo20wazApBgNVHREEIjAgggxleGFtcGxlLnRlc3SCEHd3dy5leGFtcGxlLnRl"
			+ "c3QwHQYDVR0OBBYEFGzQHNO8KrFXIT9mdw2lGchbIAUbMB8GA1UdIwQYMBaAFK34"
			+ "yu1WVEKTMPYsMvVtQFeGgRa2MA0GCSqGSIb3DQEBCwUAA4IBAQCJJhxUUiNknNEW"
			+ "0V1pEIqMpyDOkraG6Lpo0kDTiMf3kKJJJoCtusKxYNu/4uJ+6qHgyZvbAT1K4yaB"
			+ "lSGVl09m2QhV16SCUFBwqObhWG190z0gAkglyhfEn66O92KuOUWielG6kYsxdv96"
			+ "VsrQ3JEQujOeCVpT+Z+61h3f/YlkxAaHqOGlNQpo/QKFjAxMDqPvbIfDGU0zV+AG"
			+ "Zw7zG0+treqoNzK7BIG1UzPqjXT41zyOve4Q5JTvmtPoWo3YvnqF+FqqkfQaAYU7"
			+ "psIh5pUBw5vK2ghmhq9E/wb4MAZpswzD+4VeSEwsbUjfU3DWexKbvLA5O1wKukfH"
			+ "pGsqGJGl";
	}

	static function sslRootCertificateBody():String {
		return "MIIDYzCCAkugAwIBAgIUa46EOG9aPLgRJKLPoew3RJvehBEwDQYJKoZIhvcNAQEL"
			+ "BQAwQTELMAkGA1UEBhMCTVgxGDAWBgNVBAoMD1JlZmxheGUgVGVzdCBDQTEYMBYG"
			+ "A1UEAwwPUmVmbGF4ZSBSb290IENBMB4XDTI2MDgzMTA1MzIzNVoXDTM2MDgyODA1"
			+ "MzIzNVowQTELMAkGA1UEBhMCTVgxGDAWBgNVBAoMD1JlZmxheGUgVGVzdCBDQTEY"
			+ "MBYGA1UEAwwPUmVmbGF4ZSBSb290IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A"
			+ "MIIBCgKCAQEAoxaBDD23jYSmqMzqfiotTC9JwGF+3BN65zHxVVKuAdmRP4D++OI2"
			+ "DT7U07WIUkwfp6aeXTsOv2qiuXSzv+Nr6sVbxgApGlMLAtslBOGXldUpXbrhsnc+"
			+ "cwAbav+jEtnxtBSM6UOUGtax34P2Tl7bHXJhv+Kj49xKpLxIJjuO1PhfF3nDJrPt"
			+ "ZsFedMbyYp9yAVz87UhB+T8YVQ2806NibaoZA7JeOLlze48dOh4rDi2kF4tB9yyz"
			+ "nThgobWhCzpT+WgNJls2h5xuCfBOPhk7y0AWpiRtd72OzVPw7Y4tkaYy+w/yTsGQ"
			+ "UCBWXRr9JwlTOUw64HJq+9m5jvmfrSqpHQIDAQABo1MwUTAdBgNVHQ4EFgQUrfjK"
			+ "7VZUQpMw9iwy9W1AV4aBFrYwHwYDVR0jBBgwFoAUrfjK7VZUQpMw9iwy9W1AV4aB"
			+ "FrYwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAHGq3hWpw7n8O"
			+ "CsmjV0vyjUDthhgNCGvvBzYZ4qRai9TGLkZucdOct8cXBsDNIF5MLvGP46hd4L4r"
			+ "SKLj1RNew2Gv9hG9fdaWsRFfMX04jtYgZhsZSjwsmGkztVPqwXr0Wl/A/JCI4wjw"
			+ "DR70HMad+sxJRNpHZ2i/Awbu7loLxxI/Ih2PdW0asX807kOqjR/7figPlGASPnFB"
			+ "59HAvgKUDENIqE70sEPdN75qhrsxL/hc4orThdw8aujZlRYzrxxVOkkPwAni+z0Y"
			+ "62CGAKaux3VRJ3Kij+Nx+2vH16G/4iDkSRQvyOlye0mcVAnmi96zx8d7/69v/iXb"
			+ "2FeXHBnJuQ==";
	}

	static function encryptedPrivateKeyPem():String {
		return "-----BEGIN ENCRYPTED PRIVATE KEY-----\n"
			+ "MIIC5TBfBgkqhkiG9w0BBQ0wUjAxBgkqhkiG9w0BBQwwJAQQQpeDvIQjlTxrKxgn\n"
			+ "/btTRgICCAAwDAYIKoZIhvcNAgkFADAdBglghkgBZQMEASoEECsaOY5BCgXJdCmJ\n"
			+ "neDMFIcEggKA7TtMwBxUR1CO/GCtITAHK9cuCZd6OZZqoTjwEY9RpfXRNBD4NyGG\n"
			+ "K6ZuY/pUJP2xwXq0lqVkqJlGGrlI+OB2OP42bkCM9YtoZJR3EvSHKzEA8o9NArog\n"
			+ "XAiQBRp3Kh70jyraq7ckEt/qYIM1HncbQe79GSMjXTJ9tY0BIOd2thbyrBMobR/v\n"
			+ "0igLYrHC6r8J7i1BjmUunAir4wTwMGrhe0XqvpWXN6CDz8yKeyUkWPzetE0VUCUx\n"
			+ "cqLrRq2x8xpjaUS5aRajdejxx1/jT3PdD6U5Ji5s+rKJPc6W58veOZj3CLRraveT\n"
			+ "DxNQdGzQhfOeyfImXaic7Q4xY2Xsgft54I+VgVwo9lituF2M0tNrvsaa0I+oFISP\n"
			+ "7WjeTHOviguTuVZsMnLTupHd/zn+rwuoN+SNP0XLKtAmqnauJeCQHmXZt2U7Ix2Q\n"
			+ "0Hlmh3MqAqb3rxfNV4mlo5RyIBSIdlBVjYA+6/xBeMIilOoJGzkM41fPPKXsWLLH\n"
			+ "OV1CY6YQ9VkWsZfddxSy0b1fyQRMs+Utz4mOBnbqerHJPuNIW8WKnXsEHUYAMwPr\n"
			+ "Ah9Pyl2bMit8+UC1NfUec4A++PaKn37iHLBWBJkeGMssK2IcyQx+RtnIF6Oiv9LU\n"
			+ "o9rtn5dd/GAsNbMd8F0uMdXPl5aJj1tBx2rYdUx1IYNXulDprQxh5AdG/S5e/aBI\n"
			+ "ZWTaUW5VgGtVz+rHmuMi5f04m6/QPckRYEXDwPkDzrUI2TdVf4JJWfhIqpsvEJav\n"
			+ "xekP2PgIJZUoyceyKeYi5eq+slJCQ4avCELSiVPXHh/AWliXmPIQDfyLlIlrtIad\n"
			+ "kE+7MKp4FO/19vVes9zEuNIKp6BUaw8W6g==\n"
			+ "-----END ENCRYPTED PRIVATE KEY-----\n";
	}

	@:describe("sys.thread.NoEventLoopException")
	@:test
	function testNoEventLoopExceptionValuesAndCatch():Void {
		var defaultError = new sys.thread.NoEventLoopException();
		Assert.equals("Event loop is not available. Refer to sys.thread.Thread.runWithEventLoop.", defaultError.message);

		var previous = new haxe.Exception("previous failure");
		var customError = new sys.thread.NoEventLoopException("custom event-loop failure", previous);
		Assert.equals("custom event-loop failure", customError.message);
		Assert.equals("previous failure", customError.previous.message);

		try {
			throw customError;
			Assert.fail("NoEventLoopException should be catchable by its concrete type");
		} catch (caught:sys.thread.NoEventLoopException) {
			Assert.equals("custom event-loop failure", caught.message);
		}
	}

	@:describe("sys.thread.Condition")
	@:test
	function testThreadConditionSignalAndBroadcast():Void {
		var condition = new sys.thread.Condition();
		var ready = new sys.thread.Lock();
		var resumed = new sys.thread.Lock();
		var allowFinalRelease = new sys.thread.Lock();
		var done = new sys.thread.Lock();

		Thread.create(function() {
			condition.acquire();
			condition.acquire();
			ready.release();
			condition.wait();
			condition.release();
			resumed.release();
			allowFinalRelease.wait();
			condition.release();
			done.release();
		});

		Assert.isTrue(ready.wait(2), "The Condition waiter did not acquire the mutex");
		condition.acquire();
		condition.signal();
		Assert.isFalse(resumed.wait(0), "The waiter resumed before the signaling owner released the mutex");
		condition.release();

		Assert.isTrue(resumed.wait(2), "Condition.signal did not resume the waiter");
		Assert.isFalse(condition.tryAcquire(), "Condition.wait did not restore the recursive mutex hold count");
		allowFinalRelease.release();
		Assert.isTrue(done.wait(2), "The waiter did not release its restored mutex holds");
		Assert.isTrue(condition.tryAcquire(), "The Condition mutex stayed locked after the waiter released every hold");
		condition.release();

		var broadcastCondition = new sys.thread.Condition();
		var broadcastReady = new sys.thread.Lock();
		var broadcastDone = new sys.thread.Lock();
		for (_ in 0...3) {
			Thread.create(function() {
				broadcastCondition.acquire();
				broadcastReady.release();
				broadcastCondition.wait();
				broadcastCondition.release();
				broadcastDone.release();
			});
		}

		Assert.isTrue(broadcastReady.wait(2), "The first Condition broadcast waiter did not start");
		Assert.isTrue(broadcastReady.wait(2), "The second Condition broadcast waiter did not start");
		Assert.isTrue(broadcastReady.wait(2), "The third Condition broadcast waiter did not start");
		broadcastCondition.acquire();
		broadcastCondition.signal();
		Assert.isFalse(broadcastDone.wait(0), "A signal waiter resumed before mutex release");
		broadcastCondition.release();
		Assert.isTrue(broadcastDone.wait(2), "Condition.signal did not resume one waiter");
		Assert.isFalse(broadcastDone.wait(0), "Condition.signal resumed more than one waiter");

		broadcastCondition.acquire();
		broadcastCondition.broadcast();
		Assert.isFalse(broadcastDone.wait(0), "A broadcast waiter resumed before mutex release");
		broadcastCondition.release();
		Assert.isTrue(broadcastDone.wait(2), "Condition.broadcast did not resume the first remaining waiter");
		Assert.isTrue(broadcastDone.wait(2), "Condition.broadcast did not resume the second remaining waiter");
	}

	@:describe("sys.thread.Thread and sys.thread.EventLoop")
	@:test
	function testThreadMessagesAndEventLoopAvailability():Void {
		var parent = Thread.current();
		Assert.isNull(Thread.readMessage(false));

		Thread.create(function() {
			try {
				Thread.current().events;
				parent.sendMessage("plain-thread-event-loop-present");
			} catch (_:sys.thread.NoEventLoopException) {
				parent.sendMessage("plain-thread-event-loop-missing");
			}
		});
		Assert.equals("plain-thread-event-loop-missing", Thread.readMessage(true));

		Thread.createWithEventLoop(function() {
			Thread.current().events.run(function() {
				parent.sendMessage("child-event-loop-ran");
			});
		});
		Assert.equals("child-event-loop-ran", Thread.readMessage(true));

		var events = Thread.current().events;
		Thread.create(function() {
			events.run(function() {
				parent.sendMessage("cross-process-event-ran");
			});
		});
		Assert.isTrue(events.wait(2));
		switch events.progress() {
			case Now:
			case other:
				Assert.fail('Expected EventLoop.Now after a queued event, got $other');
		}
		Assert.equals("cross-process-event-ran", Thread.readMessage(false));

		events.promise();
		events.runPromised(function() {
			parent.sendMessage("promised-event-ran");
		});
		Assert.isTrue(events.wait(2));
		switch events.progress() {
			case Now:
			case other:
				Assert.fail('Expected EventLoop.Now after a promised event, got $other');
		}
		Assert.equals("promised-event-ran", Thread.readMessage(false));
	}

	@:describe("sys.thread synchronization primitives")
	@:test
	function testThreadLocalDequeLockMutexAndSemaphore():Void {
		var parent = Thread.current();
		var tls = new sys.thread.Tls<String>();
		Assert.isNull(tls.value);
		tls.value = "main-thread";
		Thread.create(function() {
			parent.sendMessage(tls.value == null ? "child-tls-empty" : "child-tls-leaked");
			tls.value = "child-thread";
			parent.sendMessage(tls.value);
		});
		Assert.equals("child-tls-empty", Thread.readMessage(true));
		Assert.equals("child-thread", Thread.readMessage(true));
		Assert.equals("main-thread", tls.value);

		var deque = new sys.thread.Deque<String>();
		deque.add("tail");
		deque.push("front");
		Assert.equals("front", deque.pop(false));
		Assert.equals("tail", deque.pop(false));
		Assert.isNull(deque.pop(false));
		Thread.create(function() {
			parent.sendMessage("deque-waiting");
			parent.sendMessage('deque:${deque.pop(true)}');
		});
		Assert.equals("deque-waiting", Thread.readMessage(true));
		deque.add("handoff");
		Assert.equals("deque:handoff", Thread.readMessage(true));

		var lock = new sys.thread.Lock();
		Assert.isFalse(lock.wait(0));
		Thread.create(function() {
			lock.release();
			lock.release();
			parent.sendMessage("lock-released-twice");
		});
		Assert.equals("lock-released-twice", Thread.readMessage(true));
		Assert.isTrue(lock.wait(2));
		Assert.isTrue(lock.wait(2));
		Assert.isFalse(lock.wait(0));

		var mutex = new sys.thread.Mutex();
		mutex.acquire();
		mutex.acquire();
		Thread.create(function() {
			parent.sendMessage(mutex.tryAcquire() ? "mutex-acquired-too-early" : "mutex-blocked");
			mutex.acquire();
			parent.sendMessage("mutex-acquired");
			mutex.release();
		});
		Assert.equals("mutex-blocked", Thread.readMessage(true));
		mutex.release();
		Assert.isNull(Thread.readMessage(false));
		mutex.release();
		Assert.equals("mutex-acquired", Thread.readMessage(true));

		var semaphore = new sys.thread.Semaphore(1);
		semaphore.acquire();
		Thread.create(function() {
			parent.sendMessage(semaphore.tryAcquire(0) ? "semaphore-acquired-too-early" : "semaphore-blocked");
			semaphore.acquire();
			parent.sendMessage("semaphore-acquired");
			semaphore.release();
		});
		Assert.equals("semaphore-blocked", Thread.readMessage(true));
		semaphore.release();
		Assert.equals("semaphore-acquired", Thread.readMessage(true));
		Assert.isTrue(semaphore.tryAcquire(0));
		semaphore.release();
	}

	@:describe("sys.thread.ThreadPoolException")
	@:test
	function testThreadPoolExceptionValuesAndCatch():Void {
		var previous = new haxe.Exception("previous failure");
		var error = new sys.thread.ThreadPoolException("pool failure", previous);
		Assert.equals("pool failure", error.message);
		Assert.equals("previous failure", error.previous.message);

		try {
			throw error;
			Assert.fail("ThreadPoolException should be catchable by its concrete type");
		} catch (caught:sys.thread.ThreadPoolException) {
			Assert.equals("pool failure", caught.message);
		}
	}

	/** Remove only the files owned by the Haxe ExUnit filesystem contract. */
	static function cleanFilesystemContract(root:String):Void {
		var nested = root + "/nested";
		var link = root + "/nested-link";
		var original = nested + "/original.txt";
		var renamed = nested + "/renamed.txt";
		var stream = nested + "/stream.bin";
		var copied = nested + "/copied.bin";
		var createdByUpdate = nested + "/created-by-update.txt";

		if (sys.FileSystem.exists(link)) {
			sys.FileSystem.deleteFile(link);
		}
		if (sys.FileSystem.exists(original)) {
			sys.FileSystem.deleteFile(original);
		}
		if (sys.FileSystem.exists(renamed)) {
			sys.FileSystem.deleteFile(renamed);
		}
		if (sys.FileSystem.exists(stream)) {
			sys.FileSystem.deleteFile(stream);
		}
		if (sys.FileSystem.exists(copied)) {
			sys.FileSystem.deleteFile(copied);
		}
		if (sys.FileSystem.exists(createdByUpdate)) {
			sys.FileSystem.deleteFile(createdByUpdate);
		}
		if (sys.FileSystem.exists(nested)) {
			sys.FileSystem.deleteDirectory(nested);
		}
		if (sys.FileSystem.exists(root)) {
			sys.FileSystem.deleteDirectory(root);
		}
	}

	/** Native filesystem failures do not have one portable Haxe exception type. */
	static function assertNonEmptyDirectoryDeleteFails(path:String):Void {
		try {
			sys.FileSystem.deleteDirectory(path);
			throw "Deleting a non-empty directory should fail";
		} catch (error:Dynamic) {
			if (Std.isOfType(error, String)) {
				throw error;
			}
			Assert.isTrue(sys.FileSystem.exists(path));
		}
	}

	@:describe("sys.FileSystem and sys.FileStat")
	@:test
	function testFileSystemLifecycleAndStatFields():Void {
		var root = "_tmp/reflaxe_filesystem_exunit_contract";
		var nested = root + "/nested";
		var link = root + "/nested-link";
		var original = nested + "/original.txt";
		var renamed = nested + "/renamed.txt";

		cleanFilesystemContract(root);
		Assert.isFalse(sys.FileSystem.exists(root));

		sys.FileSystem.createDirectory(nested);
		Assert.isTrue(sys.FileSystem.exists(nested));
		Assert.isTrue(sys.FileSystem.isDirectory(nested));

		sys.io.File.saveContent(original, "hello");
		Assert.isTrue(sys.FileSystem.exists(original));
		Assert.isFalse(sys.FileSystem.isDirectory(original));
		Assert.equals("original.txt", sys.FileSystem.readDirectory(nested).join(","));
		assertNonEmptyDirectoryDeleteFails(nested);

		sys.FileSystem.rename(original, renamed);
		Assert.isFalse(sys.FileSystem.exists(original));
		Assert.isTrue(sys.FileSystem.exists(renamed));

		var stat = sys.FileSystem.stat(renamed);
		Assert.equals(5, stat.size);
		var integerFields:Array<Int> = [stat.gid, stat.uid, stat.dev, stat.ino, stat.nlink, stat.rdev, stat.mode];
		for (value in integerFields) {
			Assert.isTrue(Std.isOfType(value, Int));
		}
		Assert.isTrue(stat.nlink >= 1);

		var dateFields:Array<Date> = [stat.atime, stat.mtime, stat.ctime];
		for (value in dateFields) {
			Assert.isTrue(value.getTime() > 0);
		}

		// Link creation is target-specific setup for the portable fullPath contract.
		elixir.File.lnSymbolicBang("nested", link);
		Assert.isTrue(sys.FileSystem.isDirectory(link));
		Assert.equals(sys.FileSystem.fullPath(renamed), sys.FileSystem.fullPath(link + "/renamed.txt"));

		var absolute = sys.FileSystem.absolutePath(root);
		var resolved = sys.FileSystem.fullPath(root);
		Assert.isTrue(haxe.io.Path.isAbsolute(absolute));
		Assert.isTrue(haxe.io.Path.isAbsolute(resolved));
		Assert.isTrue(StringTools.endsWith(absolute, root));
		Assert.isTrue(StringTools.endsWith(resolved, root));

		sys.FileSystem.deleteFile(link);
		sys.FileSystem.deleteFile(renamed);
		sys.FileSystem.deleteDirectory(nested);
		sys.FileSystem.deleteDirectory(root);
		Assert.isFalse(sys.FileSystem.exists(root));
	}

	@:describe("sys.io.File, sys.io.FileInput, and sys.io.FileOutput")
	@:test
	function testFileStreamLifecycleAndBinaryData():Void {
		var root = "_tmp/reflaxe_file_stream_exunit_contract";
		var nested = root + "/nested";
		var stream = nested + "/stream.bin";
		var copied = nested + "/copied.bin";
		var createdByUpdate = nested + "/created-by-update.txt";

		cleanFilesystemContract(root);
		sys.FileSystem.createDirectory(nested);

		var output = sys.io.File.write(stream);
		output.writeByte("a".code);
		Assert.equals(4, output.writeBytes(Bytes.ofString("bcde"), 0, 4));
		Assert.equals(5, output.tell());
		output.seek(1, sys.io.FileSeek.SeekBegin);
		Assert.equals(2, output.writeBytes(Bytes.ofString("XY"), 0, 2));
		Assert.equals(3, output.tell());
		output.close();
		Assert.equals("aXYde", sys.io.File.getContent(stream));

		var append = sys.io.File.append(stream);
		append.writeString("fg");
		append.close();
		Assert.equals("aXYdefg", sys.io.File.getContent(stream));

		var update = sys.io.File.update(stream);
		update.seek(-2, sys.io.FileSeek.SeekEnd);
		update.writeString("HI");
		update.close();
		Assert.equals("aXYdeHI", sys.io.File.getContent(stream));

		var created = sys.io.File.update(createdByUpdate);
		created.close();
		Assert.isTrue(sys.FileSystem.exists(createdByUpdate));

		var input = sys.io.File.read(stream);
		Assert.equals(0, input.tell());
		Assert.isFalse(input.eof());
		Assert.equals(0, input.tell());
		Assert.equals("a".code, input.readByte());
		var callerBuffer = Bytes.alloc(6);
		callerBuffer.fill(0, callerBuffer.length, "_".code);
		Assert.equals(3, input.readBytes(callerBuffer, 2, 3));
		Assert.equals("__XYd_", callerBuffer.toString());
		Assert.equals(4, input.tell());
		input.seek(-2, sys.io.FileSeek.SeekEnd);
		Assert.equals("HI", input.read(2).toString());
		Assert.isTrue(input.eof());
		input.close();

		var binary = Bytes.alloc(4);
		binary.set(0, 0);
		binary.set(1, 1);
		binary.set(2, 127);
		binary.set(3, 255);
		sys.io.File.saveBytes(copied, binary);
		Assert.equals(0, sys.io.File.getBytes(copied).compare(binary));
		sys.io.File.copy(copied, stream);
		Assert.equals(0, sys.io.File.getBytes(stream).compare(binary));

		cleanFilesystemContract(root);
		Assert.isFalse(sys.FileSystem.exists(root));
	}

	@:describe("sys.net.Host")
	@:test
	function testHostIPv4AndNameContracts():Void {
		var loopback = new sys.net.Host("127.0.0.1");
		Assert.equals("127.0.0.1", loopback.host);
		Assert.equals(2130706433, loopback.ip);
		Assert.equals("127.0.0.1", loopback.toString());
		Assert.isFalse(loopback.reverse() == "");

		var signedBoundary = new sys.net.Host("128.0.0.1");
		Assert.equals(-2147483647, signedBoundary.ip);
		Assert.equals("128.0.0.1", signedBoundary.toString());

		var unsignedMaximum = new sys.net.Host("255.255.255.255");
		Assert.equals(-1, unsignedMaximum.ip);
		Assert.equals("255.255.255.255", unsignedMaximum.toString());

		Assert.isFalse(sys.net.Host.localhost() == "");
		Assert.raises(() -> new sys.net.Host("::1"));
	}

	@:describe("sys.net.Address")
	@:test
	function testAddressSameProcessValueContracts():Void {
		var address = new sys.net.Address();
		Assert.equals(0, address.host);
		Assert.equals(0, address.port);

		address.host = 2130706433;
		address.port = 4001;
		Assert.equals("127.0.0.1", address.getHost().toString());

		var sameAddress = address;
		sameAddress.port = 4002;
		Assert.equals(4002, address.port);

		var cloned = address.clone();
		Assert.equals(0, address.compare(cloned));
		cloned.port = 4003;
		Assert.equals(4002, address.port);
		Assert.equals(1, address.compare(cloned));
		Assert.equals(-1, cloned.compare(address));

		cloned.host = address.host + 1;
		cloned.port = address.port;
		Assert.equals(1, address.compare(cloned));
	}

	@:describe("sys.net.UdpSocket")
	@:test
	function testUdpSocketReceivesIntoCallerBuffer():Void {
		var host = new sys.net.Host("127.0.0.1");
		var receiver = new sys.net.UdpSocket();
		receiver.bind(host, 0);
		var receiverEndpoint = receiver.host();
		Assert.isTrue(receiverEndpoint.port > 0);

		receiver.setBlocking(false);
		try {
			receiver.readFrom(Bytes.alloc(1), 0, 1, new sys.net.Address());
			Assert.fail("readFrom should block when no datagram is ready");
		} catch (error:Error) {
			switch (error) {
				case Blocked:
				default:
					Assert.fail("readFrom should raise Error.Blocked without data");
			}
		}
		receiver.setBlocking(true);
		receiver.setTimeout(0.25);

		var sender = new sys.net.UdpSocket();
		var senderEndpoint = sender.host();
		var destination = new sys.net.Address();
		destination.host = host.ip;
		destination.port = receiverEndpoint.port;
		var payload = Bytes.ofString("hello!");
		Assert.equals(payload.length, sender.sendTo(payload, 0, payload.length, destination));

		var buffer = Bytes.ofString("________");
		var source = new sys.net.Address();
		Assert.equals(5, receiver.readFrom(buffer, 2, 5, source));
		Assert.equals("__hello_", buffer.toString());
		Assert.equals(host.ip, source.host);
		Assert.equals(senderEndpoint.port, source.port);

		sender.close();
		receiver.close();
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

	@:describe("UInt and haxe.Int32")
	@:test
	function testUnsignedAndSigned32BitWidthContracts():Void {
		var unsignedMax:UInt = -1;
		var unsignedZero:UInt = 0;
		Assert.isTrue(unsignedMax > unsignedZero);
		Assert.equals(4294967295.0, (unsignedMax : Float));
		Assert.equals(0, ((unsignedMax + 1) : Int));
		Assert.equals(2147483647, ((unsignedMax >>> 1) : Int));
		Assert.equals(1, ((unsignedMax & 1) : Int));

		var unsignedCounter:UInt = Std.parseInt("-1");
		Assert.equals(-1, (unsignedCounter++ : Int));
		Assert.equals(0, (unsignedCounter : Int));

		var signedMax = Int32.ofInt(2147483647);
		var signedMin = signedMax + Int32.ofInt(1);
		Assert.equals(-2147483648, (signedMin : Int));
		Assert.equals(2147483647, ((Int32.ofInt(-1) >>> Int32.ofInt(1)) : Int));
		Assert.equals(1, Int32.ucompare(Int32.ofInt(-1), Int32.ofInt(0)));
		Assert.equals(-1, Int32.ucompare(Int32.ofInt(0), Int32.ofInt(-1)));
	}

	@:describe("haxe.Int64 and haxe.Int64Helper")
	@:test
	function testInt64PublicOperationSurface():Void {
		var six = Int64.ofInt(6);
		var three = Int64.ofInt(3);
		Assert.equals("6", Int64.toStr(six.copy()));
		Assert.isTrue(Int64.is(six));
		Assert.isTrue(Int64.isInt64(six));
		Assert.isFalse(Int64.isNeg(six));
		Assert.isTrue(Int64.isNeg(Int64.neg(six)));
		Assert.isTrue(Int64.isZero(Int64.ofInt(0)));
		Assert.equals(1, Int64.compare(six, three));
		Assert.equals(1, Int64.ucompare(Int64.ofInt(-1), Int64.ofInt(0)));
		Assert.isTrue(Int64.eq(six, Int64.ofInt(6)));
		Assert.isTrue(Int64.neq(six, three));

		Assert.equals("9", Int64.toStr(Int64.add(six, three)));
		Assert.equals("3", Int64.toStr(Int64.sub(six, three)));
		Assert.equals("18", Int64.toStr(Int64.mul(six, three)));
		Assert.equals(2.0, Int64.div(six, three));
		Assert.equals("0", Int64.toStr(Int64.mod(six, three)));
		Assert.equals("2", Int64.toStr(Int64.and(six, three)));
		Assert.equals("7", Int64.toStr(Int64.or(six, three)));
		Assert.equals("5", Int64.toStr(Int64.xor(six, three)));
		Assert.equals("12", Int64.toStr(Int64.shl(six, 1)));
		Assert.equals("3", Int64.toStr(Int64.shr(six, 1)));
		Assert.equals("3", Int64.toStr(Int64.ushr(six, 1)));

		var division = Int64.divMod(Int64.ofInt(17), Int64.ofInt(5));
		Assert.equals("3", Int64.toStr(division.quotient));
		Assert.equals("2", Int64.toStr(division.modulus));
		Assert.equals("42", Int64.toStr(Int64.fromFloat(42.75)));
		Assert.equals("-42", Int64.toStr(haxe.Int64Helper.fromFloat(-42.75)));
		Assert.equals("123", Int64.toStr(haxe.Int64Helper.parseString(" 123 ")));
		Assert.raises(() -> haxe.Int64Helper.parseString("9223372036854775808"));
		Assert.raises(() -> haxe.Int64Helper.parseString("not-an-integer"));
		Assert.raises(() -> haxe.Int64Helper.fromFloat(Math.NaN));

		var composite = Int64.make(Int32.ofInt(1), Int32.ofInt(2));
		Assert.equals(1, (Int64.getHigh(composite) : Int));
		Assert.equals(2, (Int64.getLow(composite) : Int));
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
	function testTimerRepeatUsesEventLoop():Void {
		var repeated = new Timer(1);
		repeated.run = function() {
			Thread.current().sendMessage("timer-repeat");
		};
		progressCurrentThreadEvents();
		Assert.equals("timer-repeat", Thread.readMessage(false));
		progressCurrentThreadEvents();
		Assert.equals("timer-repeat", Thread.readMessage(false));
		repeated.stop();
	}

	@:describe("haxe.Timer")
	@:test
	function testTimerDelayUsesEventLoop():Void {
		Timer.delay(function() {
			Thread.current().sendMessage("timer-delay");
		}, 1);
		progressCurrentThreadEvents();
		Assert.equals("timer-delay", Thread.readMessage(false));
	}

	@:describe("Sys")
	@:test
	function testSysPortableEnvironmentAndProcessContracts():Void {
		var environmentKey = "REFLAXE_ELIXIR_SYS_RUNTIME_TEST";
		var previousValue = Sys.getEnv(environmentKey);
		Sys.putEnv(environmentKey, "available");
		var directValue = Sys.getEnv(environmentKey);
		var snapshotValue = Sys.environment().get(environmentKey);
		Sys.putEnv(environmentKey, null);
		var removedValue = Sys.getEnv(environmentKey);
		if (previousValue != null) {
			Sys.putEnv(environmentKey, previousValue);
		}

		Assert.equals("available", directValue);
		Assert.equals("available", snapshotValue);
		Assert.isNull(removedValue);

		var originalCwd = Sys.getCwd();
		Sys.setCwd(originalCwd);
		Assert.equals(originalCwd, Sys.getCwd());
		Assert.isTrue(Sys.args().length >= 0);

		var beforeSleep = Sys.time();
		Sys.sleep(0.01);
		Assert.isTrue(Sys.time() > beforeSleep);
		Assert.isTrue(Sys.cpuTime() >= 0);

		var systemName = Sys.systemName();
		Assert.isTrue(["BSD", "Linux", "Mac", "Windows"].indexOf(systemName) >= 0);
		var command = systemName == "Windows" ? "cmd" : "sh";
		var commandArgs = systemName == "Windows" ? ["/d", "/s", "/c", "exit /b 7"] : ["-c", "exit 7"];
		Assert.equals(7, Sys.command(command, commandArgs));
		Assert.equals(9, Sys.command(systemName == "Windows" ? "exit /b 9" : "exit 9"));
		Assert.isFalse(Sys.setTimeLocale("reflaxe-elixir-unavailable-locale"));
	}

	@:describe("Sys")
	@:test
	function testSysCommandForwardsOutput():Void {
		var systemName = Sys.systemName();
		var directCommand = systemName == "Windows" ? "cmd" : "sh";
		var directArgs = systemName == "Windows" ? ["/d", "/s", "/c", "echo direct-output"] : ["-c", "printf direct-output"];
		var directOutput = ExUnitCaptureIO.capture(function() {
			Assert.equals(0, Sys.command(directCommand, directArgs));
		});
		Assert.equals(systemName == "Windows" ? "direct-output\r\n" : "direct-output", directOutput);

		var shellOutput = ExUnitCaptureIO.capture(function() {
			Assert.equals(0, Sys.command(systemName == "Windows" ? "echo shell-output" : "printf shell-output"));
		});
		Assert.equals(systemName == "Windows" ? "shell-output\r\n" : "shell-output", shellOutput);
	}

	@:describe("Sys")
	@:test
	function testSysStandardStreamsAndCharacters():Void {
		var inputOutput = ExUnitCaptureIO.captureWithInput("abc\n", function() {
			var input = Sys.stdin();
			Assert.equals("a".charCodeAt(0), input.readByte());
			Assert.equals("bc", input.readLine());
			input.close();
		});
		Assert.equals("", inputOutput);

		var stdout = ExUnitCaptureIO.capture(function() {
			var output = Sys.stdout();
			output.writeString("standard-output");
			output.writeByte(10);
			output.flush();
			output.close();
		});
		Assert.equals("standard-output\n", stdout);

		var stderr = ExUnitCaptureIO.captureDevice(reflaxe.elixir.runtime.StandardIODevice.StandardError, function() {
			var output = Sys.stderr();
			output.writeString("standard-error");
			output.close();
		});
		Assert.isTrue(stderr.indexOf("standard-error") >= 0);

		var silentCharacter = ExUnitCaptureIO.captureWithInput("é", function() {
			Assert.equals("é".charCodeAt(0), Sys.getChar(false));
		});
		Assert.equals("", silentCharacter);

		var echoedCharacter = ExUnitCaptureIO.captureWithInput("Z", function() {
			Assert.equals("Z".charCodeAt(0), Sys.getChar(true));
		});
		Assert.equals("Z", echoedCharacter);
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
		Assert.equals(0, hex.encodeBytes(Bytes.alloc(0)).length);
		Assert.equals(0, hex.decodeBytes(Bytes.alloc(0)).length);
		Assert.equals("", hex.encodeString(""));
		Assert.equals("", hex.decodeString(""));

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

/** Test-only access to ExUnit's process-local IO capture boundary. */
@:native("ExUnit.CaptureIO")
extern class ExUnitCaptureIO {
	@:native("capture_io")
	static function capture(callback:() -> Void):String;

	@:native("capture_io")
	static function captureWithInput(input:String, callback:() -> Void):String;

	@:native("capture_io")
	static function captureDevice(device:reflaxe.elixir.runtime.StandardIODevice, callback:() -> Void):String;
}

/**
 * Bounded test server for the public HTTP client contract.
 * Raw BEAM TCP is isolated here because Haxe has no HTTP server test API.
 * The server accepts one request and applies five-second accept and receive limits.
 */
@:noCompletion
class HttpContractServer {
	public static function start(expectedMethod:String, expectedNeedle:String, status:Int, responseBody:String):Int {
		return startWithNeedles(expectedMethod, [expectedNeedle], status, responseBody);
	}

	public static function startWithNeedles(expectedMethod:String, expectedNeedles:Array<String>, status:Int, responseBody:String):Int {
		return untyped __elixir__('
            (fn ->
              {:ok, listener} =
                :gen_tcp.listen(0, [
                  :binary,
                  {:active, false},
                  {:packet, :raw},
                  {:reuseaddr, true},
                  {:ip, {127, 0, 0, 1}}
                ])

              {:ok, {{127, 0, 0, 1}, port}} = :inet.sockname(listener)

              spawn(fn ->
                case :gen_tcp.accept(listener, 5_000) do
                  {:ok, socket} ->
                    read_until_expected = fn read_until_expected, received ->
                      if Enum.all?({1}, fn needle -> String.contains?(received, needle) end) do
                        {:ok, received}
                      else
                        case :gen_tcp.recv(socket, 0, 5_000) do
                          {:ok, chunk} -> read_until_expected.(read_until_expected, received <> chunk)
                          {:error, _reason} -> {:ok, received}
                        end
                      end
                    end

                    case read_until_expected.(read_until_expected, "") do
                      {:ok, request} ->
                        request_ok =
                          String.starts_with?(request, {0} <> " ") and
                            Enum.all?({1}, fn needle -> String.contains?(request, needle) end)

                        actual_status = if request_ok, do: {2}, else: 500
                        body = if request_ok, do: {3}, else: "server request mismatch"
                        reason = if actual_status >= 400, do: "ERROR", else: "OK"
                        crlf = <<13, 10>>

                        response =
                          "HTTP/1.1 #{actual_status} #{reason}" <> crlf <>
                            "content-type: text/plain" <> crlf <>
                            "x-test: one" <> crlf <>
                            "x-test: two" <> crlf <>
                            "content-length: #{byte_size(body)}" <> crlf <>
                            crlf <>
                            body

                        :ok = :gen_tcp.send(socket, response)
                        :gen_tcp.close(socket)

                      {:error, _reason} ->
                        :gen_tcp.close(socket)
                    end

                  {:error, _reason} ->
                    :ok
                end

                :gen_tcp.close(listener)
              end)

              port
            end).()
        ', expectedMethod, expectedNeedles, status, responseBody);
	}
}
