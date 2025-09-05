defmodule Main do
  def main() do
    message = "Testing composition architecture"
    Log.trace(message, %{:fileName => "Main.hx", :lineNumber => 26, :className => "Main", :methodName => "main"})
    IO.puts("Injection still works")
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    if (doubled.length > 0) do
      g = 0
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, doubled, :ok}, fn _, {acc_g, acc_doubled, acc_state} ->
  if (acc_g < acc_doubled.length) do
    n = doubled[g]
    acc_g = acc_g + 1
    Log.trace("Doubled: " <> n, %{:fileName => "Main.hx", :lineNumber => 39, :className => "Main", :methodName => "main"})
    {:cont, {acc_g, acc_doubled, acc_state}}
  else
    {:halt, {acc_g, acc_doubled, acc_state}}
  end
end)
    end
  end
end