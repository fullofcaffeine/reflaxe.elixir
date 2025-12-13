defmodule Container do
  def add(struct, item) do
    items = items ++ [item]
  end
  def get(struct, index) do
    struct.items[index]
  end
  def size(struct) do
    length(struct.items)
  end
  def map(struct, fn_param) do
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, (fn -> fn _, acc ->
  if (0 < length(struct.items)) do
    item = struct.items[0]
    result.add(fn_param.(item))
    {:cont, acc}
  else
    {:halt, acc}
  end
end end).())
    MyApp.Container.new()
  end
end
