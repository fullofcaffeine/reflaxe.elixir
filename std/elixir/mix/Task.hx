package elixir.mix;

import elixir.types.Atom;
import elixir.types.Term;

/** Type-safe execution of already installed Mix tasks. */
@:native("Mix.Task")
extern class Task {
	static function reenable(name:String):Term;
	static function run(name:String, args:Array<String>):Term;
}
