defmodule MapKeyValueIterator do
  def new(map) do
    %{:map => map, :keys => Map.keys(map)}
  end
  def has_next(struct) do
    struct.keys.hasNext()
  end
  def next(struct) do
    key = struct.keys.next()
    %{:value => Map.get(struct.map, key), :key => key}
  end
end