defmodule Main do
  defp main() do
    array = [1, 2, 3, 4, 5]
    result = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < array.length) do
  item = array[g]
  g + 1
  if (item > 2), do: result.push(item * 2)
  {:cont, acc}
else
  {:halt, acc}
end end)
    g = 0
    g1 = array.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  g = 0
  g1 = array.length
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  j = g + 1
  if (array[i] < array[j]), do: result.push(array[i] + array[j])
  {:cont, acc}
else
  {:halt, acc}
end end)
  {:cont, acc}
else
  {:halt, acc}
end end)
    filtered = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < array.length) do
  x = array[g]
  g + 1
  if (x rem 2 == 0), do: filtered.push(x)
  {:cont, acc}
else
  {:halt, acc}
end end)
    functions = []
    functions.push(fn -> 0 end)
    functions.push(fn -> 1 end)
    functions.push(fn -> 2 end)
    i = 100
    result.push(0)
    result.push(1)
    result.push(2)
    result.push(i)
    sum = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < array.length) do
  n = array[g]
  g + 1
  sum = sum + n
  {:cont, acc}
else
  {:halt, acc}
end end)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < array.length) do
  n = array[g]
  g + 1
  sum = sum - n
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace(result, %{:fileName => "Main.hx", :lineNumber => 54, :className => "Main", :methodName => "main"})
    Log.trace(filtered, %{:fileName => "Main.hx", :lineNumber => 55, :className => "Main", :methodName => "main"})
    Log.trace("Functions count: " + functions.length, %{:fileName => "Main.hx", :lineNumber => 56, :className => "Main", :methodName => "main"})
    Log.trace("Sum after reuse: " + sum, %{:fileName => "Main.hx", :lineNumber => 57, :className => "Main", :methodName => "main"})
  end
end