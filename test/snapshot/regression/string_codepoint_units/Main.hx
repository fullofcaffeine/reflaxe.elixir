/**
 * Every String operation must count in the same unit: one Unicode codepoint.
 *
 * `runtime.exs` calls these functions from Elixir with text where graphemes,
 * codepoints and bytes differ, and compares with the Haxe interpreter results.
 */
class Main {
	/** Lists the length, each character code and each one-character string. */
	public static function describe(s:String):String {
		var codes:Array<String> = [];
		var chars:Array<String> = [];
		var i = 0;
		while (i < s.length) {
			codes.push(Std.string(s.charCodeAt(i)));
			chars.push(s.charAt(i));
			i++;
		}
		return s.length + "|" + codes.join(",") + "|" + chars.join("/");
	}

	/** Cuts the same range with `substr` and `substring`, then the open-ended rest. */
	public static function slices(s:String, pos:Int, len:Int):String {
		return [
			s.substr(pos, len),
			s.substring(pos, pos + len),
			s.substr(pos),
			s.substr(-2),
			s.substring(pos)
		].join("|");
	}

	/** Searches forward and backward; the answers are positions in codepoints. */
	public static function find(s:String, needle:String):String {
		return [
			s.indexOf(needle),
			s.indexOf(needle, 2),
			s.lastIndexOf(needle),
			s.lastIndexOf(needle, 2)
		].join(",");
	}

	/** Splits on the empty string: one piece per codepoint. */
	public static function pieces(s:String):String {
		return s.split("").join("/");
	}

	/** Reads outside the string: no code, and the empty string. */
	public static function outside(s:String):String {
		return [
			Std.string(s.charCodeAt(-1)),
			Std.string(s.charCodeAt(s.length)),
			"[" + s.charAt(-1) + "]",
			"[" + s.charAt(s.length) + "]"
		].join(",");
	}

	/**
	 * A small JSON checker that mixes `charAt`, `charCodeAt`, `substr` and
	 * `length` on one index, as a hand-written parser does. Returns "ok" plus
	 * the end index, or "error" plus the index of the first rejected character.
	 */
	public static function check(source:String):String {
		var end = value(source, space(source, 0));
		if (end < 0)
			return "error@" + (-end - 1);
		end = space(source, end);
		return end == source.length ? "ok@" + end : "error@" + end;
	}

	static function space(source:String, index:Int):Int {
		while (index < source.length) {
			var ch = source.charAt(index);
			if (ch != " " && ch != "\n" && ch != "\r" && ch != "\t")
				break;
			index++;
		}
		return index;
	}

	static inline function fail(index:Int):Int {
		return -index - 1;
	}

	static function value(source:String, index:Int):Int {
		if (index >= source.length)
			return fail(index);
		var code = source.charCodeAt(index);
		if (code == "[".code)
			return items(source, index + 1, "]", false);
		if (code == "{".code)
			return items(source, index + 1, "}", true);
		if (code == "\"".code)
			return text(source, index + 1);
		if (code >= "0".code && code <= "9".code) {
			while (index < source.length && source.charCodeAt(index) >= "0".code && source.charCodeAt(index) <= "9".code)
				index++;
			return index;
		}
		for (literal in ["true", "false", "null"]) {
			if (source.substr(index, literal.length) == literal)
				return index + literal.length;
		}
		return fail(index);
	}

	static function text(source:String, index:Int):Int {
		while (index < source.length) {
			if (source.charAt(index) == "\"")
				return index + 1;
			index++;
		}
		return fail(index);
	}

	static function items(source:String, index:Int, close:String, keyed:Bool):Int {
		index = space(source, index);
		if (index < source.length && source.charAt(index) == close)
			return index + 1;
		while (true) {
			if (keyed) {
				index = space(source, index);
				if (index >= source.length || source.charAt(index) != "\"")
					return fail(index);
				index = text(source, index + 1);
				if (index < 0)
					return index;
				index = space(source, index);
				if (index >= source.length || source.charAt(index) != ":")
					return fail(index);
				index++;
			}
			index = value(source, space(source, index));
			if (index < 0)
				return index;
			index = space(source, index);
			if (index >= source.length)
				return fail(index);
			var ch = source.charAt(index);
			if (ch == close)
				return index + 1;
			if (ch != ",")
				return fail(index);
			index++;
		}
	}

	/** Writes control and non-ASCII characters as `\u{HEX}` so results stay plain text. */
	static function plain(value:String):String {
		var out = new StringBuf();
		for (code in new haxe.iterators.StringIteratorUnicode(value)) {
			if (code < 32 || code > 126 || code == "\\".code)
				out.add("\\u{" + StringTools.hex(code) + "}");
			else
				out.addChar(code);
		}
		return out.toString();
	}

	static function line(label:String, kind:String, result:String):Void {
		Sys.println(label + " " + kind + " " + plain(result));
	}

	static function show(label:String, s:String):Void {
		line(label, "describe", describe(s));
		line(label, "slices", slices(s, 1, 2));
		line(label, "pieces", pieces(s));
		line(label, "outside", outside(s));
		line(label, "check", check(s));
	}

	/**
	 * Prints the Haxe interpreter results kept in `interpreter.txt`:
	 * `haxe -cp . -main Main --interp > interpreter.txt`.
	 */
	public static function main():Void {
		var accent = String.fromCharCode(0x301);
		var flag = String.fromCharCode(0x1F1E7) + String.fromCharCode(0x1F1F7);
		var joiner = String.fromCharCode(0x200D);
		var family = String.fromCharCode(0x1F468) + joiner + String.fromCharCode(0x1F469) + joiner + String.fromCharCode(0x1F467);
		var jamo = String.fromCharCode(0x1100) + String.fromCharCode(0x1161);
		show("crlf-array", "[1,\r\n2]");
		show("crlf-object", "{\r\n\"a\": 1\r\n}");
		show("combining", "\"e" + accent + "\"");
		show("flag", "[\"" + flag + "\",true]");
		show("family", "{\"k\":\"" + family + "\",\"z\":null}");
		show("jamo", "[\"" + jamo + "\",1]");
		show("plain", "[1, 2]");
		show("empty", "");
		show("bad", "[1,\r\n?]");
		line("crlf", "find", find("a\r\nb\r\nc", "\n"));
		line("flag", "find", find(flag + "x" + flag + "x", "x"));
		line("accent", "find", find("e" + accent + "e" + accent, "e"));
		line("overlap", "find", find("aaa", "aa"));
		line("empty", "find", find("e" + accent, ""));
		line("missing", "find", find(flag, "x"));
	}
}
