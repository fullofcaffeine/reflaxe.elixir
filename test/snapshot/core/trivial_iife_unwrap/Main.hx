import elixir.IO;
import elixir.Path;
import elixir.types.Term;

typedef PackageRoot = {
	var absolute:String;
}

typedef RepeatedPair = {
	var _0:String;
	var _1:String;
}

class Main {
	public static function packageJson(packageRoot:PackageRoot):String {
		return Path.joinTwo(packageRoot.absolute, "package.json");
	}

	public static function preserveBindingScope(value:String):String {
		return identity({
			var decorated = value + "!";
			IO.puts(decorated);
			decorated;
		});
	}

	public static function preserveRemoteCallScope(value:String):Term {
		return IO.puts({
			var decorated = value + "?";
			IO.puts(decorated);
			decorated;
		});
	}

	public static function preserveFunctionVariableScope(value:String):String {
		final callback = identity;
		return callback({
			var decorated = value + ".";
			IO.puts(decorated);
			decorated;
		});
	}

	public static function preserveRepeatedTupleValue(value:String):RepeatedPair {
		return identityPair(duplicate(observe(value)));
	}

	public static function preserveTupleArgumentOrder(first:String, second:String):RepeatedPair {
		return identityPair(reverse(observe(first), observe(second)));
	}

	static inline function duplicate(value:String):RepeatedPair {
		return {_0: value, _1: value};
	}

	static inline function reverse(first:String, second:String):RepeatedPair {
		return {_0: second, _1: first};
	}

	static function observe(value:String):String {
		IO.puts(value);
		return value;
	}

	static function identityPair(value:RepeatedPair):RepeatedPair {
		return value;
	}

	static function identity(value:String):String {
		return value;
	}
}
