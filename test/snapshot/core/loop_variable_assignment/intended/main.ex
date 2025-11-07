defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    doubled = _ = Enum.each(numbers, (fn -> fn item ->
    [].push(item * 2)
end end).())
    []
    _ = Log.trace("Doubled: #{(fn -> inspect(doubled) end).()}", %{:file_name => "Main.hx", :line_number => 9, :class_name => "Main", :method_name => "main"})
    evens = _ = Enum.each(numbers, (fn -> fn item ->
    if (rem(item, 2) == 0), do: [].push(item)
end end).())
    []
    _ = Log.trace("Evens: #{(fn -> inspect(evens) end).()}", %{:file_name => "Main.hx", :line_number => 13, :class_name => "Main", :method_name => "main"})
    pairs = x = 1
    y = "a"
    _ = [%{:x => x, :y => y}]
    y = "b"
    _ = [%{:x => x, :y => y}]
    x = 2
    y = "a"
    _ = [%{:x => x, :y => y}]
    y = "b"
    _ = [%{:x => x, :y => y}]
    []
    _ = Log.trace("Pairs: #{(fn -> inspect(pairs) end).()}", %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "main"})
    i = 0
    collected = []
    _ = Enum.each(0..(5 - 1), (fn -> fn i ->
  i = Enum.concat(i, [i * i])
  i + 1
end end).())
    _ = Log.trace("Collected squares: #{(fn -> inspect(collected) end).()}", %{:file_name => "Main.hx", :line_number => 28, :class_name => "Main", :method_name => "main"})
    j = 0
    results = []
    _ = Enum.each(0..(3 - 1), (fn -> fn j ->
  j = Enum.concat(j, [j])
  j + 1
end end).())
    _ = Log.trace("Do-while results: #{(fn -> inspect(results) end).()}", %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "main"})
    sum = 0
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, sum}, (fn -> fn _, {numbers, sum} ->
  if (0 < length(numbers)) do
    n = numbers[0]
    sum = sum + n
    {:cont, {numbers, sum}}
  else
    {:halt, {numbers, sum}}
  end
end end).())
    _ = Log.trace("Sum: #{(fn -> sum end).()}", %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "main"})
    output = []
    _ = Enum.each(numbers, (fn -> fn item ->
    if (item > 2), do: item = Enum.concat(item, [item])
end end).())
    _ = Log.trace("Filtered output: #{(fn -> inspect(output) end).()}", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "main"})
  end
end
