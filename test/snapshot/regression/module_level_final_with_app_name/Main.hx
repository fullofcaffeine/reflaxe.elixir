import rules.Tags;

/**
 * Regression for haxe.elixir.codex-yq6: a module-level `final` that a function of
 * the same Haxe module reads, in a build that sets `-D app_name`.
 *
 * The module-level fields of `rules/Tags.hx` become the Elixir module
 * `Tags_Fields_`. The read of the value must call that module, not
 * `FixtureApp.Tags_Fields_`, which does not exist. `runtime.exs` checks natively.
 */
@:keep
class Main {
	static final limit = 3;

	static function main():Void {}

	/** Reads the module-level value from another module. */
	public static function isPrivateTag(tag:String):Bool
		return isPrivate(tag);

	/** Reads a static value of its own class. */
	public static function underLimit(count:Int):Bool
		return count < limit;
}
