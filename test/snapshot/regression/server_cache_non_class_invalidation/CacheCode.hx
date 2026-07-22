/**
 * A zero-runtime-cost Haxe view over an integer.
 *
 * The warm-server regression changes only this inline method. `Main.hx` must
 * then be retyped so its generated Elixir uses the new operation.
 */
abstract CacheCode(Int) from Int to Int {
	public inline function render():Int {
		return this + 1;
	}
}
