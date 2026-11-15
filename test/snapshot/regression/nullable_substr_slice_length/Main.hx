/**
 * Regression for haxe.elixir.codex-623: a null `Null<Int>` length or end index
 * means "to the end" in `String.substr` and `Array.slice`. A generic typedef
 * alias of a nullable type, such as `Alias<Dynamic>`, counts as nullable too.
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
		Sys.println(nullableLength("abcdef", 1, null));
		Sys.println(nullableLength("abcdef", 1, 2));
		Sys.println(nullableEnd([1, 2, 3, 4], 1, null).join(","));
		Sys.println(nullableEnd([1, 2, 3, 4], 1, 3).join(","));

		// A plain Int cannot be null, so these keep the direct form.
		Sys.println(plainLength("abcdef", 1, 2));
		Sys.println(plainEnd([1, 2, 3, 4], 1, 3).join(","));

		// A generic alias keeps its type argument through two and three levels.
		Sys.println(twoLevelLength("abcdef", 1, null));
		Sys.println(twoLevelLength("abcdef", 1, 2));
		Sys.println(threeLevelLength("abcdef", 1, null));
		Sys.println(twoLevelEnd([1, 2, 3, 4], 1, null).join(","));
		Sys.println(threeLevelEnd([1, 2, 3, 4], 1, null).join(","));
		Sys.println(threeLevelEnd([1, 2, 3, 4], 1, 3).join(","));
		Sys.println(aliasOfPlainLength("abcdef", 1, 2));
	}

	public static function nullableLength(text:String, start:Int, length:Null<Int>):String {
		return text.substr(start, length);
	}

	public static function nullableEnd(values:Array<Int>, start:Int, end:Null<Int>):Array<Int> {
		return values.slice(start, end);
	}

	public static function plainLength(text:String, start:Int, length:Int):String {
		return text.substr(start, length);
	}

	public static function plainEnd(values:Array<Int>, start:Int, end:Int):Array<Int> {
		return values.slice(start, end);
	}

	public static function twoLevelLength(text:String, start:Int, length:Alias<Dynamic>):String {
		return text.substr(start, length);
	}

	public static function threeLevelLength(text:String, start:Int, length:Outer<Null<Int>>):String {
		return text.substr(start, length);
	}

	public static function twoLevelEnd(values:Array<Int>, start:Int, end:Alias<Null<Int>>):Array<Int> {
		return values.slice(start, end);
	}

	public static function threeLevelEnd(values:Array<Int>, start:Int, end:Outer<Dynamic>):Array<Int> {
		return values.slice(start, end);
	}

	public static function aliasOfPlainLength(text:String, start:Int, length:Alias<Int>):String {
		return text.substr(start, length);
	}
}
