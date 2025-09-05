defmodule Main do
  defp main() do
    array = [1, 2, 3, 4, 5]
    result = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {array, g, :ok}, fn _, {acc_array, acc_g, acc_state} ->
  if (acc_g < acc_array.length) do
    item = array[g]
    acc_g = acc_g + 1
    if (item > 2), do: result ++ [item * 2]
    {:cont, {acc_array, acc_g, acc_state}}
  else
    {:halt, {acc_array, acc_g, acc_state}}
  end
end)
    g = 0
    g1 = array.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, g, :ok}, fn _, {acc_g1, acc_g, acc_g, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    acc_g = 0
    acc_g1 = array.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {acc_g1, acc_g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < acc_g1) do
    j = acc_g = acc_g + 1
    if (array[i] < array[j]), do: result ++ [array[i] + array[j]]
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    {:cont, {acc_g1, acc_g, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_g, acc_state}}
  end
end)
    filtered = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {array, g, :ok}, fn _, {acc_array, acc_g, acc_state} ->
  if (acc_g < acc_array.length) do
    x = array[g]
    acc_g = acc_g + 1
    if (x rem 2 == 0), do: filtered ++ [x]
    {:cont, {acc_array, acc_g, acc_state}}
  else
    {:halt, {acc_array, acc_g, acc_state}}
  end
end)
    functions = []
    functions = functions ++ [fn -> 0 end]
    functions = functions ++ [fn -> 1 end]
    functions = functions ++ [fn -> 2 end]
    i = 100
    result = result ++ [0]
    result = result ++ [1]
    result = result ++ [2]
    result = result ++ [i]
    sum = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, array, g, :ok}, fn _, {acc_sum, acc_array, acc_g, acc_state} ->
  if (acc_g < acc_array.length) do
    n = array[g]
    acc_g = acc_g + 1
    acc_sum = acc_sum + n
    {:cont, {acc_sum, acc_array, acc_g, acc_state}}
  else
    {:halt, {acc_sum, acc_array, acc_g, acc_state}}
  end
end)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, g, array, :ok}, fn _, {acc_sum, acc_g, acc_array, acc_state} ->
  if (acc_g < acc_array.length) do
    n = array[g]
    acc_g = acc_g + 1
    acc_sum = (acc_sum - n)
    {:cont, {acc_sum, acc_g, acc_array, acc_state}}
  else
    {:halt, {acc_sum, acc_g, acc_array, acc_state}}
  end
end)
    Log.trace(result, %{:fileName => "Main.hx", :lineNumber => 54, :className => "Main", :methodName => "main"})
    Log.trace(filtered, %{:fileName => "Main.hx", :lineNumber => 55, :className => "Main", :methodName => "main"})
    Log.trace("Functions count: " <> functions.length, %{:fileName => "Main.hx", :lineNumber => 56, :className => "Main", :methodName => "main"})
    Log.trace("Sum after reuse: " <> sum, %{:fileName => "Main.hx", :lineNumber => 57, :className => "Main", :methodName => "main"})
  end
end