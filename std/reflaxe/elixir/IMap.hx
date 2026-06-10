package reflaxe.elixir;

/**
 * Canonical Elixir-target runtime boundary for `haxe.Constraints.IMap`.
 *
 * WHAT
 * - Defines the only supported unwrapping path for values that cross from Haxe `IMap`
 *   APIs into runtime helpers that need key/value pairs.
 *
 * WHY
 * - Plain Elixir maps (`%{}`) are the canonical representation for native
 *   `Map`/`StringMap`/`IntMap` values on this target.
 * - BEAM structs and Reflaxe runtime structs are also maps, so callers must not
 *   infer map semantics by shape-sniffing arbitrary `%{}` terms.
 *
 * HOW
 * - `unwrap/1` accepts plain Elixir maps or pre-normalized pair lists.
 * - Tree-backed or custom `IMap` implementations must pass key/value pairs
 *   produced by their own iterator implementation instead of passing the wrapper.
 *
 * EXAMPLES
 * - `%{"a" => 1}` becomes `[%{key: "a", value: 1}]`.
 * - `[{"a", 1}]` becomes `[%{key: "a", value: 1}]`.
 */
@:native("Reflaxe.Elixir.IMap")
class IMap {
	public static function unwrap<K, V>(mapOrPairs:Any):Array<{key:K, value:V}> {
		return untyped __elixir__('normalize_pair = fn
      {key, value} ->
        %{key: key, value: value}
      %{key: _key, value: _value} = pair ->
        pair
      other ->
        raise ArgumentError,
          message: "expected IMap pair list entries to be {key, value} tuples or %{key: key, value: value} maps, got: " <> inspect(other)
    end
    cond do
      Kernel.is_list({0}) ->
        Enum.map({0}, normalize_pair)
      Kernel.is_map({0}) and not Map.has_key?({0}, :__struct__) and not Map.has_key?({0}, :__reflaxe_class__) ->
        Enum.map(Map.to_list({0}), fn {key, value} ->
          %{key: key, value: value}
        end)
      Kernel.is_map({0}) ->
        raise ArgumentError,
          message: "expected IMap runtime value to be a plain Elixir map or key/value pair list; custom IMap implementations must pass pre-normalized pairs"
      true ->
        raise ArgumentError,
          message: "expected IMap runtime value to be a plain Elixir map or key/value pair list, got: " <> inspect({0})
    end', mapOrPairs);
	}

	/**
	 * Builds the structural iterator value expected by Haxe `Map.iterator()`
	 * lowering over native Elixir map values.
	 */
	@:native("value_iterator")
	public static function valueIterator<K, V>(mapOrPairs:Any):Any {
		return untyped __elixir__('values =
      Reflaxe.Elixir.IMap.unwrap({0})
      |> Enum.map(fn %{value: value} -> value end)
    ref = make_ref()
    state_key = {ArrayIterator, ref}
    %{
      __reflaxe_class__: ArrayIterator,
      array: values,
      ref: ref,
      current: 0,
      has_next: fn ->
        Process.get(state_key, 0) < length(values)
      end,
      next: fn ->
        index = Process.get(state_key, 0)
        Process.put(state_key, index + 1)
        Enum.at(values, index)
      end
    }', mapOrPairs);
	}

	/**
	 * Builds the structural iterator value expected by Haxe `keyValueIterator()`
	 * lowering while keeping native Elixir maps as the backing storage.
	 *
	 * Haxe's `KeyValueIterator` structural API calls `iterator.has_next.()` and
	 * `iterator.next.()` directly, so this helper owns the closure-backed cursor
	 * instead of routing through generated constructor state.
	 */
	@:native("key_value_iterator")
	public static function keyValueIterator<K, V>(mapOrPairs:Any):Any {
		return untyped __elixir__('pairs = Reflaxe.Elixir.IMap.unwrap({0})
    ref = make_ref()
    state_key = {MapKeyValueIterator, ref}
    %{
      __reflaxe_class__: MapKeyValueIterator,
      pairs: pairs,
      ref: ref,
      current: 0,
      has_next: fn ->
        Process.get(state_key, 0) < length(pairs)
      end,
      next: fn ->
        index = Process.get(state_key, 0)
        Process.put(state_key, index + 1)
        case Enum.at(pairs, index) do
          %{key: key, value: value} ->
            %{key: key, value: value}
          {key, value} ->
            %{key: key, value: value}
          _ ->
            %{key: nil, value: nil}
        end
      end
    }', mapOrPairs);
	}
}
