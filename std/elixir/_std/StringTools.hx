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
		return untyped __elixir__('case haxe_char_code_at({0}, {1}) do
  nil -> false
  code -> (code > 8 and code < 14) or code == 32
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
		return untyped __elixir__('case haxe_char_code_at({0}, {1}) do
  nil -> -1
  code -> code
end', s, index);
		#end
	}

	/**
	 * Returns the character code at `index` without exposing a nullable result.
	 *
	 * String positions are codepoints on this target. The official
	 * Haxe stdlib uses `unsafeCodeAt` in iterator/parser hot paths after doing
	 * its own bounds checks, so this aliases the target's fast code access.
	 */
	public static function unsafeCodeAt(s:String, index:Int):Int {
		#if macro
		var code = s.charCodeAt(index);
		return code == null ? 0 : code;
		#else
		return untyped __elixir__('case haxe_char_code_at({0}, {1}) do
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

	#if !macro
	/**
	 * Returns the position index of `s`: the data that finds codepoint N without
	 * a walk from the start of the string.
	 *
	 * WHY: A Haxe string position counts Unicode codepoints. BEAM stores a
	 * string as UTF-8 bytes, where one codepoint takes one to four bytes, so
	 * `s.charCodeAt(i)` must first find the byte where codepoint `i` starts.
	 * A walk for each call makes a `while (i < s.length)` loop quadratic.
	 *
	 * HOW: The index is `:ascii` when every codepoint is one byte, so position
	 * and byte offset are equal. Otherwise it is a tuple that holds the byte
	 * offset of each codepoint, plus the byte size as its last element.
	 * A string of 256 bytes or more keeps its index in the process dictionary
	 * under `:reflaxe_haxe_string_index`, for as long as the same string is
	 * read. Only the last such string is kept. Shorter strings are indexed on
	 * each call, which is cheap and leaves the kept index in place.
	 *
	 * Bytes that are not valid UTF-8 count as one position each.
	 * See `docs/05-architecture/STRING_INDEX_UNITS.md`.
	 */
	@:keep
	@:noCompletion
	public static function haxeUnitIndex(s:String):elixir.types.Term {
		return untyped __elixir__('if byte_size({0}) < 256 do
  haxe_unit_index_build({0})
else
  case Process.get(:reflaxe_haxe_string_index) do
    {^{0}, index} ->
      index
    _ ->
      index = haxe_unit_index_build({0})
      Process.put(:reflaxe_haxe_string_index, {{0}, index})
      index
  end
end', s);
	}

	/** Builds the position index of `s` in one or two passes over its bytes. */
	@:keep
	@:noCompletion
	public static function haxeUnitIndexBuild(s:String):elixir.types.Term {
		return untyped __elixir__('if haxe_ascii_only({0}), do: :ascii, else: :erlang.list_to_tuple(haxe_unit_offsets({0}, 0, []))', s);
	}

	/** True when every byte of `s` is ASCII. Reads eight bytes at a time. */
	@:keep
	@:noCompletion
	public static function haxeAsciiOnly(s:String):Bool {
		return untyped __elixir__('case {0} do
  <<word::64, rest::binary>> when Bitwise.band(word, 0x8080808080808080) == 0 -> haxe_ascii_only(rest)
  <<byte, rest::binary>> when byte < 128 -> haxe_ascii_only(rest)
  <<>> -> true
  _ -> false
end', s);
	}

	/**
	 * Lists the byte offset of each codepoint in `s`, then the offset after the
	 * last one. `offset` is the offset of `s` in the whole string and `found`
	 * holds the earlier offsets, newest first.
	 */
	@:keep
	@:noCompletion
	public static function haxeUnitOffsets(s:String, offset:Int, found:elixir.types.Term):elixir.types.Term {
		return untyped __elixir__('case {0} do
  <<_::utf8, rest::binary>> -> haxe_unit_offsets(rest, {1} + byte_size({0}) - byte_size(rest), [{1} | {2}])
  <<_, rest::binary>> -> haxe_unit_offsets(rest, {1} + 1, [{1} | {2}])
  <<>> -> :lists.reverse([{1} | {2}])
end', s, offset, found);
	}

	/** Returns the number of codepoints in `s`, given its position index. */
	@:keep
	@:noCompletion
	public static function haxeUnitCount(s:String, index:elixir.types.Term):Int {
		return untyped __elixir__('if {1} == :ascii, do: byte_size({0}), else: tuple_size({1}) - 1', s, index);
	}

	/** Returns the byte offset where codepoint `position` starts. `position` must be in `0..count`. */
	@:keep
	@:noCompletion
	public static function haxeUnitOffset(index:elixir.types.Term, position:Int):Int {
		return untyped __elixir__('if {0} == :ascii, do: {1}, else: elem({0}, {1})', index, position);
	}

	/** Returns the codepoint position that holds byte `offset`. Uses a binary search. */
	@:keep
	@:noCompletion
	public static function haxeUnitPosition(index:elixir.types.Term, offset:Int):Int {
		return untyped __elixir__('if {0} == :ascii, do: {1}, else: haxe_unit_search({0}, {1}, 0, tuple_size({0}) - 1)', index, offset);
	}

	/** Finds the last element of `offsets` in `low..high` that is not after byte `offset`. */
	@:keep
	@:noCompletion
	public static function haxeUnitSearch(offsets:elixir.types.Term, offset:Int, low:Int, high:Int):Int {
		return untyped __elixir__('cond do
  {2} >= {3} -> {2}
  elem({0}, div({2} + {3} + 1, 2)) <= {1} -> haxe_unit_search({0}, {1}, div({2} + {3} + 1, 2), {3})
  true -> haxe_unit_search({0}, {1}, {2}, div({2} + {3} + 1, 2) - 1)
end', offsets, offset, low, high);
	}

	/**
	 * Returns up to `count` codepoints of `s` from position `start`. Both are
	 * clamped to the end of the string; `start` must not be negative.
	 */
	@:keep
	@:noCompletion
	public static function haxeUnitPart(s:String, index:elixir.types.Term, start:Int, count:Int):String {
		return
			untyped __elixir__('haxe_byte_range({0}, haxe_unit_offset({1}, min({2}, haxe_unit_count({0}, {1}))), haxe_unit_offset({1}, min({2} + max({3}, 0), haxe_unit_count({0}, {1}))))',
			s, index, start, count);
	}

	/** Returns the bytes of `s` from byte offset `from` up to, not including, `to`. */
	@:keep
	@:noCompletion
	public static function haxeByteRange(s:String, from:Int, to:Int):String {
		return untyped __elixir__('binary_part({0}, {1}, {2} - {1})', s, from, to);
	}

	/** Returns the code of the codepoint that starts at byte `offset`, or the byte when it is not valid UTF-8. */
	@:keep
	@:noCompletion
	public static function haxeUnitCode(s:String, offset:Int):Int {
		return untyped __elixir__('case {0} do
  <<_::binary-size({1}), code::utf8, _::binary>> -> code
  _ -> :binary.at({0}, {1})
end', s, offset);
	}

	/** Returns the last byte offset, not after `from`, where `value` (of `size` bytes) occurs in `s`, or -1. */
	@:keep
	@:noCompletion
	public static function haxeLastMatch(s:String, value:String, size:Int, from:Int):Int {
		return untyped __elixir__('cond do
  {3} < 0 -> -1
  binary_part({0}, {3}, {2}) == {1} -> {3}
  true -> haxe_last_match({0}, {1}, {2}, {3} - 1)
end', s, value, size, from);
	}
	#end

	/**
	 * Haxe-compatible `String.length`: the number of codepoints.
	 */
	#if !macro
	@:keep
	#end
	@:noCompletion
	public static function haxeLength(s:String):Int {
		#if macro
		return s.length;
		#else
		return untyped __elixir__('haxe_unit_count({0}, haxe_unit_index({0}))', s);
		#end
	}

	/**
	 * Haxe-compatible `String.charAt`: the codepoint at position `index`, or "".
	 */
	#if !macro
	@:keep
	#end
	@:noCompletion
	public static function haxeCharAt(s:String, index:Int):String {
		#if macro
		return s.charAt(index);
		#else
		return untyped __elixir__('if {1} < 0, do: "", else: haxe_unit_part({0}, haxe_unit_index({0}), {1}, 1)', s, index);
		#end
	}

	/**
	 * Haxe-compatible `String.charCodeAt`: the code of the codepoint at position `index`, or null.
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
  case haxe_unit_index({0}) do
    :ascii ->
      if {1} < byte_size({0}), do: :binary.at({0}, {1}), else: nil
    offsets when {1} < tuple_size(offsets) - 1 ->
      haxe_unit_code({0}, elem(offsets, {1}))
    _ ->
      nil
  end
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
  reflaxe_string_index = haxe_unit_index(reflaxe_string_source)
  reflaxe_string_length = haxe_unit_count(reflaxe_string_source, reflaxe_string_index)
  reflaxe_string_start =
    cond do
      Kernel.is_nil({2}) -> 0
      {2} < 0 -> max(reflaxe_string_length + {2}, 0)
      true -> {2}
    end

  cond do
    reflaxe_string_value == "" ->
      min(reflaxe_string_start, reflaxe_string_length)
    reflaxe_string_start > reflaxe_string_length ->
      -1
    true ->
      reflaxe_string_from = haxe_unit_offset(reflaxe_string_index, reflaxe_string_start)
      case :binary.match(reflaxe_string_source, reflaxe_string_value, scope: {reflaxe_string_from, byte_size(reflaxe_string_source) - reflaxe_string_from}) do
        {byte_pos, _} -> haxe_unit_position(reflaxe_string_index, byte_pos)
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
  reflaxe_string_index = haxe_unit_index(reflaxe_string_source)
  reflaxe_string_length = haxe_unit_count(reflaxe_string_source, reflaxe_string_index)
  reflaxe_string_start = if Kernel.is_nil({2}), do: reflaxe_string_length, else: min(max({2}, 0), reflaxe_string_length)

  if reflaxe_string_value == "" do
    reflaxe_string_start
  else
    reflaxe_string_size = byte_size(reflaxe_string_value)
    reflaxe_string_from = min(haxe_unit_offset(reflaxe_string_index, reflaxe_string_start), byte_size(reflaxe_string_source) - reflaxe_string_size)

    case haxe_last_match(reflaxe_string_source, reflaxe_string_value, reflaxe_string_size, reflaxe_string_from) do
      -1 -> -1
      byte_pos -> haxe_unit_position(reflaxe_string_index, byte_pos)
    end
  end
end).()
', s, value, startIndex);
		#end
	}

	/**
	 * Haxe-compatible `String.split`. An empty delimiter gives one piece per codepoint.
	 */
	#if !macro
	@:keep
	#end
	@:noCompletion
	public static function haxeSplit(s:String, delimiter:String):Array<String> {
		#if macro
		return s.split(delimiter);
		#else
		return untyped __elixir__('if {1} == "", do: String.codepoints({0}), else: String.split({0}, {1})', s, delimiter);
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
  reflaxe_string_index = haxe_unit_index(reflaxe_string_source)
  reflaxe_string_length = haxe_unit_count(reflaxe_string_source, reflaxe_string_index)
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

  haxe_unit_part(reflaxe_string_source, reflaxe_string_index, reflaxe_string_start, reflaxe_string_count)
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
  reflaxe_string_index = haxe_unit_index(reflaxe_string_source)
  reflaxe_string_length = haxe_unit_count(reflaxe_string_source, reflaxe_string_index)
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

  haxe_unit_part(reflaxe_string_source, reflaxe_string_index, reflaxe_string_start, reflaxe_string_count)
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
  reflaxe_string_index = haxe_unit_index(reflaxe_string_source)
  reflaxe_string_length = haxe_unit_count(reflaxe_string_source, reflaxe_string_index)
  reflaxe_string_start = min(max({1}, 0), reflaxe_string_length)
  reflaxe_string_end = if Kernel.is_nil({2}), do: reflaxe_string_length, else: min(max({2}, 0), reflaxe_string_length)
  haxe_unit_part(reflaxe_string_source, reflaxe_string_index, min(reflaxe_string_start, reflaxe_string_end), abs(reflaxe_string_end - reflaxe_string_start))
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
