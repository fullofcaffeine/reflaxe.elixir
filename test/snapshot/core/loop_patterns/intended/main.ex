defmodule Main do
  defp main() do
    numbers = [1, 2, 3, 4, 5]
    evens = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, g, :ok}, fn _, {acc_numbers, acc_g, acc_state} ->
  if (acc_g < acc_numbers.length) do
    n = numbers[g]
    acc_g = acc_g + 1
    if (n rem 2 == 0), do: evens ++ [n]
    {:cont, {acc_numbers, acc_g, acc_state}}
  else
    {:halt, {acc_numbers, acc_g, acc_state}}
  end
end)
    doubled = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, g, :ok}, fn _, {acc_numbers, acc_g, acc_state} ->
  if (acc_g < acc_numbers.length) do
    n = numbers[g]
    acc_g = acc_g + 1
    doubled ++ [n * 2]
    {:cont, {acc_numbers, acc_g, acc_state}}
  else
    {:halt, {acc_numbers, acc_g, acc_state}}
  end
end)
    Log.trace("Evens: " <> Std.string(evens), %{:fileName => "Main.hx", :lineNumber => 19, :className => "Main", :methodName => "main"})
    Log.trace("Doubled: " <> Std.string(doubled), %{:fileName => "Main.hx", :lineNumber => 20, :className => "Main", :methodName => "main"})
  end
end