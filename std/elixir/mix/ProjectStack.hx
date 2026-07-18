package elixir.mix;

import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.Term;

/** Scoped Mix project overrides used while resolving one dependency. */
@:native("Mix.ProjectStack")
extern class ProjectStack {
	@:native("post_config")
	static function postConfig(config:KeywordList<Term>):Term;

	@:native("pop_post_config")
	static function popPostConfig(key:Atom):Term;
}
