package haxe.ds;

import haxe.Constraints.IMap;

/**
 * Map (Elixir target)
 *
 * Multi-type abstract over `haxe.Constraints.IMap` that selects an implementation based on the key type.
 *
 * The Elixir backend keeps the upstream public API shape, but its specialization casts preserve an
 * existing receiver when one is present. Map instances are represented as native `%{}` terms and the
 * AST pipeline lowers operations to idiomatic `Map.*` / `Enum.*` calls.
 */
@:transitive
@:multiType(@:followWithAbstracts K)
abstract Map<K, V>(IMap<K, V>) {
	public function new();

	public inline function set(key:K, value:V):Void
		this.set(key, value);

	@:arrayAccess public inline function get(key:K):Null<V>
		return this.get(key);

	public inline function exists(key:K):Bool
		return this.exists(key);

	public inline function remove(key:K):Bool
		return this.remove(key);

	public inline function keys():Iterator<K> {
		return this.keys();
	}

	public inline function iterator():Iterator<V> {
		return this.iterator();
	}

	public inline function keyValueIterator():KeyValueIterator<K, V> {
		return this.keyValueIterator();
	}

	public inline function copy():Map<K, V> {
		return cast this.copy();
	}

	public inline function toString():String {
		return this.toString();
	}

	public inline function clear():Void {
		this.clear();
	}

	@:arrayAccess @:noCompletion public inline function arrayWrite(k:K, v:V):V {
		this.set(k, v);
		return v;
	}

	@:to static inline function toStringMap<K:String, V>(t:IMap<K, V>):StringMap<V> {
		return t == null ? new StringMap<V>() : cast t;
	}

	@:to static inline function toIntMap<K:Int, V>(t:IMap<K, V>):IntMap<V> {
		return t == null ? new IntMap<V>() : cast t;
	}

	@:to static inline function toEnumValueMapMap<K:EnumValue, V>(t:IMap<K, V>):EnumValueMap<K, V> {
		return t == null ? new EnumValueMap<K, V>() : cast t;
	}

	@:to static inline function toObjectMap<K:{}, V>(t:IMap<K, V>):ObjectMap<K, V> {
		return cast t;
	}

	@:from static inline function fromStringMap<V>(map:StringMap<V>):Map<String, V> {
		return cast map;
	}

	@:from static inline function fromIntMap<V>(map:IntMap<V>):Map<Int, V> {
		return cast map;
	}

	@:from static inline function fromObjectMap<K:{}, V>(map:ObjectMap<K, V>):Map<K, V> {
		return cast map;
	}
}
