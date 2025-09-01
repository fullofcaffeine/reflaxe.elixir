defmodule Container do
  def new() do
    %{:items => []}
  end
  def add(struct, item) do
    struct.items.push(item)
  end
  def get(struct, index) do
    struct.items[index]
  end
  def size(struct) do
    struct.items.length
  end
  def map(struct, fn) do
    result = Container.new()
    g = 0
    g1 = struct.items
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  item = g1[g]
  g + 1
  result.add(fn.(item))
  {:cont, acc}
else
  {:halt, acc}
end end)
    result
  end
end