/**
 * `EReg` positions must count codepoints, as `String` positions do.
 *
 * `runtime.exs` calls these functions from Elixir with text where graphemes,
 * codepoints and bytes differ, and compares with the Haxe interpreter results.
 */
class Main {
	/**
	 * Matches once and uses the reported position with `substr`, the way
	 * application code combines the two. Also reads the text on both sides.
	 */
	public static function found(text:String, pattern:String):String {
		var matcher = new EReg(pattern, "");
		if (!matcher.match(text))
			return "none";
		var at = matcher.matchedPos();
		return [
			at.pos + "," + at.len,
			matcher.matchedLeft(),
			matcher.matched(0),
			matcher.matchedRight(),
			text.substr(at.pos, at.len),
			text.substr(0, at.pos)
		].join("|");
	}

	/** Matches inside a range given as a codepoint position and length. */
	public static function foundIn(text:String, pattern:String, pos:Int, len:Int):String {
		var matcher = new EReg(pattern, "");
		if (!matcher.matchSub(text, pos, len))
			return "none";
		var at = matcher.matchedPos();
		return at.pos + "," + at.len + "|" + matcher.matched(0);
	}

	/** Replaces every match. */
	public static function replaced(text:String, pattern:String, by:String):String {
		return new EReg(pattern, "g").replace(text, by);
	}

	/** Replaces every match with its text and position. */
	public static function mapped(text:String, pattern:String):String {
		return new EReg(pattern, "g").map(text, function(matcher) {
			return "<" + matcher.matched(0) + "@" + matcher.matchedPos().pos + ">";
		});
	}

	/** Splits at every match. */
	public static function pieces(text:String, pattern:String):String {
		return new EReg(pattern, "g").split(text).join("|");
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

	static function show(label:String, text:String, pattern:String, ranges:Bool):Void {
		Sys.println(label + " found " + plain(found(text, pattern)));
		// The interpreter reads the `matchSub` range in bytes when the text is not
		// ASCII, so only ASCII text is compared for that call.
		if (ranges)
			Sys.println(label + " foundIn " + plain(foundIn(text, pattern, 2, 3)));
		Sys.println(label + " replaced " + plain(replaced(text, pattern, "_")));
		Sys.println(label + " mapped " + plain(mapped(text, pattern)));
		Sys.println(label + " pieces " + plain(pieces(text, pattern)));
	}

	/**
	 * Prints the Haxe interpreter results kept in `interpreter.txt`:
	 * `haxe -cp . -main Main --interp > interpreter.txt`.
	 */
	public static function main():Void {
		var accent = String.fromCharCode(0x301);
		var flag = String.fromCharCode(0x1F1E7) + String.fromCharCode(0x1F1F7);
		show("crlf", "a\r\nbc\r\nbd", "b", true);
		show("accent", "e" + accent + "xe" + accent + "xy", "x", false);
		show("flag", flag + "b" + flag + "bc", "b", false);
		show("plain", "abcabc", "b", true);
		show("wide", "a\r\n" + flag + "c" + flag, flag, false);
		show("missing", "a\r\nc", "b", true);
	}
}
