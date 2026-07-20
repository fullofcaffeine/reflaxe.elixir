package elixir;

import elixir.types.Atom;
import elixir.types.KeywordEntry;
import elixir.types.KeywordList;
import elixir.types.Term;
import elixir.types.Tuple2;
import elixir.types.Tuple3;

/** A single `OptionParser` switch declaration such as `check: :boolean`. */
typedef OptionSwitch = KeywordEntry<Atom>;

/**
 * Typed atom constants accepted as the simple value in an `OptionSwitch`.
 *
 * Inline `Atom` fields preserve literal-atom lowering when passed through the
 * generic `Keyword.entry` constructor. The class emits no target module.
 */
class OptionSwitchTypes {
	public static inline final BOOLEAN:Atom = "boolean";
	public static inline final COUNT:Atom = "count";
	public static inline final INTEGER:Atom = "integer";
	public static inline final FLOAT:Atom = "float";
	public static inline final STRING:Atom = "string";
	public static inline final KEEP:Atom = "keep";
}

/** An option that could not be parsed by `OptionParser.parse/2`. */
typedef InvalidOption = Tuple2<String, Null<String>>;

/** Explicit native carrier for `{parsed, argv, invalid}`. */
typedef RawOptionParseResult = Tuple3<KeywordList<Term>, Array<String>, Array<InvalidOption>>;

/**
 * Zero-cost named view of the native `{parsed, argv, invalid}` result.
 *
 * Named properties are read-only because this is a BEAM tuple, not a mutable
 * record. Explicit `_0`, `_1`, and `_2` properties preserve existing raw
 * reads and persistent tuple-update syntax.
 */
@:elixirNativeTupleView
abstract OptionParseResult(RawOptionParseResult) from RawOptionParseResult to RawOptionParseResult {
	public var _0(get, set):KeywordList<Term>;
	public var _1(get, set):Array<String>;
	public var _2(get, set):Array<InvalidOption>;

	public var options(get, never):KeywordList<Term>;
	public var argv(get, never):Array<String>;
	public var invalid(get, never):Array<InvalidOption>;

	extern inline function get__0():KeywordList<Term> {
		return this._0;
	}

	extern inline function set__0(value:KeywordList<Term>):KeywordList<Term> {
		return this._0 = value;
	}

	extern inline function get__1():Array<String> {
		return this._1;
	}

	extern inline function set__1(value:Array<String>):Array<String> {
		return this._1 = value;
	}

	extern inline function get__2():Array<InvalidOption> {
		return this._2;
	}

	extern inline function set__2(value:Array<InvalidOption>):Array<InvalidOption> {
		return this._2 = value;
	}

	extern inline function get_options():KeywordList<Term> {
		return this._0;
	}

	extern inline function get_argv():Array<String> {
		return this._1;
	}

	extern inline function get_invalid():Array<InvalidOption> {
		return this._2;
	}
}

/** Type-safe externs for Elixir's `OptionParser` module. */
@:native("OptionParser")
extern class OptionParser {
	@:native("parse")
	static function parse(args:Array<String>, options:KeywordList<Term>):OptionParseResult;
}
