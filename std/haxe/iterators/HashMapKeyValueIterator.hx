/*
 * Copyright (C)2005-2025 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package haxe.iterators;

import haxe.ds.HashMap;

/**
 * HashMapKeyValueIterator (Elixir target)
 *
 * WHAT
 * - Type-compatible iterator surface for explicit
 *   `new haxe.iterators.HashMapKeyValueIterator(map)` usage.
 *
 * WHY
 * - `haxe.ds.HashMap` is a BEAM-specific immutable receiver override.
 * - The upstream iterator shape is useful at Haxe type-checking time, but
 *   generated Elixir must keep using the target HashMap's supported
 *   `keys()`/`get()` runtime path instead of emitting a separate iterator
 *   module coupled to upstream HashMap internals.
 *
 * HOW
 * - Delegate to `map.keys()` and `map.get(key)` instead of reaching into
 *   upstream HashMap internals.
 * - The emitted module is intentionally tiny and uses the closure-backed
 *   iterator returned by the target HashMap override.
 *
 * EXAMPLES
 * ```haxe
 * var iterator = new HashMapKeyValueIterator(map);
 * while (iterator.hasNext()) {
 *   var pair = iterator.next();
 * }
 * ```
 */
class HashMapKeyValueIterator<K:{function hashCode():Int;}, V> {
	final map:HashMap<K, V>;
	final keys:Iterator<K>;

	public function new(map:HashMap<K, V>) {
		this.map = map;
		this.keys = map.keys();
	}

	public function hasNext():Bool {
		return keys.hasNext();
	}

	public function next():{key:K, value:V} {
		var key = keys.next();
		return {key: key, value: map.get(key)};
	}
}
