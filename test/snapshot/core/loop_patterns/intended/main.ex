defmodule Main do
  defp main() do
    numbers = [1, 2, 3, 4, 5]
    evens = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < numbers.length) do
  n = numbers[g]
  g + 1
  if (n rem 2 == 0), do: evens.push(n)
  {:cont, acc}
else
  {:halt, acc}
end end)
    doubled = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < numbers.length) do
  n = numbers[g]
  g + 1
  doubled.push(n * 2)
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Evens: " + Std.string(evens), %{:fileName => "Main.hx", :lineNumber => 19, :className => "Main", :methodName => "main"})
    Log.trace("Doubled: " + Std.string(doubled), %{:fileName => "Main.hx", :lineNumber => 20, :className => "Main", :methodName => "main"})
  end
end