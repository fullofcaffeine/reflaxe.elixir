defmodule Main do
  def main() do
    message = "Testing composition architecture"
    Log.trace(message, %{:fileName => "Main.hx", :lineNumber => 23, :className => "Main", :methodName => "main"})
    __elixir__.call("IO.puts(\"Injection still works\")")
    numbers = [1, 2, 3, 4, 5]
    doubled = g = []
g1 = 0
g2 = numbers
Enum.reduce_while(1..:infinity, :ok, fn _, acc -> if (g1 < g2.length) do
  v = g2[g1]
  g1 + 1
  g.push(v * 2)
  {:cont, acc}
else
  {:halt, acc}
end end)
g
    if (doubled.length > 0) do
      g = 0
      Enum.reduce_while(1..:infinity, :ok, fn _, acc -> if (g < doubled.length) do
  n = doubled[g]
  g + 1
  Log.trace("Doubled: " + n, %{:fileName => "Main.hx", :lineNumber => 36, :className => "Main", :methodName => "main"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    end
  end
end