/**
 * `StringBuf` must append in constant time and cut `addSub` in codepoints.
 *
 * `runtime.exs` calls these functions from Elixir. It compares the results
 * with the Haxe interpreter and builds 800 KB with a time budget.
 */
class Main {
	/** Builds `count` two-character pieces: one `addChar`, then one `add`. */
	public static function build(count:Int):String {
		var out = new StringBuf();
		var i = 0;
		while (i < count) {
			out.addChar("a".code + (i % 26));
			out.add("-");
			i++;
		}
		return out.toString();
	}

	/** Copies `source` one character at a time with `addSub`, as a tokenizer does. */
	public static function copy(source:String):String {
		var out = new StringBuf();
		var i = 0;
		while (i < source.length) {
			out.addSub(source, i, 1);
			i++;
		}
		return out.toString();
	}

	/** Cuts several ranges of `s` with `addSub`. Each range is in codepoints. */
	public static function subs(s:String):String {
		var out = new StringBuf();
		out.addSub(s, 0, 1);
		out.add("|");
		out.addSub(s, 1, 2);
		out.add("|");
		out.addSub(s, 1);
		out.add("|");
		out.addSub(s, s.length - 1, 1);
		out.add("|");
		out.addSub(s, 0, s.length);
		out.add("|");
		out.addSub(s, s.length);
		out.add("|");
		out.addSub(s, 2, 0);
		return out.toString();
	}

	/**
	 * Cuts two characters from the position that `indexOf` found. Both must
	 * count the same unit: in "a\r\nbc", "b" is at position 3 and the cut is "bc".
	 */
	public static function afterSearch(s:String, needle:String):String {
		var out = new StringBuf();
		out.addSub(s, s.indexOf(needle), 2);
		return out.toString();
	}

	/** Appends each kind of value, then reads the buffer twice and its length. */
	public static function kinds(text:String, code:Int):String {
		var out = new StringBuf();
		out.add(text);
		out.add(12);
		out.add(1.5);
		out.add(true);
		out.add(null);
		out.addChar(code);
		out.add("");
		var first = out.toString();
		out.add("!");
		return first + "|" + out.toString() + "|" + out.length;
	}

	/** An empty buffer gives the empty string and length zero. */
	public static function empty():String {
		var out = new StringBuf();
		return "[" + out.toString() + "]" + out.length;
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
		line(label, "subs", subs(s));
		line(label, "copy", copy(s));
		line(label, "kinds", kinds(s, s.charCodeAt(s.length - 1)));
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
		show("crlf", "a\r\nb\r\n");
		show("combining", "e" + accent + "xe" + accent);
		show("flag", flag + "x" + flag);
		show("family", "k" + family + "z" + String.fromCharCode(0x1F600));
		show("plain", "abcd");
		line("crlf", "afterSearch", afterSearch("a\r\nbc", "b"));
		line("flag", "afterSearch", afterSearch(flag + "bc", "b"));
		line("empty", "empty", empty());
		line("small", "build", build(3));
	}
}
