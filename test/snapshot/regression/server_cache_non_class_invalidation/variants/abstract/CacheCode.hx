/** Variant B: changing only the inline abstract body must invalidate its caller. */
abstract CacheCode(Int) from Int to Int {
	public inline function render():Int {
		return this * 2;
	}
}
