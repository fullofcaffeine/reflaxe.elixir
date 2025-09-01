defmodule Main do
  def main() do
    message = "Testing composition architecture"
    Log.trace(message, %{:fileName => "Main.hx", :lineNumber => 26, :className => "Main", :methodName => "main"})
    IO.puts("Injection still works")
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    if (doubled.length > 0) do
      g = 0
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < doubled.length) do
  n = doubled[g]
  g + 1
  Log.trace("Doubled: " + n, %{:fileName => "Main.hx", :lineNumber => 39, :className => "Main", :methodName => "main"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    end
  end
end