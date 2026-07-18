package elixir.mix;

import elixir.types.KeywordList;
import elixir.types.Term;

/** Type-safe externs for Mix project configuration. */
@:native("Mix.Project")
extern class Project {
	static function config():KeywordList<Term>;

	@:native("project_file")
	static function projectFile():Null<String>;
}
