/**
 * A Haxe enum is a non-class module type.
 *
 * The warm-server regression adds a constructor here and verifies that the
 * generated Elixir enum module is refreshed instead of left stale.
 */
enum CacheStatus {
	Ready;
	Waiting;
}
