import elixir.IO;
import elixir.Path;
import elixir.types.Term;

typedef PackageRoot = {
	var absolute:String;
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

	static function identity(value:String):String {
		return value;
	}
}
