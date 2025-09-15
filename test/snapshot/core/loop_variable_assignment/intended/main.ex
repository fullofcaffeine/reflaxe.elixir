defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]

    # Simple map operation
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    Log.trace("Doubled: #{inspect(doubled)}", %{:file_name => "Main.hx", :line_number => 9, :class_name => "Main", :method_name => "main"})

    # Filter operation
    evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Evens: #{inspect(evens)}", %{:file_name => "Main.hx", :line_number => 13, :class_name => "Main", :method_name => "main"})

    # Building pairs with comprehension
    x = 2  # Final value after assignments
    pairs = for y <- ["a", "b", "a", "b"], do: %{x: x, y: y}
    Log.trace("Pairs: #{inspect(pairs)}", %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "main"})

    # Collecting squares with comprehension
    collected = for i <- 0..4, do: i * i
    Log.trace("Collected squares: #{inspect(collected)}", %{:file_name => "Main.hx", :line_number => 28, :class_name => "Main", :method_name => "main"})

    # Do-while style collection
    results = for j <- 0..2, do: j
    Log.trace("Do-while results: #{inspect(results)}", %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "main"})

    # Sum with reduce
    sum = Enum.reduce(numbers, 0, fn n, acc -> acc + n end)
    Log.trace("Sum: #{sum}", %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "main"})

    # Filter with comprehension
    output = for n <- numbers, n > 2, do: n
    Log.trace("Filtered output: #{inspect(output)}", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "main"})
  end
end