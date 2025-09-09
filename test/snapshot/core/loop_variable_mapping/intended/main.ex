defmodule Main do
  def main() do
    array = [1, 2, 3, 4, 5]
    result = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, array, :ok}, fn _, {acc_g, acc_array, acc_state} ->
  if (acc_g < length(acc_array)) do
    item = array[g]
    acc_g = acc_g + 1
    if (item > 2), do: result ++ [item * 2]
    {:cont, {acc_g, acc_array, acc_state}}
  else
    {:halt, {acc_g, acc_array, acc_state}}
  end
end)
    g = 0
    g1 = length(array)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g, g1, :ok}, fn _, {acc_g, acc_g, acc_g1, acc_state} -> nil end)
    filtered = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, array, :ok}, fn _, {acc_g, acc_array, acc_state} ->
  if (acc_g < length(acc_array)) do
    x = array[g]
    acc_g = acc_g + 1
    if (rem(x, 2) == 0), do: filtered ++ [x]
    {:cont, {acc_g, acc_array, acc_state}}
  else
    {:halt, {acc_g, acc_array, acc_state}}
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, g, array, :ok}, fn _, {acc_sum, acc_g, acc_array, acc_state} -> nil end)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, sum, array, :ok}, fn _, {acc_g, acc_sum, acc_array, acc_state} -> nil end)
    Log.trace(result, %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "main"})
    Log.trace(filtered, %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "main"})
    Log.trace("Functions count: " <> Kernel.to_string(length(functions)), %{:file_name => "Main.hx", :line_number => 56, :class_name => "Main", :method_name => "main"})
    Log.trace("Sum after reuse: " <> Kernel.to_string(sum), %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "main"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()