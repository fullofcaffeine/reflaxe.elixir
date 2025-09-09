defmodule MapKeyValueIterator do
  @map nil
  @keys nil
  def has_next(struct) do
    struct.keys.has_next()
  end
  def next(struct) do
    key = struct.keys.next()
    %{:value => Map.get(struct.map, key), :key => key}
  end
end