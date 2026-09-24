/**
 * Test reserved keyword parameter handling
 * 
 * This test ensures that Elixir reserved keywords used as function parameters
 * are properly escaped with a suffix (e.g., "end" becomes "end_param").
 * 
 * Fixed in commit: db85ccd
 */
class Main {
	static function main() {
		if (KeywordMethods.or(4, 7) != 11)
			throw "Reserved method direct call must reach its declaration";
		final captured = KeywordMethods.or;
		if (captured(2, 3) != 5)
			throw "Reserved method capture must match direct calls";
		// Test Elixir reserved keywords that Haxe allows as parameters
		// Note: Some keywords like "do", "if", "else", "case", "import" are also Haxe keywords
		testEnd("hello", "world");
		testAfter(100);
		testRescue("exception");
		testDef("definition");
		testDefp("private");
		testDefmodule("MyModule");
		testAlias("MyAlias");
		testReceive("message");
		testQuote("expression");
		testUnquote("value");
		testRequire("library");
		testUse("framework");

		// Test multiple reserved keywords
		testMultiple("start", "middle", "result");
		localKeywordArrays();
	}

	/** Local declarations must use the same escaped names as their reads and writes. */
	public static function localKeywordArrays():Int {
		final after:Array<Int> = [];
		final end:Array<Int> = [];
		final rescue:Array<Int> = [];

		after.push(1);
		end.push(2);
		rescue.push(3);

		return after.length + end.length + rescue.length;
	}

	// Functions with Elixir reserved keyword parameters (that Haxe allows)
	static function testEnd(start:String, end:String):String {
		return start + " to " + end;
	}

	static function testAfter(after:Int):Int {
		return after + 1;
	}

	static function testRescue(rescue:String):String {
		return "rescued: " + rescue;
	}

	static function testDef(def:String):String {
		return "def: " + def;
	}

	static function testDefp(defp:String):String {
		return "defp: " + defp;
	}

	static function testDefmodule(defmodule:String):String {
		return "module: " + defmodule;
	}

	static function testAlias(alias:String):String {
		return "alias: " + alias;
	}

	static function testReceive(receive:String):String {
		return "received: " + receive;
	}

	static function testQuote(quote:String):String {
		return "quoted: " + quote;
	}

	static function testUnquote(unquote:String):String {
		return "unquoted: " + unquote;
	}

	static function testRequire(require:String):String {
		return "required: " + require;
	}

	static function testUse(use:String):String {
		return "using: " + use;
	}

	// Test multiple reserved keywords in one function
	static function testMultiple(start:String, end:String, after:String):String {
		return start + " -> " + end + " (after: " + after + ")";
	}
}

/** Ordinary Haxe method names can coincide with Elixir operators. */
class KeywordMethods {
	public static function or(left:Int, right:Int):Int {
		return left + right;
	}
}
