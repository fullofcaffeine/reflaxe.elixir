defmodule Main do
  def main() do
    fruits = ["apple", "banana", "orange"]
    _ = Enum.each(fruits, (fn -> fn item ->
    Log.trace("For: " <> item, %{:file_name => "Main.hx", :line_number => 10, :class_name => "Main", :method_name => "main"})
end end).())
    i = 0
    _ = Enum.each(0..(length(fruits) - 1), (fn -> fn i ->
  Log.trace("While: " <> fruits[i], %{:file_name => "Main.hx", :line_number => 16, :class_name => "Main", :method_name => "main"})
  i + 1
end end).())
  end
end
