/**
 * Map (Elixir target)
 *
 * Haxe std defines `Map<K,V>` as an alias of `haxe.ds.Map<K,V>`.
 * We mirror that here so the module exists under the Elixir-target std overrides.
 */
typedef Map<K, V> = haxe.ds.Map<K, V>;

@:dox(hide)
@:deprecated
typedef IMap<K, V> = haxe.Constraints.IMap<K, V>;

