defmodule Container do
  @items nil
  def add(struct, item) do
    struct.items ++ [item]
  end
  def get(_struct, index) do
    struct.items[index]
  end
  def size(struct) do
    length(struct.items)
  end
  def map(struct, fn_param) do
    result = Container.new()
    g = 0
    g1 = struct.items
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < length(acc_g1)) do
    item = g1[g]
    acc_g = acc_g + 1
    result.add(fn_param.(item))
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    result
  end
end