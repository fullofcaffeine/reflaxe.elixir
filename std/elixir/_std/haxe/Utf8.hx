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

package haxe;

import haxe.exceptions.NotImplementedException;
import haxe.iterators.StringIteratorUnicode;

/**
 * UTF-8 compatibility API for the Elixir target.
 *
 * BEAM strings are UTF-8 binaries, so character operations use Unicode
 * codepoint positions. The legacy ISO-to-UTF-8 transcoding methods remain
 * unsupported, as they are in Haxe's generic Unicode-target implementation.
 */
@:deprecated('haxe.Utf8 is deprecated. Use UnicodeString instead.')
class Utf8 {
	var buffer:String;

	public function new(?size:Int) {
		buffer = "";
	}

	public inline function addChar(code:Int):Void {
		buffer += String.fromCharCode(code);
	}

	public inline function toString():String {
		return buffer;
	}

	public static function iter(value:String, callback:Int->Void):Void {
		var iterator = new StringIteratorUnicode(value);
		while (iterator.hasNext()) {
			callback(iterator.next());
		}
	}

	public static function encode(value:String):String {
		throw new NotImplementedException();
	}

	public static function decode(value:String):String {
		throw new NotImplementedException();
	}

	public static inline function charCodeAt(value:String, index:Int):Int {
		var code = StringTools.haxeCharCodeAt(value, index);
		if (code == null)
			throw "haxe.Utf8.charCodeAt: index out of bounds";
		return code;
	}

	public static inline function validate(value:String):Bool {
		return untyped __elixir__('String.valid?({0})', value);
	}

	public static inline function length(value:String):Int {
		return untyped __elixir__('String.length({0})', value);
	}

	public static function compare(left:String, right:String):Int {
		return left > right ? 1 : (left == right ? 0 : -1);
	}

	public static inline function sub(value:String, position:Int, length:Int):String {
		return StringTools.haxeSubstr(value, position, length);
	}
}
