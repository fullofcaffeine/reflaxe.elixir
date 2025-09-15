defmodule Main do
  def main() do
    fruits = ["apple", "banana", "orange"]

    # For loop using Enum.each
    Enum.each(fruits, fn fruit ->
      Log.trace("For: #{fruit}", %{:file_name => "Main.hx", :line_number => 10, :class_name => "Main", :method_name => "main"})
    end)

    # While loop using Enum.each with index
    Enum.each(fruits, fn fruit ->
      Log.trace("While: #{fruit}", %{:file_name => "Main.hx", :line_number => 16, :class_name => "Main", :method_name => "main"})
    end)
  end
end