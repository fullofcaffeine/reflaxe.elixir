package;

import elixir.types.Term;

@:native("Mix")
extern class MixHost {
	static function shell():MixShell;
}

@:elixirModuleRef
extern class MixShell {
	@:native("info")
	function info(message:String):Void;
}

/**
 * Reports compiler status from a Haxe-authored Mix task.
 */
@:mixTask({
	shortdoc: "Reports compiler status",
	requirements: ["app.config"]
})
@:native("Mix.Tasks.Haxe.Example")
class Main {
	public static function run(args:Array<String>):Int {
		MixHost.shell().info("Running Haxe-authored Mix task");
		return args.length;
	}

	public static function enabled(value:Term):Bool {
		return value == true;
	}

	public static function greeting(name:String = "world"):String {
		return name;
	}

	static function localGreeting(name:String = "world"):String {
		return name;
	}

	public static function defaultGreeting():String {
		return greeting() + localGreeting();
	}
}
