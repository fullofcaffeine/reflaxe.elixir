defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    g = []
    g1 = 0
    doubled = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, g1, :ok}, fn _, {acc_numbers, acc_g1, acc_state} ->
  n = acc_numbers[acc_g1]
  if (acc_g1 < length(acc_numbers)) do
    acc_g1 = acc_g1 + 1
    g = g ++ [n * 2]
    {:cont, {acc_numbers, acc_g1, acc_state}}
  else
    {:halt, {acc_numbers, acc_g1, acc_state}}
  end
end)
g
    Log.trace("Doubled: " <> Std.string(doubled), %{:file_name => "Main.hx", :line_number => 9, :class_name => "Main", :method_name => "main"})
    g = []
    g1 = 0
    evens = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, g1, :ok}, fn _, {acc_numbers, acc_g1, acc_state} ->
  n = acc_numbers[acc_g1]
  if (acc_g1 < length(acc_numbers)) do
    acc_g1 = acc_g1 + 1
    if rem(n, 2) == 0 do
      g = g ++ [n]
    end
    {:cont, {acc_numbers, acc_g1, acc_state}}
  else
    {:halt, {acc_numbers, acc_g1, acc_state}}
  end
end)
g
    Log.trace("Evens: " <> Std.string(evens), %{:file_name => "Main.hx", :line_number => 13, :class_name => "Main", :method_name => "main"})
    g = []
    x = 1
    x = 2
    pairs = g = g ++ [%{:x => x, :y => ("a")}]
g = g ++ [%{:x => x, :y => ("b")}]
g = g ++ [%{:x => x, :y => ("a")}]
g = g ++ [%{:x => x, :y => ("b")}]
g
    Log.trace("Pairs: " <> Std.string(pairs), %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "main"})
    i = 0
    collected = []
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, :ok}, fn _, {acc_i, acc_state} ->
  if (acc_i < 5) do
    collected = collected ++ [acc_i * acc_i]
    acc_i = acc_i + 1
    {:cont, {acc_i, acc_state}}
  else
    {:halt, {acc_i, acc_state}}
  end
end)
    Log.trace("Collected squares: " <> Std.string(collected), %{:file_name => "Main.hx", :line_number => 28, :class_name => "Main", :method_name => "main"})
    j = 0
    results = []
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j, :ok}, fn _, {acc_j, acc_state} ->
  if (acc_j < 3) do
    results = results ++ [acc_j]
    acc_j = acc_j + 1
    {:cont, {acc_j, acc_state}}
  else
    {:halt, {acc_j, acc_state}}
  end
end)
    Log.trace("Do-while results: " <> Std.string(results), %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "main"})
    sum = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, sum, g, :ok}, fn _, {acc_numbers, acc_sum, acc_g, acc_state} -> nil end)
    Log.trace("Sum: " <> Kernel.to_string(sum), %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "main"})
    output = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, g, :ok}, fn _, {acc_numbers, acc_g, acc_state} ->
  if (acc_g < length(acc_numbers)) do
    n = acc_numbers[acc_g]
    acc_g = acc_g + 1
    if (n > 2) do
      output = output ++ [n]
    end
    {:cont, {acc_numbers, acc_g, acc_state}}
  else
    {:halt, {acc_numbers, acc_g, acc_state}}
  end
end)
    Log.trace("Filtered output: " <> Std.string(output), %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "main"})
  end
end