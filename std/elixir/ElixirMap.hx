package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.Term;

/**
 * Map module extern definitions for Elixir standard library
 * Provides type-safe interfaces for Map operations
 * 
 * Maps to Elixir's Map module functions with proper type signatures
 */
@:native("Map")
extern class ElixirMap {
	// Core map operations
	@:native("new")
	public static function new_():Term;

	@:native("new")
	public static function fromList(list:Array<Term>):Term;

	@:native("put")
	public static function put(map:Term, key:Term, value:Term):Term;

	@:native("get")
	public static function get(map:Term, key:Term):Term;

	@:native("Map.get")
	public static function getWithDefault<K, V>(map:Map<K, V>, key:K, defaultValue:V):V;

	/** Typed lookup on an explicitly native BEAM map represented by `Term`. */
	@:native("Map.get")
	public static function getTyped<K, V>(map:Term, key:K):Null<V>;

	/** Typed lookup with a default on an explicitly native BEAM map. */
	@:native("Map.get")
	public static function getTypedWithDefault<K, V>(map:Term, key:K, defaultValue:V):V;

	/** Native `Map.fetch/2` result for boundaries that validate the returned tag. */
	@:native("Map.fetch")
	public static function fetchTerm<K>(map:Term, key:K):Term;

	/** Functional native-map update without widening the caller to `Dynamic`. */
	@:native("Map.put")
	public static function putTerm<K, V>(map:Term, key:K, value:V):Term;

	/** Functional native-map deletion without widening the caller to `Dynamic`. */
	@:native("Map.delete")
	public static function deleteTerm<K>(map:Term, key:K):Term;

	/** Native-map membership at an explicit `Term` boundary. */
	@:native("Map.has_key?")
	public static function hasKeyTerm<K>(map:Term, key:K):Bool;

	/** Fetch a required value from an explicitly native BEAM map. */
	@:native("Map.fetch!")
	public static function fetchBangTerm<K, V>(map:Term, key:K):V;

	/** Enumerate the keys of an explicitly native BEAM map. */
	@:native("Map.keys")
	public static function keysTerm<K>(map:Term):Array<K>;

	/** Enumerate key/value tuples from an explicitly native BEAM map. */
	@:native("Map.to_list")
	public static function toListTerm<K, V>(map:Term):Array<{_0:K, _1:V}>;

	/** Merge two explicitly native BEAM maps. */
	@:native("Map.merge")
	public static function mergeTerm(left:Term, right:Term):Term;

	/** Drop keys from an explicitly native BEAM map. */
	@:native("Map.drop")
	public static function dropTerm<K>(map:Term, keys:Array<K>):Term;

	@:native("Map.fetch")
	public static function fetch<K, V>(map:Map<K, V>, key:K):{_0:String, _1:Null<V>}; // {:ok, value} | :error

	@:native("Map.fetch!")
	public static function fetchBang<K, V>(map:Map<K, V>, key:K):V; // Throws if key not found

	// Membership and size
	@:native("Map.has_key?")
	public static function hasKey<K, V>(map:Map<K, V>, key:K):Bool;

	@:native("Map.size")
	public static function size<K, V>(map:Map<K, V>):Int;

	@:native("Map.size")
	public static function sizeTerm(map:Term):Int;

	@:native("Map.empty?")
	public static function empty<K, V>(map:Map<K, V>):Bool;

	// Removal operations
	@:native("Map.delete")
	public static function delete<K, V>(map:Map<K, V>, key:K):Map<K, V>;

	@:native("Map.pop")
	public static function pop<K, V>(map:Map<K, V>, key:K):{_0:Null<V>, _1:Map<K, V>};

	@:native("Map.pop")
	public static function popWithDefault<K, V>(map:Map<K, V>, key:K, defaultValue:V):{_0:V, _1:Map<K, V>};

	// Update operations
	@:native("Map.update")
	public static function update<K, V>(map:Map<K, V>, key:K, initial:V, func:V->V):Map<K, V>;

	@:native("Map.update!")
	public static function updateBang<K, V>(map:Map<K, V>, key:K, func:V->V):Map<K, V>; // Throws if key not found

	@:native("Map.put_new")
	public static function putNew<K, V>(map:Map<K, V>, key:K, value:V):Map<K, V>;

	@:native("Map.put_new_lazy")
	public static function putNewLazy<K, V>(map:Map<K, V>, key:K, func:Void->V):Map<K, V>;

	// Bulk operations
	@:native("Map.merge")
	public static function merge<K, V>(map1:Map<K, V>, map2:Map<K, V>):Map<K, V>;

	@:native("Map.merge")
	public static function mergeWith<K, V>(map1:Map<K, V>, map2:Map<K, V>, func:(K, V, V) -> V):Map<K, V>;

	@:native("Map.drop")
	public static function drop<K, V>(map:Map<K, V>, keys:Array<K>):Map<K, V>;

	@:native("Map.take")
	public static function take<K, V>(map:Map<K, V>, keys:Array<K>):Map<K, V>;

	@:native("Map.split")
	public static function split<K, V>(map:Map<K, V>, keys:Array<K>):{_0:Map<K, V>, _1:Map<K, V>};

	// Iteration and transformation
	@:native("Map.keys")
	public static function keys<K, V>(map:Map<K, V>):Array<K>;

	@:native("Map.values")
	public static function values<K, V>(map:Map<K, V>):Array<V>;

	@:native("Map.to_list")
	public static function toList<K, V>(map:Map<K, V>):Array<{_0:K, _1:V}>;

	@:native("Map.from_struct")
	public static function fromStruct<T>(struct:T):Map<String, Term>;

	// Filter and mapping
	@:native("Map.filter")
	public static function filter<K, V>(map:Map<K, V>, func:(K, V) -> Bool):Map<K, V>;

	@:native("Map.reject")
	public static function reject<K, V>(map:Map<K, V>, func:(K, V) -> Bool):Map<K, V>;

	// Comparison
	@:native("Map.equal?")
	public static function equal<K, V>(map1:Map<K, V>, map2:Map<K, V>):Bool;

	// String key convenience functions (for struct-like maps)
	@:native("Map.get")
	public static function getAtom(map:Map<String, Term>, key:String):Null<Term>;

	@:native("Map.put")
	public static function putAtom(map:Map<String, Term>, key:String, value:Term):Map<String, Term>;

	@:native("Map.has_key?")
	public static function hasAtom(map:Map<String, Term>, key:String):Bool;

	@:native("Map.delete")
	public static function deleteAtom(map:Map<String, Term>, key:String):Map<String, Term>;

	// Replace operations (similar to put but only if key exists)
	@:native("Map.replace")
	public static function replace<K, V>(map:Map<K, V>, key:K, value:V):Map<K, V>;

	@:native("Map.replace!")
	public static function replaceBang<K, V>(map:Map<K, V>, key:K, value:V):Map<K, V>; // Throws if key not found

	@:native("Map.replace_lazy")
	public static function replaceLazy<K, V>(map:Map<K, V>, key:K, func:V->V):Map<K, V>;
}
#end
