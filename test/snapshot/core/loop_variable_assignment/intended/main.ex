defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    doubled = g = []
g1 = 0
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g1 < numbers.length) do
  n = numbers[g1]
  g1 + 1
  g.push(n * 2)
  {:cont, acc}
else
  {:halt, acc}
end end)
g
    Log.trace("Doubled: " + Std.string(doubled), %{:fileName => "Main.hx", :lineNumber => 9, :className => "Main", :methodName => "main"})
    evens = g = []
g1 = 0
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g1 < numbers.length) do
  n = numbers[g1]
  g1 + 1
  if (n rem 2 == 0), do: g.push(n)
  {:cont, acc}
else
  {:halt, acc}
end end)
g
    Log.trace("Evens: " + Std.string(evens), %{:fileName => "Main.hx", :lineNumber => 13, :className => "Main", :methodName => "main"})
    pairs = g = []
x = 1
y = "a"
g.push(%{:x => x, :y => y})
y = "b"
g.push(%{:x => x, :y => y})
x = 2
y = "a"
g.push(%{:x => x, :y => y})
y = "b"
g.push(%{:x => x, :y => y})
g
    Log.trace("Pairs: " + Std.string(pairs), %{:fileName => "Main.hx", :lineNumber => 19, :className => "Main", :methodName => "main"})
    i = 0
    collected = []
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (i < 5) do
  collected.push(i * i)
  i + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Collected squares: " + Std.string(collected), %{:fileName => "Main.hx", :lineNumber => 28, :className => "Main", :methodName => "main"})
    j = 0
    results = []
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (j < 3) do
  results.push(j)
  j + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Do-while results: " + Std.string(results), %{:fileName => "Main.hx", :lineNumber => 37, :className => "Main", :methodName => "main"})
    sum = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < numbers.length) do
  n = numbers[g]
  g + 1
  sum = sum + n
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Sum: " + sum, %{:fileName => "Main.hx", :lineNumber => 44, :className => "Main", :methodName => "main"})
    output = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < numbers.length) do
  n = numbers[g]
  g + 1
  if (n > 2), do: output.push(n)
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Filtered output: " + Std.string(output), %{:fileName => "Main.hx", :lineNumber => 53, :className => "Main", :methodName => "main"})
  end
end