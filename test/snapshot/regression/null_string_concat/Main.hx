/**
 * Regression for haxe.elixir.codex-623: a null operand of a string
 * concatenation prints as the text `null`, as the Haxe interpreter prints it.
 *
 * Every value reaches its function as a parameter, so neither Haxe nor the
 * compiler can fold it at compile time. `expected.stdout` is the output of
 * `haxe -cp . -main Main --interp`.
 */
typedef Same<T> = T;
typedef Alias<T> = Same<T>;
typedef Outer<T> = Alias<T>;

@:keep
class Main {
	static function main():Void {
		// Null<String>, the reported case: right side, left side, interpolation.
		Sys.println(nullableRight(null));
		Sys.println(nullableRight("s"));
		Sys.println(nullableLeft(null));
		Sys.println(nullableLeft("s"));
		Sys.println(nullableInterpolated(null));
		Sys.println(nullableInterpolated("s"));
		Sys.println(nullableOnly(null));

		// A plain String keeps the direct form.
		Sys.println(plainRight("s"));
		Sys.println(plainLeft("s"));
		Sys.println(plainInterpolated("a", "b"));

		// Dynamic and other nullable types already printed `null`; keep them so.
		Sys.println(dynamicBoth(null));
		Sys.println(dynamicBoth(7));
		Sys.println(dynamicInterpolated(null));
		Sys.println(nullableNumber(null));
		Sys.println(nullableNumber(3));
		Sys.println(nullableFlag(null));

		// Other places that concatenate.
		Sys.println(append("log", null));
		Sys.println(append("log", ":x"));
		Sys.println(appendTo(null, "tail"));
		Sys.println(fieldValue(new Label(null)));
		Sys.println(fieldValue(new Label("named")));
		Sys.println(optional());
		Sys.println(optional("given"));
		Sys.println(missingKey(["k" => "v"], "other"));
		Sys.println(missingKey(["k" => "v"], "k"));
		Sys.println(literalNull());
		Sys.println(chain(null, "b", null));
		Sys.println(chain("a", "b", 1));

		// A generic alias keeps its type argument through two and three levels.
		Sys.println(twoLevelAlias(null));
		Sys.println(twoLevelAlias("v"));
		Sys.println(threeLevelAlias(null));
		Sys.println(threeLevelAlias("v"));
		Sys.println(aliasOfPlain("v"));

		// Values that cannot be null stay unchanged.
		Sys.println(nonNull(false, 5));
		Sys.println(nonNull(true, 6));

		// Std.string and trace keep their Haxe output.
		Sys.println(Std.string(null));
		Sys.println(stdString(null));
		trace(nullableRight(null));
	}

	public static function nullableRight(value:Null<String>):String {
		return "x/" + value;
	}

	public static function nullableLeft(value:Null<String>):String {
		return value + "/x";
	}

	public static function nullableInterpolated(value:Null<String>):String {
		return 'x/$value/${value}';
	}

	public static function nullableOnly(value:Null<String>):String {
		return '$value';
	}

	public static function plainRight(value:String):String {
		return "x/" + value;
	}

	public static function plainLeft(value:String):String {
		return value + "/x";
	}

	public static function plainInterpolated(first:String, second:String):String {
		return '<$first|$second>';
	}

	public static function dynamicBoth(value:Dynamic):String {
		return ("x/" + value) + "|" + (value + "/x");
	}

	public static function dynamicInterpolated(value:Dynamic):String {
		return 'x/$value';
	}

	public static function nullableNumber(value:Null<Int>):String {
		return "n=" + value + "|" + (value + "=n");
	}

	public static function nullableFlag(value:Null<Bool>):String {
		return 'flag=$value';
	}

	public static function append(text:String, suffix:Null<String>):String {
		text += suffix;
		return text;
	}

	public static function appendTo(text:Null<String>, suffix:String):String {
		text += suffix;
		return text;
	}

	public static function fieldValue(label:Label):String {
		return "name=" + label.name;
	}

	public static function optional(?value:String):String {
		return "optional=" + value;
	}

	public static function missingKey(values:Map<String, String>, key:String):String {
		return "value=" + values.get(key);
	}

	public static function literalNull():String {
		return "literal=" + null;
	}

	public static function chain(first:Null<String>, second:String, third:Dynamic):String {
		return "a/" + first + "/" + second + "/" + third;
	}

	public static function twoLevelAlias(value:Alias<Null<String>>):String {
		return "a/" + value;
	}

	public static function threeLevelAlias(value:Outer<Null<String>>):String {
		return value + "/c";
	}

	public static function aliasOfPlain(value:Alias<String>):String {
		return "p/" + value;
	}

	public static function nonNull(flag:Bool, count:Int):String {
		return "count=" + Std.string(count) + ("/" + "part") + (flag ? "/yes" : "/no");
	}

	public static function stdString(value:Null<String>):String {
		return Std.string(value);
	}
}

/** Holds a text field that can be null. */
class Label {
	public var name:Null<String>;

	public function new(name:Null<String>) {
		this.name = name;
	}
}
