package elixir.mix;

import elixir.types.Atom;

/** Mix's installed archives and configured code paths for standalone workers. */
@:native("Mix.Local")
extern class Local {
	/** Make installed archives, including Hex, available to Mix tasks. */
	@:native("append_archives")
	static function appendArchives():Atom;

	/** Load paths configured through MIX_PATH, as the Mix CLI does. */
	@:native("append_paths")
	static function appendPaths():Atom;
}
