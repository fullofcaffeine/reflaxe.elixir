package;

/**
 * An Ecto query binding `[t]` next to a lambda argument whose name is `t` plus a digit.
 *
 * The Ecto macro binds `t`, so the compiler sees no binder for it. LocalVarReferenceFix
 * must not treat `t` as a drifted spelling of the lambda argument `t2` and rewrite the
 * query to `[t2], t2.name` (`haxe.elixir.codex-hhp5`). The intended output keeps `[t]`.
 *
 * The query is written with `__elixir__`, as in `typed_query_basic`, because the raw
 * macro binding is the boundary under test.
 */
class Main {
	public static function main() {
		lambdaArgT2();
	}

	public static function lambdaArgT2() {
		var query = untyped __elixir__('Ecto.Query.from(u in "users")');
		var filterVal = "alice";
		var q2 = untyped __elixir__('Ecto.Query.where({0}, [t], t.name == ^({1}))', query, filterVal);
		var xs = [1, 2, 3].map(function(t2) return t2 + 1);
		trace(xs);
		untyped __elixir__('{0}', q2);
	}
}
