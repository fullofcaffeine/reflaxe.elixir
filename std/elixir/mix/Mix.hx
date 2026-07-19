package elixir.mix;

import elixir.types.Atom;
import elixir.types.Term;

/** Type-safe access to the active Mix shell. */
@:native("Mix")
extern class Mix {
	/** Start Mix in a standalone BEAM process. */
	static function start():Term;

	static function shell():Shell;

	@:native("ensure_application!")
	static function ensureApplicationBang(application:Atom):Atom;
}
