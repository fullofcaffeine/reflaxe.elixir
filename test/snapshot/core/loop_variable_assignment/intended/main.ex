defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    g_value = 0
    _ = Enum.each(numbers, fn n -> [n * 2] end)
    doubled = []
    g_value = 0
    _ = Enum.each(numbers, fn n ->
  if (rem(n, 2) == 0), do: [n]
end)
    evens = []
    x = 1
    y = "a"
    [%{:x => x, :y => y}]
    y = "b"
    [%{:x => x, :y => y}]
    x = 2
    y = "a"
    [%{:x => x, :y => y}]
    y = "b"
    [%{:x => x, :y => y}]
    pairs = []
    i = 0
    collected = []
    {i, collected} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, []}, fn _, {i, collected} ->
      if (i < 5) do
        collected = collected ++ [i * i]
        old_i = i
        i = i + 1
        old_i
        {:cont, {i, collected}}
      else
        {:halt, {i, collected}}
      end
    end)
    nil
    j = 0
    results = []
    {j, results} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, []}, fn _, {j, results} ->
      if (j < 3) do
        results = results ++ [j]
        old_j = j
        j = j + 1
        old_j
        {:cont, {j, results}}
      else
        {:halt, {j, results}}
      end
    end)
    nil
    sum = 0
    _g = 0
    sum = Enum.reduce(numbers, sum, fn n, sum_acc -> sum_acc + n end)
    output = []
    _g = 0
    output = Enum.reduce(numbers, output, fn n, output_acc ->
      if (n > 2) do
        output_acc = Enum.concat(output_acc, [n])
        output_acc
      else
        output_acc
      end
    end)
    nil
  end
end
