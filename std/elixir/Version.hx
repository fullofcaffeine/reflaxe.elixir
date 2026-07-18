package elixir;

#if (macro || reflaxe_runtime || elixir)
/** Typed access to Elixir semantic-version requirements. */
@:native("Version")
extern class Version {
	@:native("match?")
	public static function matches(version:String, requirement:String):Bool;
}
#end
