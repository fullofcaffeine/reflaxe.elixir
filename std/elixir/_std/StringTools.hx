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

/**
 * StringTools implementation for Elixir target
 * 
 * WHY: Provide idiomatic Elixir code generation for string operations
 * WHAT: Replaces Haxe's default StringTools with Elixir-optimized version
 * HOW: Pure Haxe implementation that generates clean Elixir code
 * 
 * NOTE:
 * - `StringTools` is used by macros at Haxe compile-time (macro context).
 * - For functions that benefit from native Elixir implementations at runtime, we use
 *   `#if macro` to keep a pure-Haxe version for macro evaluation, and `#else` to
 *   inject idiomatic Elixir via `__elixir__()` for the Elixir target runtime.
 */
class StringTools {
	/**
	 * UTF-16 surrogate code point constants
	 */
	public static inline var MIN_SURROGATE_CODE_POINT = 0xD800;

	public static inline var MAX_SURROGATE_CODE_POINT = 0xDFFF;
	public static inline var MIN_HIGH_SURROGATE_CODE_POINT = 0xD800;
	public static inline var MAX_HIGH_SURROGATE_CODE_POINT = 0xDBFF;
	public static inline var MIN_LOW_SURROGATE_CODE_POINT = 0xDC00;
	public static inline var MAX_LOW_SURROGATE_CODE_POINT = 0xDFFF;

	/**
	 * Encode an URL by using the standard format.
	 */
	public static function urlEncode(s:String):String {
		// Basic URL encoding implementation
		var result = "";
		for (i in 0...s.length) {
			var c = fastCodeAt(s, i);
			if ((c >= 65 && c <= 90)
				|| // A-Z
				(c >= 97 && c <= 122)
				|| // a-z
				(c >= 48 && c <= 57)
				|| // 0-9
				c == 45
				|| c == 95
				|| c == 46
				|| c == 126) { // - _ . ~
				result += haxeCharAt(s, i);
			} else {
				result += "%" + hex(c, 2);
			}
		}
		return result;
	}

	/**
	 * Decode an URL using the standard format.
	 */
	public static function urlDecode(s:String):String {
		#if macro
		var result = "";
		var i = 0;
		while (i < s.length) {
			var c = s.charAt(i);
			if (c == "%") {
				if (i + 2 < s.length) {
					var hex = s.substr(i + 1, 2);
					var code = parseInt("0x" + hex);
					if (code != null) {
						result += String.fromCharCode(code);
						i += 3;
						continue;
					}
				}
			}
			result += c;
			i++;
		}
		return result;
		#else
		// Elixir: `URI.decode/1` safely percent-decodes and does not treat '+' specially.
		return untyped __elixir__('URI.decode({0})', s);
		#end
	}

	/**
	 * Escape HTML special characters of the string `s`.
	 */
	public static function htmlEscape(s:String, ?quotes:Bool):String {
		s = replace(s, "&", "&amp;");
		s = replace(s, "<", "&lt;");
		s = replace(s, ">", "&gt;");
		if (quotes) {
			s = replace(s, '"', "&quot;");
			s = replace(s, "'", "&#039;");
		}
		return s;
	}

	/**
	 * Unescape HTML special characters of the string `s`.
	 */
	public static function htmlUnescape(s:String):String {
		s = replace(s, "&gt;", ">");
		s = replace(s, "&lt;", "<");
		s = replace(s, "&quot;", '"');
		s = replace(s, "&#039;", "'");
		s = replace(s, "&amp;", "&");
		return s;
	}

	/**
	 * Tells if the string `s` starts with the string `start`.
	 */
	public static function startsWith(s:String, start:String):Bool {
		return s.length >= start.length && haxeSubstr(s, 0, start.length) == start;
	}

	/**
	 * Tells if the string `s` ends with the string `end`.
	 */
	public static function endsWith(s:String, end:String):Bool {
		var elen = end.length;
		var slen = s.length;
		return slen >= elen && haxeSubstr(s, slen - elen, elen) == end;
	}

	/**
	 * Tells if the character in the string `s` at position `pos` is a space.
	 */
	public static function isSpace(s:String, pos:Int):Bool {
		#if macro
		var c = s.charCodeAt(pos);
		return (c > 8 && c < 14) || c == 32;
		#else
		return untyped __elixir__('if {1} < 0 do
  false
else
  case Enum.at(String.to_charlist({0}), {1}) do
    nil -> false
    code -> (code > 8 and code < 14) or code == 32
  end
end', s, pos);
		#end
	}

	/**
	 * Removes leading space characters of `s`.
	 */
	public static function ltrim(s:String):String {
		var l = s.length;
		var r = 0;
		while (r < l && isSpace(s, r)) {
			r++;
		}
		if (r > 0) {
			return haxeSubstr(s, r, l - r);
		} else {
			return s;
		}
	}

	/**
	 * Removes trailing space characters of `s`.
	 */
	public static function rtrim(s:String):String {
		var l = s.length;
		var r = 0;
		while (r < l && isSpace(s, l - r - 1)) {
			r++;
		}
		if (r > 0) {
			return haxeSubstr(s, 0, l - r);
		} else {
			return s;
		}
	}

	/**
	 * Removes leading and trailing space characters of `s`.
	 */
	public static inline function trim(s:String):String {
		return ltrim(rtrim(s));
	}

	/**
	 * Pad `s` by appending `c` at its right until its length is at least `l`.
	 */
	public static function lpad(s:String, c:String, l:Int):String {
		if (c.length <= 0)
			return s;
		var buf = "";
		while (buf.length + s.length < l) {
			buf += c;
		}
		return buf + s;
	}

	/**
	 * Pad `s` by appending `c` at its left until its length is at least `l`.
	 */
	public static function rpad(s:String, c:String, l:Int):String {
		if (c.length <= 0)
			return s;
		var buf = s;
		while (buf.length < l) {
			buf += c;
		}
		return buf;
	}

	/**
	 * Replace all occurrences of the string `sub` in the string `s` with the string `by`.
	 */
	public static function replace(s:String, sub:String, by:String):String {
		// Use split/join pattern for replacement
		return haxeSplit(s, sub).join(by);
	}

	/**
	 * Encode a number into a hexadecimal representation, with an optional number of zeros for left padding.
	 */
	public static function hex(n:Int, ?digits:Int):String {
		#if macro
		var s = "";
		var hexChars = "0123456789ABCDEF";
		do {
			s = hexChars.charAt(n & 15) + s;
			n >>>= 4;
		} while (n > 0);

		if (digits != null) {
			while (s.length < digits) {
				s = "0" + s;
			}
		}
		return s;
		#else
		// Elixir: match Haxe Int semantics (32-bit) via an explicit mask.
		if (digits == null) {
			return untyped __elixir__('Integer.to_string(Bitwise.band({0}, 0xFFFFFFFF), 16) |> String.upcase()', n);
		}
		return untyped __elixir__('Integer.to_string(Bitwise.band({0}, 0xFFFFFFFF), 16) |> String.upcase() |> String.pad_leading({1}, \"0\")', n, digits);
		#end
	}

	/**
	 * Provides fast integer matching for switches on strings
	 */
	public static function fastCodeAt(s:String, index:Int):Int {
		#if macro
		var code = s.charCodeAt(index);
		return code == null ? -1 : code;
		#else
		return untyped __elixir__('case Enum.at(String.to_charlist({0}), {1}) do
  nil -> -1
  code -> code
end', s, index);
		#end
	}

	/**
	 * Returns the character code at `index` without exposing a nullable result.
	 *
	 * Elixir string access is codepoint-indexed in this target. The official
	 * Haxe stdlib uses `unsafeCodeAt` in iterator/parser hot paths after doing
	 * its own bounds checks, so this aliases the target's fast code access.
	 */
	public static function unsafeCodeAt(s:String, index:Int):Int {
		#if macro
		var code = s.charCodeAt(index);
		return code == null ? 0 : code;
		#else
		return untyped __elixir__('case Enum.at(String.to_charlist({0}), {1}) do
  nil -> 0
  code -> code
end', s, index);
		#end
	}

	/**
	 * Returns `true` if `s` contains `value` and `false` otherwise.
	 */
	public static function contains(s:String, value:String):Bool {
		return haxeIndexOf(s, value, 0) != -1;
	}

	/**
	 * Haxe-compatible `String.charAt`.
	 */
	#if !macro
	@:keep
	#end
	@:noCompletion
	public static function haxeCharAt(s:String, index:Int):String {
		#if macro
		return s.charAt(index);
		#else
		return untyped __elixir__('if {1} < 0 do
  ""
else
  String.at({0}, {1}) || ""
end', s, index);
		#end
	}

	/**
	 * Haxe-compatible `String.charCodeAt`.
	 */
	#if !macro
	@:keep
	#end
	@:noCompletion
	public static function haxeCharCodeAt(s:String, index:Int):Null<Int> {
		#if macro
		return s.charCodeAt(index);
		#else
		return untyped __elixir__('if {1} < 0 do
  nil
else
  Enum.at(String.to_charlist({0}), {1})
end', s, index);
		#end
	}

	/**
	 * Haxe-compatible `String.indexOf`, including empty-pattern behavior.
	 */
	#if !macro
	@:keep
	#end
	@:noCompletion
	public static function haxeIndexOf(s:String, value:String, ?startIndex:Int):Int {
		#if macro
		return startIndex == null ? s.indexOf(value) : s.indexOf(value, startIndex);
		#else
		return untyped __elixir__('
(fn ->
  reflaxe_string_source = {0}
  reflaxe_string_value = {1}
  reflaxe_string_length = String.length(reflaxe_string_source)
  reflaxe_string_start = if Kernel.is_nil({2}), do: 0, else: max({2}, 0)

  cond do
    reflaxe_string_value == "" ->
      min(reflaxe_string_start, reflaxe_string_length)
    reflaxe_string_start > reflaxe_string_length ->
      -1
    true ->
      reflaxe_string_slice = String.slice(reflaxe_string_source, reflaxe_string_start, reflaxe_string_length - reflaxe_string_start)
      case :binary.match(reflaxe_string_slice, reflaxe_string_value) do
        {byte_pos, _} -> String.length(binary_part(reflaxe_string_slice, 0, byte_pos)) + reflaxe_string_start
        :nomatch -> -1
      end
  end
end).()
', s, value, startIndex);
		#end
	}

	/**
	 * Haxe-compatible `String.lastIndexOf`, including empty-pattern behavior.
	 */
	#if !macro
	@:keep
	#end
	@:noCompletion
	public static function haxeLastIndexOf(s:String, value:String, ?startIndex:Int):Int {
		#if macro
		return s.lastIndexOf(value, startIndex);
		#else
		return untyped __elixir__('
(fn ->
  reflaxe_string_source = {0}
  reflaxe_string_value = {1}
  reflaxe_string_length = String.length(reflaxe_string_source)
  reflaxe_string_start = if Kernel.is_nil({2}), do: reflaxe_string_length, else: min(max({2}, 0), reflaxe_string_length)

  if reflaxe_string_value == "" do
    reflaxe_string_start
  else
    reflaxe_string_graphemes = String.graphemes(reflaxe_string_source)
    reflaxe_string_needle = String.graphemes(reflaxe_string_value)
    reflaxe_string_needle_length = length(reflaxe_string_needle)

    if reflaxe_string_needle_length > reflaxe_string_length do
      -1
    else
      reflaxe_string_max_start = min(reflaxe_string_start, reflaxe_string_length - reflaxe_string_needle_length)
      Enum.find(reflaxe_string_max_start..0//-1, -1, fn reflaxe_string_index ->
        Enum.slice(reflaxe_string_graphemes, reflaxe_string_index, reflaxe_string_needle_length) == reflaxe_string_needle
      end)
    end
  end
end).()
', s, value, startIndex);
		#end
	}

	/**
	 * Haxe-compatible `String.split`.
	 */
	#if !macro
	@:keep
	#end
	@:noCompletion
	public static function haxeSplit(s:String, delimiter:String):Array<String> {
		#if macro
		return s.split(delimiter);
		#else
		return untyped __elixir__('if {1} == "", do: String.graphemes({0}), else: String.split({0}, {1})', s, delimiter);
		#end
	}

	/**
	 * Haxe-compatible `String.substr`.
	 */
	#if !macro
	@:keep
	#end
	@:noCompletion
	public static function haxeSubstr(s:String, pos:Int, ?len:Int):String {
		#if macro
		return s.substr(pos, len);
		#else
		return untyped __elixir__('
(fn ->
  reflaxe_string_source = {0}
  reflaxe_string_length = String.length(reflaxe_string_source)
  reflaxe_string_start =
    cond do
      {1} < 0 -> max(reflaxe_string_length + {1}, 0)
      {1} > reflaxe_string_length -> reflaxe_string_length
      true -> {1}
    end
  reflaxe_string_count =
    cond do
      Kernel.is_nil({2}) -> reflaxe_string_length - reflaxe_string_start
      {2} < 0 -> max(reflaxe_string_length + {2} - reflaxe_string_start, 0)
      true -> {2}
    end

  String.slice(reflaxe_string_source, reflaxe_string_start, reflaxe_string_count)
end).()
', s, pos, len);
		#end
	}

	/**
	 * Haxe-compatible `String.substr` for calls whose length argument is a concrete `Int`.
	 */
	#if !macro
	@:keep
	#end
	@:noCompletion
	public static function haxeSubstrNonNilLen(s:String, pos:Int, len:Int):String {
		#if macro
		return s.substr(pos, len);
		#else
		return untyped __elixir__('
(fn ->
  reflaxe_string_source = {0}
  reflaxe_string_length = String.length(reflaxe_string_source)
  reflaxe_string_start =
    cond do
      {1} < 0 -> max(reflaxe_string_length + {1}, 0)
      {1} > reflaxe_string_length -> reflaxe_string_length
      true -> {1}
    end
  reflaxe_string_count =
    cond do
      {2} < 0 -> max(reflaxe_string_length + {2} - reflaxe_string_start, 0)
      true -> {2}
    end

  String.slice(reflaxe_string_source, reflaxe_string_start, reflaxe_string_count)
end).()
', s, pos, len);
		#end
	}

	/**
	 * Haxe-compatible `String.substring`.
	 */
	#if !macro
	@:keep
	#end
	@:noCompletion
	public static function haxeSubstring(s:String, startIndex:Int, ?endIndex:Int):String {
		#if macro
		return s.substring(startIndex, endIndex);
		#else
		return untyped __elixir__('
(fn ->
  reflaxe_string_source = {0}
  reflaxe_string_length = String.length(reflaxe_string_source)
  reflaxe_string_start = min(max({1}, 0), reflaxe_string_length)
  reflaxe_string_end = if Kernel.is_nil({2}), do: reflaxe_string_length, else: min(max({2}, 0), reflaxe_string_length)
  reflaxe_string_from = min(reflaxe_string_start, reflaxe_string_end)
  reflaxe_string_count = abs(reflaxe_string_end - reflaxe_string_start)
  String.slice(reflaxe_string_source, reflaxe_string_from, reflaxe_string_count)
end).()
', s, startIndex, endIndex);
		#end
	}

	/**
	 * Returns a codepoint iterator for `s`.
	 */
	@:ifFeature("StringTools.iterator")
	extern inline public static function iterator(s:String):haxe.iterators.StringIterator {
		return untyped __elixir__('StringIterator.new({0})', s);
	}

	/**
	 * Returns a key/value iterator whose keys are character indices and values
	 * are codepoints.
	 */
	@:ifFeature("StringTools.keyValueIterator")
	extern inline public static function keyValueIterator(s:String):haxe.iterators.StringKeyValueIterator {
		return untyped __elixir__('StringKeyValueIterator.new({0})', s);
	}

	/**
	 * Check if a character code represents end of file
	 * Used with character reading functions that return -1 for EOF
	 */
	public static inline function isEof(c:Int):Bool {
		return c < 0;
	}

	/**
	 * Get the UTF-16 code point at the given position
	 * This is a compatibility function for unicode iterators
	 */
	public static function utf16CodePointAt(s:String, index:Int):Int {
		return fastCodeAt(s, index);
	}

	/**
	 * Check if a code point is a high surrogate
	 */
	public static inline function isHighSurrogate(code:Int):Bool {
		return code >= MIN_HIGH_SURROGATE_CODE_POINT && code <= MAX_HIGH_SURROGATE_CODE_POINT;
	}

	/**
	 * Check if a code point is a low surrogate
	 */
	public static inline function isLowSurrogate(code:Int):Bool {
		return code >= MIN_LOW_SURROGATE_CODE_POINT && code <= MAX_LOW_SURROGATE_CODE_POINT;
	}

	/**
	 * Escape special characters in a string for use in a regular expression
	 */
	public static function quoteRegexpMeta(s:String):String {
		// Escape regex special characters
		var specialChars = ["\\", "^", "$", ".", "|", "?", "*", "+", "(", ")", "[", "]", "{", "}"];
		for (char in specialChars) {
			s = replace(s, char, "\\" + char);
		}
		return s;
	}

	/**
	 * Convert a string to an integer value, returning null if not possible
	 */
	public static function parseInt(str:String):Null<Int> {
		#if macro
		// Handle hex numbers
		if (str.substr(0, 2) == "0x") {
			var hex = str.substr(2);
			var result = 0;
			for (i in 0...hex.length) {
				var c = hex.charCodeAt(i);
				result *= 16;
				if (c >= 48 && c <= 57) { // 0-9
					result += c - 48;
				} else if (c >= 65 && c <= 70) { // A-F
					result += c - 65 + 10;
				} else if (c >= 97 && c <= 102) { // a-f
					result += c - 97 + 10;
				} else {
					return null;
				}
			}
			return result;
		}

		// Handle decimal numbers
		var result = 0;
		var negative = false;
		var start = 0;

		if (str.charAt(0) == "-") {
			negative = true;
			start = 1;
		} else if (str.charAt(0) == "+") {
			start = 1;
		}

		for (i in start...str.length) {
			var c = str.charCodeAt(i);
			if (c >= 48 && c <= 57) {
				result = result * 10 + (c - 48);
			} else {
				return null;
			}
		}

		return negative ? -result : result;
		#else
		return untyped __elixir__('
            case {0} do
              <<\"0x\", rest::binary>> ->
                case Integer.parse(rest, 16) do
                  {num, \"\"} -> num
                  _ -> nil
                end
              _ ->
                case Integer.parse({0}) do
                  {num, \"\"} -> num
                  _ -> nil
                end
            end
        ', str);
		#end
	}

	/**
	 * Convert a string to a float value, returning null if not possible
	 */
	public static function parseFloat(str:String):Null<Float> {
		#if macro
		return Std.parseFloat(str);
		#else
		return untyped __elixir__('Reflaxe.Elixir.HaxeFloat.parse({0})', str);
		#end
	}
}
