defmodule Main do
  def main() do
    fruits = ["apple", "banana", "orange"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, fruits, :ok}, fn _, {acc_g, acc_fruits, acc_state} ->
  if (acc_g < length(acc_fruits)) do
    fruit = fruits[g]
    acc_g = acc_g + 1
    Log.trace("For: " <> fruit, %{:file_name => "Main.hx", :line_number => 10, :class_name => "Main", :method_name => "main"})
    {:cont, {acc_g, acc_fruits, acc_state}}
  else
    {:halt, {acc_g, acc_fruits, acc_state}}
  end
end)
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, fruits, :ok}, fn _, {acc_i, acc_fruits, acc_state} ->
  if (acc_i < length(acc_fruits)) do
    Log.trace("While: " <> fruits[i], %{:file_name => "Main.hx", :line_number => 16, :class_name => "Main", :method_name => "main"})
    acc_i = acc_i + 1
    {:cont, {acc_i, acc_fruits, acc_state}}
  else
    {:halt, {acc_i, acc_fruits, acc_state}}
  end
end)
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()