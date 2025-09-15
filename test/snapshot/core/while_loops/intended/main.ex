defmodule Main do
  def main() do
    # Simple counting loop - use Enum.reduce
    i = Enum.reduce(1..5, 0, fn _, acc -> acc + 1 end)

    # Another counting loop
    j = Enum.reduce(1..3, 0, fn _, acc -> acc + 1 end)

    # Counter that counts down
    counter = Enum.reduce(1..10, 10, fn _, acc -> acc - 1 end)

    # Collect even numbers with continue-like behavior
    evens = for k <- 1..10, rem(k, 2) == 0, do: k

    # Count with early termination - use Enum.reduce_while
    count = Enum.reduce_while(1..100, 0, fn _, acc ->
      new_count = acc + 1
      if new_count == 10 do
        {:halt, new_count}
      else
        {:cont, new_count}
      end
    end)

    # Nested loops (simplified since original has undefined 'inner')
    outer = 0  # Would need more context for proper nested implementation

    # Complex condition loop
    {a, b} = Enum.reduce_while(1..10, {0, 10}, fn _, {a, b} ->
      if a < 5 && b > 5 do
        {:cont, {a + 1, b - 1}}
      else
        {:halt, {a, b}}
      end
    end)

    # Do-while with break
    x = Enum.reduce_while(1..10, 0, fn _, acc ->
      new_x = acc + 1
      if new_x == 5 do
        {:halt, new_x}
      else
        {:cont, new_x}
      end
    end)

    Log.trace("Final i: " <> Kernel.to_string(i), %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "main"})
    Log.trace("Final j: " <> Kernel.to_string(j), %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "main"})
    Log.trace("Final counter: " <> Kernel.to_string(counter), %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "main"})
    Log.trace("Evens: " <> Std.string(evens), %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "main"})
    Log.trace("Count from infinite: " <> Kernel.to_string(count), %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "main"})
    Log.trace("Complex condition result: a=" <> Kernel.to_string(a) <> ", b=" <> Kernel.to_string(b), %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "main"})
    Log.trace("Do-while with break: x=" <> Kernel.to_string(x), %{:file_name => "Main.hx", :line_number => 74, :class_name => "Main", :method_name => "main"})
  end
end