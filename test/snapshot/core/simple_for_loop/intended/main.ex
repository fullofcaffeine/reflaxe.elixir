defmodule Main do
  def main() do
    fruits = ["apple", "banana", "orange"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fruits, g, :ok}, fn _, {acc_fruits, acc_g, acc_state} ->
  if (acc_g < length(acc_fruits)) do
    fruit = acc_fruits[acc_g]
    acc_g = acc_g + 1
    Log.trace("For: " <> fruit, %{:file_name => "Main.hx", :line_number => 10, :class_name => "Main", :method_name => "main"})
    {:cont, {acc_fruits, acc_g, acc_state}}
  else
    {:halt, {acc_fruits, acc_g, acc_state}}
  end
end)
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fruits, i, :ok}, fn _, {acc_fruits, acc_i, acc_state} ->
  if (acc_i < length(acc_fruits)) do
    Log.trace("While: " <> acc_fruits[acc_i], %{:file_name => "Main.hx", :line_number => 16, :class_name => "Main", :method_name => "main"})
    acc_i = acc_i + 1
    {:cont, {acc_fruits, acc_i, acc_state}}
  else
    {:halt, {acc_fruits, acc_i, acc_state}}
  end
end)
  end
end