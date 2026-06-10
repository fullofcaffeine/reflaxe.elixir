defmodule Reflaxe.Elixir.IMap do
  def unwrap(map_or_pairs) do
    normalize_pair = fn
      {key, value} ->
        %{key: key, value: value}
      %{key: _key, value: _value} = pair ->
        pair
      other ->
        raise ArgumentError,
          message: "expected IMap pair list entries to be {key, value} tuples or %{key: key, value: value} maps, got: " <> inspect(other)
    end
    cond do
      Kernel.is_list(map_or_pairs) ->
        Enum.map(map_or_pairs, normalize_pair)
      Kernel.is_map(map_or_pairs) and not Map.has_key?(map_or_pairs, :__struct__) and not Map.has_key?(map_or_pairs, :__reflaxe_class__) ->
        Enum.map(Map.to_list(map_or_pairs), fn {key, value} ->
          %{key: key, value: value}
        end)
      Kernel.is_map(map_or_pairs) ->
        raise ArgumentError,
          message: "expected IMap runtime value to be a plain Elixir map or key/value pair list; custom IMap implementations must pass pre-normalized pairs"
      true ->
        raise ArgumentError,
          message: "expected IMap runtime value to be a plain Elixir map or key/value pair list, got: " <> inspect(map_or_pairs)
    end
  end
end
