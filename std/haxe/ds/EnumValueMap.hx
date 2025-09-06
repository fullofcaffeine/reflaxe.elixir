/*
 * Copyright (C)2005-2019 Haxe Foundation
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

package haxe.ds;

/**
	EnumValueMap allows mapping of enum value keys to arbitrary values.

	Keys are compared by value and recursively over their parameters. If any
	parameter is not an enum value, `Reflect.compare` is used to compare them.
	
	This is a custom implementation for Reflaxe.Elixir that uses the Type module
	instead of native EnumValue methods.
**/
class EnumValueMap<K:EnumValue, V> extends haxe.ds.BalancedTree<K, V> implements haxe.Constraints.IMap<K, V> {
	override function compare(k1:EnumValue, k2:EnumValue):Int {
		// Compare enum indices first
		var d = Type.enumIndex(k1) - Type.enumIndex(k2);
		if (d != 0)
			return d;
		
		// Then compare parameters
		var p1 = Type.enumParameters(k1);
		var p2 = Type.enumParameters(k2);
		
		var ld = p1.length - p2.length;
		if (ld != 0)
			return ld;
			
		if (p1.length == 0 && p2.length == 0)
			return 0;
			
		// Compare each parameter
		return compareArgs(p1, p2);
	}

	function compareArgs(a1:Array<Dynamic>, a2:Array<Dynamic>):Int {
		for (i in 0...a1.length) {
			var d = compareArg(a1[i], a2[i]);
			if (d != 0)
				return d;
		}
		return 0;
	}

	function compareArg(v1:Dynamic, v2:Dynamic):Int {
		// Try to compare as enum values first
		if (Reflect.isEnumValue(v1) && Reflect.isEnumValue(v2)) {
			return compare(v1, v2);
		}
		// Otherwise use Reflect.compare
		return Reflect.compare(v1, v2);
	}

	/**
		See `Map.keys`
	**/
	override public inline function keys():Iterator<K> {
		return cast iterator();
	}

	// keyValueIterator is already implemented as inline in BalancedTree

	/**
		See `Map.copy`
	**/
	override public function copy():EnumValueMap<K, V> {
		var copied = new EnumValueMap();
		for (k in keys())
			copied.set(k, get(k));
		return copied;
	}

	/**
		See `Map.toString`
	**/
	override public function toString():String {
		var s = new StringBuf();
		s.add("[");
		var it = keys();
		for (i in it) {
			s.add(Std.string(i));
			s.add(" => ");
			s.add(Std.string(get(i)));
			if (it.hasNext())
				s.add(", ");
		}
		s.add("]");
		return s.toString();
	}
}