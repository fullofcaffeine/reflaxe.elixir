package elixir.mix;

import elixir.types.Atom;

/** Type-safe access to the active Mix shell. */
@:native("Mix")
extern class Mix {
	static function shell():Shell;

	@:native("ensure_application!")
	static function ensureApplicationBang(application:Atom):Atom;
}
