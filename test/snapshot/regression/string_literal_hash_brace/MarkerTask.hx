/**
 * Counts its arguments.
 *
 * Usage: mix markers.count #{name}
 *
 * This comment becomes an Elixir heredoc string, where `#{name}` would run as
 * code. It is documentation text, so the compiler must escape it.
 */
@:mixTask({
	shortdoc: "Counts #{name} arguments"
})
@:native("Mix.Tasks.Markers.Count")
class MarkerTask {
	public static function run(args:Array<String>):Int {
		return args.length;
	}
}
