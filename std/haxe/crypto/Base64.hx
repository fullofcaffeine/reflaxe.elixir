package haxe.crypto;

import haxe.io.Bytes;

/**
 * Base64 (Elixir target)
 *
 * WHAT
 * - Canonical Haxe `haxe.crypto.Base64` helpers for standard and URL-safe Base64.
 *
 * WHY
 * - Upstream `Base64` depends on `haxe.crypto.BaseCode`, which is not emitted for
 *   the Elixir target yet. BEAM also already provides a well-tested native `Base`.
 *
 * HOW
 * - Runtime delegates to Elixir `Base` helpers and wraps decoded binaries as `Bytes`.
 * - Macro/eval contexts use a small pure-Haxe implementation so macro execution
 *   does not depend on target-only `__elixir__()` calls.
 */
@:native("Haxe.Crypto.Base64")
class Base64 {
	public static var CHARS(default, null) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	public static var BYTES(default, null) = Bytes.ofString(CHARS);

	public static var URL_CHARS(default, null) = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
	public static var URL_BYTES(default, null) = Bytes.ofString(URL_CHARS);

	public static function encode(bytes:Bytes, ?complement:Bool):String {
		var useComplement = complement == null ? true : complement;
		#if (macro || (!reflaxe_runtime && !elixir))
		return Base64Pure.encode(bytes, CHARS, useComplement);
		#else
		return untyped __elixir__('Base.encode64({0}, padding: {1})', bytes.getData(), useComplement);
		#end
	}

	public static function decode(str:String, ?complement:Bool):Bytes {
		var useComplement = complement == null ? true : complement;
		#if (macro || (!reflaxe_runtime && !elixir))
		return Base64Pure.decode(str, CHARS, useComplement);
		#else
		var encoded = useComplement ? untyped __elixir__('String.trim_trailing({0}, "=")', str) : str;
		var decoded = untyped __elixir__('Base.decode64!({0}, padding: false)', encoded);
		return Bytes.ofData(decoded);
		#end
	}

	public static function urlEncode(bytes:Bytes, ?complement:Bool):String {
		var useComplement = complement == null ? false : complement;
		#if (macro || (!reflaxe_runtime && !elixir))
		return Base64Pure.encode(bytes, URL_CHARS, useComplement);
		#else
		return untyped __elixir__('Base.url_encode64({0}, padding: {1})', bytes.getData(), useComplement);
		#end
	}

	public static function urlDecode(str:String, ?complement:Bool):Bytes {
		var useComplement = complement == null ? false : complement;
		#if (macro || (!reflaxe_runtime && !elixir))
		return Base64Pure.decode(str, URL_CHARS, useComplement);
		#else
		var encoded = useComplement ? untyped __elixir__('String.trim_trailing({0}, "=")', str) : str;
		var decoded = untyped __elixir__('Base.url_decode64!({0}, padding: false)', encoded);
		return Bytes.ofData(decoded);
		#end
	}
}

#if (macro || (!reflaxe_runtime && !elixir))
private class Base64Pure {
	public static function encode(bytes:Bytes, chars:String, complement:Bool):String {
		var output = "";
		var index = 0;
		while (index < bytes.length) {
			var first = bytes.get(index++);
			var hasSecond = index < bytes.length;
			var second = hasSecond ? bytes.get(index++) : 0;
			var hasThird = index < bytes.length;
			var third = hasThird ? bytes.get(index++) : 0;

			output += chars.charAt(first >> 2);
			output += chars.charAt(((first & 3) << 4) | (second >> 4));
			if (hasSecond)
				output += chars.charAt(((second & 15) << 2) | (third >> 6));
			else if (complement)
				output += "=";
			if (hasThird)
				output += chars.charAt(third & 63);
			else if (complement)
				output += "=";
		}
		return output;
	}

	public static function decode(str:String, chars:String, complement:Bool):Bytes {
		if (complement) {
			while (str.length > 0 && str.charCodeAt(str.length - 1) == "=".code) {
				str = str.substr(0, str.length - 1);
			}
		}

		var decoded:Array<Int> = [];
		var index = 0;
		while (index < str.length) {
			var first = decodeChar(str, chars, index++);
			var second = decodeChar(str, chars, index++);
			var hasThird = index < str.length;
			var third = hasThird ? decodeChar(str, chars, index++) : 0;
			var hasFourth = index < str.length;
			var fourth = hasFourth ? decodeChar(str, chars, index++) : 0;

			decoded.push((first << 2) | (second >> 4));
			if (hasThird)
				decoded.push(((second & 15) << 4) | (third >> 2));
			if (hasFourth)
				decoded.push(((third & 3) << 6) | fourth);
		}

		var bytes = Bytes.alloc(decoded.length);
		for (position in 0...decoded.length) {
			bytes.set(position, decoded[position]);
		}
		return bytes;
	}

	static function decodeChar(str:String, chars:String, position:Int):Int {
		if (position >= str.length)
			throw "Invalid base64 length";
		var value = chars.indexOf(str.charAt(position));
		if (value < 0)
			throw "Invalid base64 character";
		return value;
	}
}
#end
