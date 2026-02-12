package haxe;

import haxe.iterators.DynamicAccessIterator;
import haxe.iterators.DynamicAccessKeyValueIterator;

/**
 * DynamicAccess (Elixir target)
 *
 * WHAT
 * - Map-like access wrapper over dynamic terms keyed by strings.
 *
 * WHY
 * - Commonly used to work with JSON-decoded payloads and other dynamic maps while keeping
 *   a typed surface in Haxe.
 *
 * HOW
 * - Delegates to `Reflect.*` for non-JS targets.
 * - On Elixir, `Reflect` supports both string keys (e.g. Jason-decoded JSON) and atom keys
 *   (e.g. Haxe object literals), so `DynamicAccess` works across both representations.
 */
abstract DynamicAccess<T>(Dynamic<T>) from Dynamic<T> to Dynamic<T> {
	public inline function new() {
		this = {};
	}

	@:arrayAccess
	public inline function get(key:String):Null<T> {
		#if js
		return untyped this[key];
		#else
		return Reflect.field(this, key);
		#end
	}

	@:arrayAccess
	public inline function set(key:String, value:T):T {
		#if js
		return untyped this[key] = value;
		#else
		Reflect.setField(this, key, value);
		return value;
		#end
	}

	public inline function exists(key:String):Bool {
		return Reflect.hasField(this, key);
	}

	public inline function remove(key:String):Bool {
		return Reflect.deleteField(this, key);
	}

	public inline function keys():Array<String> {
		return Reflect.fields(this);
	}

	public inline function copy():DynamicAccess<T> {
		return Reflect.copy(this);
	}

	public inline function iterator():DynamicAccessIterator<T> {
		return new DynamicAccessIterator(this);
	}

	public inline function keyValueIterator():DynamicAccessKeyValueIterator<T> {
		return new DynamicAccessKeyValueIterator(this);
	}
}
