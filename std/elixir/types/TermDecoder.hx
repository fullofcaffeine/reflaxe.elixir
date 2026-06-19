package elixir.types;

#if (elixir || reflaxe_runtime)
import elixir.Kernel;
import elixir.Tuple as ElixirTuple;
import haxe.ds.Option;
import haxe.functional.Result;

using haxe.functional.ResultTools;

/**
 * TermDecoder
 *
 * WHAT
 * - Typed boundary decoding helpers for `elixir.types.Term` values.
 *
 * WHY
 * - Elixir/Phoenix boundaries (params, assigns, external library returns) are often polymorphic.
 * - Decoding early keeps application code typed without reaching for `Dynamic` or ad-hoc casts.
 *
 * HOW
 * - Uses `Kernel.is_*` predicates plus small, framework-level helpers (like `Map.fetch/2`)
 *   to validate shapes and return `haxe.functional.Result`.
 */
enum TermKind {
	Atom;
	Binary;
	Bitstring;
	Boolean;
	Float;
	Function;
	Integer;
	List;
	Map;
	Nil;
	Number;
	Pid;
	Port;
	Reference;
	Tuple;
	Unknown;
}

enum TermDecodeError {
	ExpectedType(expected:TermKind, got:TermKind);
	MissingKey(key:String);
	ExpectedOkErrorTuple(got:TermKind);
}

class TermDecoder {
	public static function kind(term:Term):TermKind {
		if (Kernel.isNil(term))
			return Nil;
		if (Kernel.isBoolean(term))
			return Boolean;
		if (Kernel.isInteger(term))
			return Integer;
		if (Kernel.isFloat(term))
			return Float;
		if (Kernel.isBinary(term))
			return Binary;
		if (Kernel.isBitstring(term))
			return Bitstring;
		if (Kernel.isAtom(term))
			return Atom;
		if (Kernel.isList(term))
			return List;
		if (Kernel.isMap(term))
			return Map;
		if (Kernel.isTuple(term))
			return Tuple;
		if (Kernel.isPid(term))
			return Pid;
		if (Kernel.isPort(term))
			return Port;
		if (Kernel.isReference(term))
			return Reference;
		if (Kernel.isFunction(term))
			return Function;
		if (Kernel.isNumber(term))
			return Number;
		return Unknown;
	}

	public static inline function asString(term:Term):Result<String, TermDecodeError> {
		return Kernel.isBinary(term) ? Ok(cast term) : Error(ExpectedType(Binary, kind(term)));
	}

	public static inline function asInt(term:Term):Result<Int, TermDecodeError> {
		return Kernel.isInteger(term) ? Ok(cast term) : Error(ExpectedType(Integer, kind(term)));
	}

	public static inline function asBool(term:Term):Result<Bool, TermDecodeError> {
		return Kernel.isBoolean(term) ? Ok(cast term) : Error(ExpectedType(Boolean, kind(term)));
	}

	public static inline function asFloat(term:Term):Result<Float, TermDecodeError> {
		return Kernel.isFloat(term) ? Ok(cast term) : Error(ExpectedType(Float, kind(term)));
	}

	public static inline function asList(term:Term):Result<Array<Term>, TermDecodeError> {
		return Kernel.isList(term) ? Ok(cast term) : Error(ExpectedType(List, kind(term)));
	}

	public static inline function asMap(term:Term):Result<Term, TermDecodeError> {
		return Kernel.isMap(term) ? Ok(term) : Error(ExpectedType(Map, kind(term)));
	}

	public static inline function optional<T>(term:Term, decode:Term->Result<T, TermDecodeError>):Result<Option<T>, TermDecodeError> {
		if (Kernel.isNil(term))
			return Ok(None);
		return decode(term).map(function(value) return Some(value));
	}

	public static function fetch(map:Term, key:Term):Result<Term, TermDecodeError> {
		return switch (asMap(map)) {
			case Ok(validatedMap):
				var fetchResult:Term = untyped __elixir__('Map.fetch({0}, {1})', validatedMap, key);
				ElixirTuple.isOkTuple(fetchResult) ? Ok(ElixirTuple.getOkValue(fetchResult)) : Error(MissingKey(Kernel.inspect(key)));
			case Error(error):
				Error(error);
		}
	}

	public static function fetchStringKey(map:Term, key:String):Result<Term, TermDecodeError> {
		return fetch(map, cast key);
	}

	public static function fetchAtomKey(map:Term, key:Atom):Result<Term, TermDecodeError> {
		return fetch(map, cast key);
	}

	public static inline function fetchStringKeyAs<T>(map:Term, key:String, decode:Term->Result<T, TermDecodeError>):Result<T, TermDecodeError> {
		return fetchStringKey(map, key).flatMap(decode);
	}

	public static inline function fetchAtomKeyAs<T>(map:Term, key:Atom, decode:Term->Result<T, TermDecodeError>):Result<T, TermDecodeError> {
		return fetchAtomKey(map, key).flatMap(decode);
	}

	public static function optionalStringKeyAs<T>(map:Term, key:String, decode:Term->Result<T, TermDecodeError>):Result<Option<T>, TermDecodeError> {
		return switch (fetchStringKey(map, key)) {
			case Ok(value):
				switch (decode(value)) {
					case Ok(decodedValue):
						Ok(Some(decodedValue));
					case Error(error):
						Error(error);
				}
			case Error(MissingKey(_)):
				Ok(None);
			case Error(error):
				Error(error);
		}
	}

	public static function optionalAtomKeyAs<T>(map:Term, key:Atom, decode:Term->Result<T, TermDecodeError>):Result<Option<T>, TermDecodeError> {
		return switch (fetchAtomKey(map, key)) {
			case Ok(value):
				switch (decode(value)) {
					case Ok(decodedValue):
						Ok(Some(decodedValue));
					case Error(error):
						Error(error);
				}
			case Error(MissingKey(_)):
				Ok(None);
			case Error(error):
				Error(error);
		}
	}

	public static function okError<T, E>(term:Term, decodeOk:Term->Result<T, TermDecodeError>,
			decodeError:Term->Result<E, TermDecodeError>):Result<Result<T, E>, TermDecodeError> {
		if (ElixirTuple.isOkTuple(term)) {
			return decodeOk(ElixirTuple.getOkValue(term)).map(function(value):Result<T, E> return Ok(value));
		}
		if (ElixirTuple.isErrorTuple(term)) {
			return decodeError(ElixirTuple.getErrorReason(term)).map(function(reason):Result<T, E> return Error(reason));
		}
		return Error(ExpectedOkErrorTuple(kind(term)));
	}
}
#end
