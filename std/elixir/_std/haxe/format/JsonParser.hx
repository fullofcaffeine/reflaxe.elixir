package haxe.format;

#if (!macro && elixir_output)
import elixir.Jason;
#end

/**
 * JsonParser (Elixir target)
 *
 * WHAT
 * - Target-owned `haxe.format.JsonParser.parse` surface for direct parser users.
 *
 * WHY
 * - `haxe.Json.parse` already decodes through `Jason.decode!/1` on BEAM, but code
 *   that imports `haxe.format.JsonParser` directly should get the same native
 *   decode path instead of emitting the upstream pure-Haxe parser.
 *
 * HOW
 * - Runtime delegates to `Jason.decode!/1`, yielding native Elixir lists/maps with
 *   string keys and raising on invalid JSON.
 * - Macro/non-Elixir contexts keep an adapted pure-Haxe parser so compile-time
 *   calls to `haxe.Json.parse` remain independent of target-only interop.
 */
class JsonParser {
	static public inline function parse(str:String):Dynamic {
		#if (!macro && elixir_output)
		return cast Jason.decodeStrict(str);
		#else
		return new JsonParser(str).doParse();
		#end
	}

	#if (macro || !elixir_output)
	var str:String;
	var pos:Int;

	function new(str:String) {
		this.str = str;
		this.pos = 0;
	}

	function doParse():Dynamic {
		var result = parseRec();
		var c;
		while (!StringTools.isEof(c = nextChar())) {
			switch (c) {
				case ' '.code, '\r'.code, '\n'.code, '\t'.code:
				default:
					invalidChar();
			}
		}
		return result;
	}

	function parseRec():Dynamic {
		while (true) {
			var c = nextChar();
			switch (c) {
				case ' '.code, '\r'.code, '\n'.code, '\t'.code:
				case '{'.code:
					var obj = {}, field = null, comma:Null<Bool> = null;
					while (true) {
						var c = nextChar();
						switch (c) {
							case ' '.code, '\r'.code, '\n'.code, '\t'.code:
							case '}'.code:
								if (field != null || comma == false)
									invalidChar();
								return obj;
							case ':'.code:
								if (field == null)
									invalidChar();
								Reflect.setField(obj, field, parseRec());
								field = null;
								comma = true;
							case ','.code:
								if (comma) comma = false; else invalidChar();
							case '"'.code:
								if (field != null || comma)
									invalidChar();
								field = parseString();
							default:
								invalidChar();
						}
					}
				case '['.code:
					var arr = [], comma:Null<Bool> = null;
					while (true) {
						var c = nextChar();
						switch (c) {
							case ' '.code, '\r'.code, '\n'.code, '\t'.code:
							case ']'.code:
								if (comma == false)
									invalidChar();
								return arr;
							case ','.code:
								if (comma) comma = false; else invalidChar();
							default:
								if (comma)
									invalidChar();
								pos--;
								arr.push(parseRec());
								comma = true;
						}
					}
				case 't'.code:
					var save = pos;
					if (nextChar() != 'r'.code || nextChar() != 'u'.code || nextChar() != 'e'.code) {
						pos = save;
						invalidChar();
					}
					return true;
				case 'f'.code:
					var save = pos;
					if (nextChar() != 'a'.code || nextChar() != 'l'.code || nextChar() != 's'.code || nextChar() != 'e'.code) {
						pos = save;
						invalidChar();
					}
					return false;
				case 'n'.code:
					var save = pos;
					if (nextChar() != 'u'.code || nextChar() != 'l'.code || nextChar() != 'l'.code) {
						pos = save;
						invalidChar();
					}
					return null;
				case '"'.code:
					return parseString();
				case '0'.code, '1'.code, '2'.code, '3'.code, '4'.code, '5'.code, '6'.code, '7'.code, '8'.code, '9'.code, '-'.code:
					return parseNumber(c);
				default:
					invalidChar();
			}
		}
	}

	function parseString() {
		var start = pos;
		var buf:StringBuf = null;
		#if target.unicode
		var prev = -1;
		inline function cancelSurrogate() {
			buf.addChar(0xFFFD);
			prev = -1;
		}
		#end
		while (true) {
			var c = nextChar();
			if (c == '"'.code)
				break;
			if (c == '\\'.code) {
				if (buf == null) {
					buf = new StringBuf();
				}
				buf.addSub(str, start, pos - start - 1);
				c = nextChar();
				#if target.unicode
				if (c != "u".code && prev != -1)
					cancelSurrogate();
				#end
				switch (c) {
					case "r".code:
						buf.addChar("\r".code);
					case "n".code:
						buf.addChar("\n".code);
					case "t".code:
						buf.addChar("\t".code);
					case "b".code:
						buf.addChar(8);
					case "f".code:
						buf.addChar(12);
					case "/".code, '\\'.code, '"'.code:
						buf.addChar(c);
					case 'u'.code:
						var uc:Int = Std.parseInt("0x" + str.substr(pos, 4));
						pos += 4;
						#if !target.unicode
						if (uc <= 0x7F)
							buf.addChar(uc);
						else if (uc <= 0x7FF) {
							buf.addChar(0xC0 | (uc >> 6));
							buf.addChar(0x80 | (uc & 63));
						} else if (uc <= 0xFFFF) {
							buf.addChar(0xE0 | (uc >> 12));
							buf.addChar(0x80 | ((uc >> 6) & 63));
							buf.addChar(0x80 | (uc & 63));
						} else {
							buf.addChar(0xF0 | (uc >> 18));
							buf.addChar(0x80 | ((uc >> 12) & 63));
							buf.addChar(0x80 | ((uc >> 6) & 63));
							buf.addChar(0x80 | (uc & 63));
						}
						#else
						if (prev != -1) {
							if (uc < 0xDC00 || uc > 0xDFFF)
								cancelSurrogate();
							else {
								buf.addChar(((prev - 0xD800) << 10) + (uc - 0xDC00) + 0x10000);
								prev = -1;
							}
						} else if (uc >= 0xD800 && uc <= 0xDBFF)
							prev = uc;
						else
							buf.addChar(uc);
						#end
					default:
						throw "Invalid escape sequence \\" + String.fromCharCode(c) + " at position " + (pos - 1);
				}
				start = pos;
			} else if (StringTools.isEof(c)) {
				throw "Unclosed string";
			} else if (c < 32) {
				throw "Invalid character in string at position " + (pos - 1);
			}
		}
		#if target.unicode
		if (prev != -1)
			cancelSurrogate();
		#end
		if (buf == null) {
			return str.substr(start, pos - start - 1);
		} else {
			buf.addSub(str, start, pos - start - 1);
			return buf.toString();
		}
	}

	function parseNumber(c:Int):Dynamic {
		var start = pos - 1;
		var minus = c == '-'.code;
		var digit = !minus;
		var zero = c == '0'.code;
		var point = false;
		var e = false;
		var pm = false;
		var end = false;
		while (true) {
			c = nextChar();
			switch (c) {
				case '0'.code:
					if (zero && !point)
						invalidNumber(start);
					if (minus) {
						minus = false;
						zero = true;
					}
					digit = true;
				case '1'.code, '2'.code, '3'.code, '4'.code, '5'.code, '6'.code, '7'.code, '8'.code, '9'.code:
					if (zero && !point)
						invalidNumber(start);
					if (minus)
						minus = false;
					digit = true;
					zero = false;
				case '.'.code:
					if (minus || point)
						invalidNumber(start);
					digit = false;
					point = true;
				case 'e'.code, 'E'.code:
					if (minus || zero || e)
						invalidNumber(start);
					digit = false;
					e = true;
				case '+'.code, '-'.code:
					if (!e || pm)
						invalidNumber(start);
					digit = false;
					pm = true;
				default:
					if (!digit)
						invalidNumber(start);
					pos--;
					end = true;
			}
			if (end)
				break;
		}
		var f = Std.parseFloat(str.substr(start, pos - start));
		var i = Std.int(f);
		return i == f ? i : f;
	}

	inline function nextChar() {
		return StringTools.fastCodeAt(str, pos++);
	}

	function invalidChar() {
		pos--;
		throw "Invalid char " + String.fromCharCode(StringTools.fastCodeAt(str, pos)) + " at position " + pos;
	}

	function invalidNumber(start:Int) {
		throw "Invalid number at position " + start + ": " + str.substr(start, pos - start);
	}
	#end
}
