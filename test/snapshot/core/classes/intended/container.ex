defmodule Container do
  def new() do
    %{:items => []}
  end
  def add(struct, item) do
    struct.items ++ [item]
  end
  def get(_struct, _index) do
    struct.items[index]
  end
  def size(struct) do
    struct.items.length
  end
  def map(struct, fn) do
    result = Container.new()
    g = 0
    g1 = struct.items
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < acc_g1.length) do
    item = g1[g]
    acc_g = acc_g + 1
    result.add(fn.(item))
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    result
  end
end