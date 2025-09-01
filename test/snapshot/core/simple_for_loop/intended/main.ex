defmodule Main do
  def main() do
    fruits = ["apple", "banana", "orange"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < fruits.length) do
  fruit = fruits[g]
  g + 1
  Log.trace("For: " + fruit, %{:fileName => "Main.hx", :lineNumber => 10, :className => "Main", :methodName => "main"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (i < fruits.length) do
  Log.trace("While: " + fruits[i], %{:fileName => "Main.hx", :lineNumber => 16, :className => "Main", :methodName => "main"})
  i + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
end