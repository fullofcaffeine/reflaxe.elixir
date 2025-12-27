defmodule Main do
  def main() do
    fruits = ["apple", "banana", "orange"]
    _g = 0
    _ = Enum.each(fruits, fn _ -> nil end)
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, fn _, {i} ->
      if (i < length(fruits)) do
        _old_i = i
        i = i + 1
        {:cont, {i}}
      else
        {:halt, {i}}
      end
    end)
    nil
  end
end
