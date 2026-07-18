package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.Term;

/** Typed access to Elixir's immutable `MapSet` value API. */
@:native("MapSet")
extern class MapSet {
	@:native("new") public static function new_():Term;
	@:native("new") public static function fromValues<T>(values:Array<T>):Term;
	@:native("member?") public static function member<T>(set:Term, value:T):Bool;
	@:native("put") public static function put<T>(set:Term, value:T):Term;
	@:native("intersection") public static function intersection(left:Term, right:Term):Term;
	@:native("size") public static function size(set:Term):Int;
	@:native("to_list") public static function toList<T>(set:Term):Array<T>;
}
#end
