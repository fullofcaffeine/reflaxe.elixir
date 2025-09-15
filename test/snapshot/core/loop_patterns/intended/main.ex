defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]

    # Filter evens using comprehension
    evens = for n <- numbers, rem(n, 2) == 0, do: n

    # Map to double using comprehension
    doubled = for n <- numbers, do: n * 2

    Log.trace("Evens: #{inspect(evens)}", %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "main"})
    Log.trace("Doubled: #{inspect(doubled)}", %{:file_name => "Main.hx", :line_number => 20, :class_name => "Main", :method_name => "main"})
  end
end