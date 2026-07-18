package elixir;

import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.Term;

/** A single `OptionParser` switch declaration such as `check: :boolean`. */
typedef OptionSwitch = {_0:Atom, _1:Atom};

/** An option that could not be parsed by `OptionParser.parse/2`. */
typedef InvalidOption = {_0:String, _1:Null<String>};

/** Native `{parsed, argv, invalid}` result returned by `OptionParser.parse/2`. */
typedef OptionParseResult = {
	_0:KeywordList<Term>,
	_1:Array<String>,
	_2:Array<InvalidOption>
};

/** Type-safe externs for Elixir's `OptionParser` module. */
@:native("OptionParser")
extern class OptionParser {
	@:native("parse")
	static function parse(args:Array<String>, options:KeywordList<Term>):OptionParseResult;
}
