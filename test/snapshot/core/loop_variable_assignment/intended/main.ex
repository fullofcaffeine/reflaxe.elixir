defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    _ = 0
    _ = Enum.each(numbers, fn n -> [] ++ [n * 2] end)
    doubled = []
    _ = 0
    _ = Enum.each(numbers, (fn -> fn n ->
  if (rem(n, 2) == 0), do: [] ++ [n]
end end).())
    evens = []
    x = 1
    y = "a"
    _ = [%{:x => x, :y => y}]
    y = "b"
    _ = [%{:x => x, :y => y}]
    x = 2
    y = "a"
    _ = [%{:x => x, :y => y}]
    y = "b"
    _ = [%{:x => x, :y => y}]
    pairs = []
    i = 0
    collected = []
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, collected}, (fn -> fn _, {i, collected} ->
      if (i < 5) do
        _ = collected ++ [i * i]
        (old_i = i
i = i + 1
old_i)
        {:cont, {i, collected}}
      else
        {:halt, {i, collected}}
      end
    end end).())
    nil
    j = 0
    results = []
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, results}, (fn -> fn _, {j, results} ->
      if (j < 3) do
        _ = results ++ [j]
        (old_j = j
j = j + 1
old_j)
        {:cont, {j, results}}
      else
        {:halt, {j, results}}
      end
    end end).())
    nil
    sum = 0
    _g = 0
    _ = Enum.each(numbers, fn n -> sum = sum + n end)
    output = []
    _g = 0
    _ = Enum.each(numbers, (fn -> fn n ->
  if (n > 2) do
    output = output ++ [n]
  end
end end).())
    nil
  end
end
