/**
 * IntIterator (Elixir target)
 *
 * WHAT
 * - Implements Haxe stdlib `IntIterator`, used by interval syntax: `min...max`.
 *
 * WHY
 * - Some code uses `IntIterator` explicitly, and the type is part of the std surface.
 *
 * HOW
 * - Mirrors Haxe std behavior: iterates from `min` (inclusive) to `max` (exclusive).
 */
class IntIterator {
    var min: Int;
    var max: Int;

    /**
     * Iterates from `min` (inclusive) to `max` (exclusive).
     *
     * If `max <= min`, the iterator will not act as a countdown.
     */
    public inline function new(min: Int, max: Int) {
        this.min = min;
        this.max = max;
    }

    /**
     * Returns true if the iterator has other items, false otherwise.
     */
    public inline function hasNext(): Bool {
        return min < max;
    }

    /**
     * Moves to the next item of the iterator.
     *
     * If this is called while hasNext() is false, the result is unspecified.
     */
    public inline function next(): Int {
        return min++;
    }
}

