defmodule Main do
  def main() do
    fruits = ["apple", "banana", "orange"]
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fruits}, fn _, {fruits} ->
  if 0 < length(fruits) do
    fruit = fruits[0]
    0 + 1
    Log.trace("For: " <> fruit, %{:file_name => "Main.hx", :line_number => 10, :class_name => "Main", :method_name => "main"})
    {:cont, {fruits}}
  else
    {:halt, {fruits}}
  end
end)
    i = 0
    Enum.each(0..(fruits.length - 1), fn i ->
  Log.trace("While: " <> fruits[i], %{:file_name => "Main.hx", :line_number => 16, :class_name => "Main", :method_name => "main"})
  i + 1
end)
  end
end