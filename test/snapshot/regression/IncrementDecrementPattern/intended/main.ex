defmodule Main do
  def main() do
    test_while_loop()
    test_for_loop()
  end

  defp test_while_loop() do
    # Use recursive function for while loop pattern
    while_loop(10, 0)
  end

  defp while_loop(k, pos) when k > 0 do
    Log.trace("Processing at position: #{pos}", %{:file_name => "Main.hx", :line_number => 18, :class_name => "Main", :method_name => "testWhileLoop"})
    while_loop(k - 1, pos + 1)
  end

  defp while_loop(k, pos) do
    Log.trace("Final: k=#{k}, pos=#{pos}", %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "testWhileLoop"})
  end

  defp test_for_loop() do
    # Use Enum.each for iteration with side effects
    count = Enum.reduce(0..4, 0, fn i, acc ->
      Log.trace("Iteration: #{i}", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testForLoop"})
      acc + 1
    end)

    Log.trace("Total count: #{count}", %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "testForLoop"})
  end

  defp test_complex_loop() do
    data = [1, 2, 3, 4, 5]

    # Use Enum.sum for summing a list
    sum = Enum.sum(data)

    Log.trace("Sum: #{sum}", %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "testComplexLoop"})
  end
end