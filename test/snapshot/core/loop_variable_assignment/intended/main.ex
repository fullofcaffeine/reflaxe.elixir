defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    g = []
    g1 = 0
    doubled = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, g1, :ok}, fn _, {acc_numbers, acc_g1, acc_state} ->
  n = numbers[g1]
  if (acc_g1 < acc_numbers.length) do
    acc_g1 = acc_g1 + 1
    g.push(n * 2)
    {:cont, {acc_numbers, acc_g1, acc_state}}
  else
    {:halt, {acc_numbers, acc_g1, acc_state}}
  end
end)
g
    Log.trace("Doubled: " <> Std.string(doubled), %{:fileName => "Main.hx", :lineNumber => 9, :className => "Main", :methodName => "main"})
    g = []
    g1 = 0
    evens = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, g1, :ok}, fn _, {acc_numbers, acc_g1, acc_state} ->
  n = numbers[g1]
  if (acc_g1 < acc_numbers.length) do
    acc_g1 = acc_g1 + 1
    if n rem 2 == 0, do: g.push(n)
    {:cont, {acc_numbers, acc_g1, acc_state}}
  else
    {:halt, {acc_numbers, acc_g1, acc_state}}
  end
end)
g
    Log.trace("Evens: " <> Std.string(evens), %{:fileName => "Main.hx", :lineNumber => 13, :className => "Main", :methodName => "main"})
    g = []
    x = 1
    y = "a"
    y = "b"
    x = 2
    y = "a"
    y = "b"
    pairs = g.push(%{:x => x, :y => y})
g.push(%{:x => x, :y => y})
g.push(%{:x => x, :y => y})
g.push(%{:x => x, :y => y})
g
    Log.trace("Pairs: " <> Std.string(pairs), %{:fileName => "Main.hx", :lineNumber => 19, :className => "Main", :methodName => "main"})
    i = 0
    collected = []
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, :ok}, fn _, {acc_i, acc_state} ->
  if (acc_i < 5) do
    collected.push(acc_i * acc_i)
    acc_i = acc_i + 1
    {:cont, {acc_i, acc_state}}
  else
    {:halt, {acc_i, acc_state}}
  end
end)
    Log.trace("Collected squares: " <> Std.string(collected), %{:fileName => "Main.hx", :lineNumber => 28, :className => "Main", :methodName => "main"})
    j = 0
    results = []
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j, :ok}, fn _, {acc_j, acc_state} ->
  if (acc_j < 3) do
    results.push(acc_j)
    acc_j = acc_j + 1
    {:cont, {acc_j, acc_state}}
  else
    {:halt, {acc_j, acc_state}}
  end
end)
    Log.trace("Do-while results: " <> Std.string(results), %{:fileName => "Main.hx", :lineNumber => 37, :className => "Main", :methodName => "main"})
    sum = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, sum, g, :ok}, fn _, {acc_numbers, acc_sum, acc_g, acc_state} ->
  if (acc_g < acc_numbers.length) do
    n = numbers[g]
    acc_g = acc_g + 1
    acc_sum = acc_sum + n
    {:cont, {acc_numbers, acc_sum, acc_g, acc_state}}
  else
    {:halt, {acc_numbers, acc_sum, acc_g, acc_state}}
  end
end)
    Log.trace("Sum: " <> sum, %{:fileName => "Main.hx", :lineNumber => 44, :className => "Main", :methodName => "main"})
    output = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, g, :ok}, fn _, {acc_numbers, acc_g, acc_state} ->
  if (acc_g < acc_numbers.length) do
    n = numbers[g]
    acc_g = acc_g + 1
    if (n > 2), do: output.push(n)
    {:cont, {acc_numbers, acc_g, acc_state}}
  else
    {:halt, {acc_numbers, acc_g, acc_state}}
  end
end)
    Log.trace("Filtered output: " <> Std.string(output), %{:fileName => "Main.hx", :lineNumber => 53, :className => "Main", :methodName => "main"})
  end
end