package elixir.mix;

import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.Term;

/** Type-safe externs for Mix project configuration. */
@:native("Mix.Project")
extern class Project {
	static function config():KeywordList<Term>;

	/** Resolved dependency application names mapped to their checkout directories. */
	@:native("deps_paths")
	static function depsPaths():Term;

	/** Load one project with configuration merged before its module is pushed. */
	@:native("in_project")
	static function inProject<T>(app:Atom, path:String, postConfig:KeywordList<Term>, callback:Term->T):T;

	@:native("project_file")
	static function projectFile():Null<String>;
}
