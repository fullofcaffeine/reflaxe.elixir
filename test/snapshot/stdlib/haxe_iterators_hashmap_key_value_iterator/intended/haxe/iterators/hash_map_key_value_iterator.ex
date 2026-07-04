defmodule HashMapKeyValueIterator do
  def new(map_param) do
    struct = %{:__reflaxe_class__ => HashMapKeyValueIterator, :map => nil, :keys => nil}
    struct = %{struct | map: map_param}
    struct = %{struct | keys: apply(Map.get(map_param, :__reflaxe_class__) || Map.get(map_param, :__struct__), :keys, [map_param])}
    struct
  end
  def has_next(struct) do
    struct.keys.has_next.()
  end
  def next(struct) do
    key = struct.keys.next.()
    reflaxe_dispatch_receiver = struct.map
    %{key: key, value: apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :get, [reflaxe_dispatch_receiver, key])}
  end
end
