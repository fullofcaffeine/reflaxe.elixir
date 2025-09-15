defmodule Main do
  def main() do
    array = [1, 2, 3, 4, 5]

    # Filter and map with comprehension
    result = for item <- array, item > 2, do: item * 2

    # While loop converted to range iteration (no-op in this case)
    # Original loop doesn't do anything meaningful

    # Filter evens with comprehension
    filtered = for x <- array, rem(x, 2) == 0, do: x

    # Create functions with comprehension
    functions = for i <- 0..2, do: fn -> i end

    # Build result with additional values
    i = 100
    result = result ++ [0, 1, 2, i]

    # Sum with reduce (loops appear to be no-ops)
    sum = Enum.reduce(array, 0, fn n, acc -> acc + n end)

    Log.trace(result, %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "main"})
    Log.trace(filtered, %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "main"})
    Log.trace("Functions count: #{length(functions)}", %{:file_name => "Main.hx", :line_number => 56, :class_name => "Main", :method_name => "main"})
    Log.trace("Sum after reuse: #{sum}", %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "main"})
  end
end