package;

import haxe.io.Bytes;
import haxe.io.Encoding;
import haxe.iterators.StringIteratorUnicode;
import haxe.iterators.StringKeyValueIteratorUnicode;

/**
 * UnicodeString — Elixir-target override for Haxe's UnicodeString abstract.
 *
 * WHAT
 * - Keeps the upstream abstract API shape while making `validate/2` exhaustive for
 *   this target's expanded `haxe.io.Encoding` enum.
 * - Supports UTF-8 validation and codepoint iteration over Elixir UTF-8 binaries.
 *
 * WHY
 * - The upstream Haxe 4.3.x `UnicodeString.validate` switch only handles `UTF8` and
 *   `RawNative`. Reflaxe.Elixir's `haxe.io.Encoding` surface also exposes UTF-16/UTF-32
 *   constructors, so the upstream switch fails exhaustiveness checks.
 *
 * HOW
 * - UTF-8 validation follows the upstream byte-state machine over the target Bytes binary.
 * - Non-UTF-8 encodings fail fast because this target's Bytes implementation stores
 *   UTF-8 binaries and does not expose UTF-16/UTF-32 validation semantics yet.
 * - Iteration delegates to Haxe's unicode iterator classes; on Elixir those use
 *   `StringTools.fastCodeAt/unsafeCodeAt`, which lower to codepoint-indexed access.
 */
@:forward
@:access(StringTools)
abstract UnicodeString(String) from String to String {
	public var length(get, never):Int;

	inline function get_length():Int {
		return untyped __elixir__('String.length({0})', this);
	}

	static public inline function validate(bytes:Bytes, encoding:Encoding):Bool {
		return untyped __elixir__('
			case {1} do
				{:raw_native} ->
					raise "UnicodeString.validate: RawNative encoding is not supported"
				{:utf16le} ->
					raise "UnicodeString.validate: only UTF8 encoding is supported on the Elixir target"
				{:utf16be} ->
					raise "UnicodeString.validate: only UTF8 encoding is supported on the Elixir target"
				{:utf32le} ->
					raise "UnicodeString.validate: only UTF8 encoding is supported on the Elixir target"
				{:utf32be} ->
					raise "UnicodeString.validate: only UTF8 encoding is supported on the Elixir target"
				{:utf8} ->
					reflaxe_unicode_len = {2}
					reflaxe_unicode_get = fn pos -> :binary.at({0}, pos) end
					reflaxe_unicode_valid = fn reflaxe_unicode_valid, pos ->
						if pos >= reflaxe_unicode_len do
							true
						else
							code = reflaxe_unicode_get.(pos)
							cond do
								code < 0x80 ->
									reflaxe_unicode_valid.(reflaxe_unicode_valid, pos + 1)
								code < 0xC2 ->
									false
								code < 0xE0 ->
									if pos + 1 >= reflaxe_unicode_len do
										false
									else
										code2 = reflaxe_unicode_get.(pos + 1)
										if code2 < 0x80 or code2 > 0xBF do
											false
										else
											reflaxe_unicode_valid.(reflaxe_unicode_valid, pos + 2)
										end
									end
								code < 0xF0 ->
									if pos + 2 >= reflaxe_unicode_len do
										false
									else
										code2 = reflaxe_unicode_get.(pos + 1)
										code3 = reflaxe_unicode_get.(pos + 2)
										code2_valid =
											if code == 0xE0 do
												code2 >= 0xA0 and code2 <= 0xBF
											else
												code2 >= 0x80 and code2 <= 0xBF
											end
										combined = Bitwise.bor(Bitwise.bsl(code, 16), Bitwise.bor(Bitwise.bsl(code2, 8), code3))
										if not code2_valid or code3 < 0x80 or code3 > 0xBF or (0xEDA080 <= combined and combined <= 0xEDBFBF) do
											false
										else
											reflaxe_unicode_valid.(reflaxe_unicode_valid, pos + 3)
										end
									end
								code > 0xF4 ->
									false
								true ->
									if pos + 3 >= reflaxe_unicode_len do
										false
									else
										code2 = reflaxe_unicode_get.(pos + 1)
										code3 = reflaxe_unicode_get.(pos + 2)
										code4 = reflaxe_unicode_get.(pos + 3)
										code2_valid =
											cond do
												code == 0xF0 -> code2 >= 0x90 and code2 <= 0xBF
												code == 0xF4 -> code2 >= 0x80 and code2 <= 0x8F
												true -> code2 >= 0x80 and code2 <= 0xBF
											end
										if not code2_valid or code3 < 0x80 or code3 > 0xBF or code4 < 0x80 or code4 > 0xBF do
											false
										else
											reflaxe_unicode_valid.(reflaxe_unicode_valid, pos + 4)
										end
									end
							end
						end
					end
					reflaxe_unicode_valid.(reflaxe_unicode_valid, 0)
			end
		', bytes.getData(), encoding, bytes.length);
	}

	public inline function new(string:String):Void {
		this = string;
	}

	public inline function iterator():StringIteratorUnicode {
		return new StringIteratorUnicode(this);
	}

	public inline function keyValueIterator():StringKeyValueIteratorUnicode {
		return new StringKeyValueIteratorUnicode(this);
	}

	@:op(A < B) static function lt(a:UnicodeString, b:UnicodeString):Bool;

	@:op(A <= B) static function lte(a:UnicodeString, b:UnicodeString):Bool;

	@:op(A > B) static function gt(a:UnicodeString, b:UnicodeString):Bool;

	@:op(A >= B) static function gte(a:UnicodeString, b:UnicodeString):Bool;

	@:op(A == B) static function eq(a:UnicodeString, b:UnicodeString):Bool;

	@:op(A != B) static function neq(a:UnicodeString, b:UnicodeString):Bool;

	@:op(A + B) static function add(a:UnicodeString, b:UnicodeString):UnicodeString;

	@:op(A += B) static function assignAdd(a:UnicodeString, b:UnicodeString):UnicodeString;

	@:op(A + B) @:commutative static function add(a:UnicodeString, b:String):UnicodeString;

	@:op(A += B) @:commutative static function assignAdd(a:UnicodeString, b:String):UnicodeString;
}
