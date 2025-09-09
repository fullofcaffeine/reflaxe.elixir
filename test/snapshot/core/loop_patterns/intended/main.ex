defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    evens = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, numbers, :ok}, fn _, {acc_g, acc_numbers, acc_state} ->
  if (acc_g < length(acc_numbers)) do
    n = numbers[g]
    acc_g = acc_g + 1
    if (rem(n, 2) == 0), do: evens ++ [n]
    {:cont, {acc_g, acc_numbers, acc_state}}
  else
    {:halt, {acc_g, acc_numbers, acc_state}}
  end
end)
    doubled = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, numbers, :ok}, fn _, {acc_g, acc_numbers, acc_state} ->
  if (acc_g < length(acc_numbers)) do
    n = numbers[g]
    acc_g = acc_g + 1
    doubled ++ [n * 2]
    {:cont, {acc_g, acc_numbers, acc_state}}
  else
    {:halt, {acc_g, acc_numbers, acc_state}}
  end
end)
    Log.trace("Evens: " <> Std.string(evens), %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "main"})
    Log.trace("Doubled: " <> Std.string(doubled), %{:file_name => "Main.hx", :line_number => 20, :class_name => "Main", :method_name => "main"})
  end
end