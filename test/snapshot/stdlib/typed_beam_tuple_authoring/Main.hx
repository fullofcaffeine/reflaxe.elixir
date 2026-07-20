import elixir.Keyword;
import elixir.Kernel;
import elixir.OptionParser;
import elixir.OptionParser.OptionSwitchTypes;
import elixir.Tuple;
import elixir.types.KeywordList;
import elixir.types.Term;
import elixir.types.Tuple2;
import elixir.types.Tuple3;
import elixir.types.Tuple4;
import elixir.types.Tuple5;

@:keep
class Main {
	public static function main():Void {
		var pair:Tuple2<String, Int> = Tuple.of2("ready", 3);
		var triple:Tuple3<String, Int, Bool> = Tuple.of3("three", 3, true);
		var quadruple:Tuple4<String, Int, Bool, Float> = Tuple.of4("four", 4, true, 4.5);
		var quintuple:Tuple5<String, Int, Bool, Float, String> = Tuple.of5("five", 5, true, 5.5, "last");
		var legacy:Tuple2<String, Int> = Tuple.make2("legacy", 2);
		var raw:Tuple2<String, Int> = {_0: "raw", _1: 1};

		var matched = switch (raw) {
			case {_0: "raw", _1: value}: value;
			default: -1;
		};

		var parsed = OptionParser.parse([], parserOptions());
		parsed._0 = [];

		consumeTuples(pair, triple, quadruple, quintuple, legacy, raw, matched);
		consumeParsed(parsed.options, parsed.argv, parsed.invalid, parsed._0);
		consumeOptions(complexOptions("demo"));
		consumeOptions(complexOptions(null));
		consumeLength(nullableArgv(parsed));
		consumeLength(nullableArgv(null));
	}

	static function parserOptions():KeywordList<Term> {
		var switches:Array<OptionSwitch> = [
			Keyword.entry("yes", OptionSwitchTypes.BOOLEAN),
			Keyword.entry("package_root", OptionSwitchTypes.STRING)
		];

		return [
			Keyword.entry("strict", switches),
			Keyword.entry("env", [Tuple.of2("MIX_ENV", "prod")])
		];
	}

	static function nullableArgv(parsed:Null<OptionParseResult>):Int {
		return parsed == null ? -1 : parsed.argv.length;
	}

	static function complexOptions(appName:Null<String>):KeywordList<Term> {
		return [Keyword.entry("app_name", appName == null ? null : Kernel.toString(appName))];
	}

	static function consumeTuples(_pair:Tuple2<String, Int>, _triple:Tuple3<String, Int, Bool>, _quadruple:Tuple4<String, Int, Bool, Float>,
		_quintuple:Tuple5<String, Int, Bool, Float, String>, _legacy:Tuple2<String, Int>, _raw:Tuple2<String, Int>, _matched:Int):Void {}

	static function consumeParsed(_options:KeywordList<Term>, _argv:Array<String>, _invalid:Array<InvalidOption>, _raw:KeywordList<Term>):Void {}

	static function consumeOptions(_options:KeywordList<Term>):Void {}

	static function consumeLength(_length:Int):Void {}
}
