package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.Term;
import elixir.types.Atom as AtomValue;
import elixir.types.Tuple2;
import elixir.types.Tuple3;
import elixir.types.Tuple4;
import elixir.types.Tuple5;

/**
 * Tuple module extern definitions for Elixir standard library
 * Provides type-safe interfaces for tuple operations
 * 
 * Maps to Elixir's Tuple module functions with proper type signatures
 * Essential for working with fixed-size collections and function returns
 */
@:native("Tuple")
extern class Tuple {
	// Tuple creation
	@:native("duplicate")
	static function duplicate<T>(value:T, size:Int):Term; // Returns tuple with value repeated

	// Tuple operations
	@:native("append")
	static function append(tuple:Term, value:Term):Term; // Append element to tuple

	@:native("delete_at")
	static function deleteAt(tuple:Term, index:Int):Term; // Delete element at index

	@:native("insert_at")
	static function insertAt(tuple:Term, index:Int, value:Term):Term; // Insert at index

	@:native("product")
	static function product(tuple1:Term, tuple2:Term):Term; // Cartesian product

	@:native("sum")
	static function sum(tuple:Term):Float; // Sum of numeric tuple elements

	// Conversion
	@:native("to_list")
	static function toList(tuple:Term):Array<Term>; // Convert tuple to list

	// Helper functions for common operations
	public static inline function fromList(list:Array<Term>):Term {
		return untyped __elixir__('List.to_tuple({0})', list);
	}

	public static inline function size(tuple:Term):Int {
		return untyped __elixir__('tuple_size({0})', tuple);
	}

	public static inline function elem(tuple:Term, index:Int):Term {
		return untyped __elixir__('elem({0}, {1})', tuple, index);
	}

	public static inline function putElem(tuple:Term, index:Int, value:Term):Term {
		return untyped __elixir__('put_elem({0}, {1}, {2})', tuple, index, value);
	}

	/** Constructs a native two-element tuple with no runtime helper call. */
	public static extern inline function of2<A, B>(a:A, b:B):Tuple2<A, B> {
		return {_0: a, _1: b};
	}

	/** Constructs a native three-element tuple with no runtime helper call. */
	public static extern inline function of3<A, B, C>(a:A, b:B, c:C):Tuple3<A, B, C> {
		return {_0: a, _1: b, _2: c};
	}

	/** Constructs a native four-element tuple with no runtime helper call. */
	public static extern inline function of4<A, B, C, D>(a:A, b:B, c:C, d:D):Tuple4<A, B, C, D> {
		return {
			_0: a,
			_1: b,
			_2: c,
			_3: d
		};
	}

	/** Constructs a native five-element tuple with no runtime helper call. */
	public static extern inline function of5<A, B, C, D, E>(a:A, b:B, c:C, d:D, e:E):Tuple5<A, B, C, D, E> {
		return {
			_0: a,
			_1: b,
			_2: c,
			_3: d,
			_4: e
		};
	}

	/** Compatibility spelling for `Tuple.of2`. */
	public static extern inline function make2<A, B>(a:A, b:B):Tuple2<A, B> {
		return of2(a, b);
	}

	/** Compatibility spelling for `Tuple.of3`. */
	public static extern inline function make3<A, B, C>(a:A, b:B, c:C):Tuple3<A, B, C> {
		return of3(a, b, c);
	}

	/** Compatibility spelling for `Tuple.of4`. */
	public static extern inline function make4<A, B, C, D>(a:A, b:B, c:C, d:D):Tuple4<A, B, C, D> {
		return of4(a, b, c, d);
	}

	/** Compatibility spelling for `Tuple.of5`. */
	public static extern inline function make5<A, B, C, D, E>(a:A, b:B, c:C, d:D, e:E):Tuple5<A, B, C, D, E> {
		return of5(a, b, c, d, e);
	}

	// Pattern matching helpers
	public static inline function isOkTuple(tuple:Term):Bool {
		return untyped __elixir__('match?({:ok, _}, {0})', tuple);
	}

	public static inline function isErrorTuple(tuple:Term):Bool {
		return untyped __elixir__('match?({:error, _}, {0})', tuple);
	}

	public static inline function getOkValue(tuple:Term):Term {
		return untyped __elixir__('elem({0}, 1)', tuple);
	}

	public static inline function getErrorReason(tuple:Term):Term {
		return untyped __elixir__('elem({0}, 1)', tuple);
	}

	// Common tuple patterns
	public static inline function ok<T>(value:T):{_0:AtomValue, _1:T} {
		return cast untyped __elixir__('{:ok, {0}}', value);
	}

	public static inline function error<T>(reason:T):{_0:AtomValue, _1:T} {
		return cast untyped __elixir__('{:error, {0}}', reason);
	}

	public static inline function okAtom():AtomValue {
		return cast untyped __elixir__(':ok');
	}

	public static inline function errorAtom():AtomValue {
		return cast untyped __elixir__(':error');
	}
}

/**
 * Common tuple result patterns for Elixir
 */
class TupleResult {
	public static inline function isOk<T>(result:{_0:String, _1:T}):Bool {
		return result._0 == "ok";
	}

	public static inline function isError<T>(result:{_0:String, _1:T}):Bool {
		return result._0 == "error";
	}

	public static inline function unwrap<T>(result:{_0:String, _1:T}):T {
		if (result._0 != "ok") {
			throw new haxe.Exception('Expected ok tuple, got ${result._0}');
		}
		return result._1;
	}

	public static inline function unwrapOr<T>(result:{_0:String, _1:T}, defaultValue:T):T {
		return result._0 == "ok" ? result._1 : defaultValue;
	}

	public static inline function mapOk<T, R>(result:{_0:String, _1:T}, fn:T->R):{_0:String, _1:Term} {
		if (result._0 == "ok") {
			return {_0: "ok", _1: cast fn(result._1)};
		}
		return cast result;
	}

	public static inline function mapError<T, E, R>(result:{_0:String, _1:T}, fn:T->R):{_0:String, _1:Term} {
		if (result._0 == "error") {
			return {_0: "error", _1: cast fn(result._1)};
		}
		return cast result;
	}
}
#end
