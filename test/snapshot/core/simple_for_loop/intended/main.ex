defmodule Main do
  def main() do
    fruits = ["apple", "banana", "orange"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, fruits, :ok}, fn _, {acc_g, acc_fruits, acc_state} ->
  if (acc_g < acc_fruits.length) do
    fruit = fruits[g]
    acc_g = acc_g + 1
    Log.trace("For: " <> fruit, %{:fileName => "Main.hx", :lineNumber => 10, :className => "Main", :methodName => "main"})
    {:cont, {acc_g, acc_fruits, acc_state}}
  else
    {:halt, {acc_g, acc_fruits, acc_state}}
  end
end)
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, fruits, :ok}, fn _, {acc_i, acc_fruits, acc_state} ->
  if (acc_i < acc_fruits.length) do
    Log.trace("While: " <> fruits[i], %{:fileName => "Main.hx", :lineNumber => 16, :className => "Main", :methodName => "main"})
    acc_i = acc_i + 1
    {:cont, {acc_i, acc_fruits, acc_state}}
  else
    {:halt, {acc_i, acc_fruits, acc_state}}
  end
end)
  end
end