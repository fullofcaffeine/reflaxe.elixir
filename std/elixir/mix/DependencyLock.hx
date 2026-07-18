package elixir.mix;

import elixir.types.Term;

/** Type-safe access to Mix's canonical lockfile reader. */
@:native("Mix.Dep.Lock")
extern class DependencyLock {
	static function read(path:String):Term;
}
