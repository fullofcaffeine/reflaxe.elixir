defmodule Main do
  def main() do
    # Simple counting loop - recursive function
    defp count_to_five(i) when i < 5 do
      count_to_five(i + 1)
    end
    defp count_to_five(i), do: i
    i = count_to_five(0)

    # Another counting loop
    defp count_to_three(j) when j < 3 do
      count_to_three(j + 1)
    end
    defp count_to_three(j), do: j
    j = count_to_three(0)

    # Counter that counts down
    defp count_down(counter) when counter > 0 do
      count_down(counter - 1)
    end
    defp count_down(counter), do: counter
    counter = count_down(10)

    # Collect even numbers with continue-like behavior
    evens = for k <- 1..10, rem(k, 2) == 0, do: k

    # Count with early termination
    defp count_until_ten(count) when count < 10 do
      count_until_ten(count + 1)
    end
    defp count_until_ten(count), do: count
    count = count_until_ten(0)

    # Nested loops would require more context
    outer = 0

    # Complex condition loop
    defp complex_loop(a, b) when a < 5 and b > 5 do
      complex_loop(a + 1, b - 1)
    end
    defp complex_loop(a, b), do: {a, b}
    {a, b} = complex_loop(0, 10)

    # Do-while with break
    defp do_while_loop(x) do
      new_x = x + 1
      if new_x == 5 do
        new_x
      else
        do_while_loop(new_x)
      end
    end
    x = do_while_loop(0)

    Log.trace("Final i: #{i}", %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "main"})
    Log.trace("Final j: #{j}", %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "main"})
    Log.trace("Final counter: #{counter}", %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "main"})
    Log.trace("Evens: #{inspect(evens)}", %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "main"})
    Log.trace("Count from infinite: #{count}", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "main"})
    Log.trace("Complex condition result: a=#{a}, b=#{b}", %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "main"})
    Log.trace("Do-while with break: x=#{x}", %{:file_name => "Main.hx", :line_number => 74, :class_name => "Main", :method_name => "main"})
  end
end