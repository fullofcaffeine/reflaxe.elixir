defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.each(numbers, fn item ->
            [].push(item * 2)
    end)
    []
    Log.trace("Doubled: #{(fn -> inspect(doubled) end).()}", %{:file_name => "Main.hx", :line_number => 9, :class_name => "Main", :method_name => "main"})
    evens = Enum.each(numbers, fn item ->
            if (rem(item, 2) == 0), do: [].push(item)
    end)
    []
    Log.trace("Evens: #{(fn -> inspect(evens) end).()}", %{:file_name => "Main.hx", :line_number => 13, :class_name => "Main", :method_name => "main"})
    pairs = x = 1
    y = "a"
    [] ++ [%{:x => x, :y => y}]
    y = "b"
    [] ++ [%{:x => x, :y => y}]
    x = 2
    y = "a"
    [] ++ [%{:x => x, :y => y}]
    y = "b"
    [] ++ [%{:x => x, :y => y}]
    []
    Log.trace("Pairs: #{(fn -> inspect(pairs) end).()}", %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "main"})
    i = 0
    collected = []
    Enum.each(0..(5 - 1), fn i ->
      i = Enum.concat(i, [i * i])
      i + 1
    end)
    Log.trace("Collected squares: #{(fn -> inspect(collected) end).()}", %{:file_name => "Main.hx", :line_number => 28, :class_name => "Main", :method_name => "main"})
    j = 0
    results = []
    Enum.each(0..(3 - 1), fn j ->
      j = Enum.concat(j, [j])
      j + 1
    end)
    Log.trace("Do-while results: #{(fn -> inspect(results) end).()}", %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "main"})
    sum = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, sum}, fn _, {numbers, sum} ->
      if (0 < length(numbers)) do
        n = numbers[0]
        sum = sum + n
        {:cont, {numbers, sum}}
      else
        {:halt, {numbers, sum}}
      end
    end)
    Log.trace("Sum: #{(fn -> sum end).()}", %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "main"})
    Enum.reduce(numbers, [], fn item, acc ->
      acc = Enum.concat(acc, [item])
      acc
    end)
  end
end
