defmodule Main do
  def main() do
    fruits = ["apple", "banana", "orange"]
    _ = Enum.each(fruits, (fn -> fn _ ->
    nil
end end).())
    i = 0
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fruits, i}, (fn -> fn _, {fruits, i} ->
  if (i < length(fruits)) do
    i + 1
    {:cont, {fruits, i}}
  else
    {:halt, {fruits, i}}
  end
end end).())
  end
end
