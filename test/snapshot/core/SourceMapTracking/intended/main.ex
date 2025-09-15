defmodule Main do
  def main() do
    test_basic_tracking()
    test_complex_expressions()
    test_class_tracking()
  end
  defp test_basic_tracking() do
    x = 10
    y = 20
    result = x + y
    Log.trace("Result: #{result}", %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "testBasicTracking"})
  end
  defp test_complex_expressions() do
    items = [1, 2, 3, 4, 5]
    doubled = Enum.map(items, fn item -> item * 2 end)
    is_even = fn n -> rem(n, 2) == 0 end

    Enum.each(doubled, fn item ->
      if is_even.(item) do
        Log.trace("Even: #{item}", %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "testComplexExpressions"})
      else
        Log.trace("Odd: #{item}", %{:file_name => "Main.hx", :line_number => 49, :class_name => "Main", :method_name => "testComplexExpressions"})
      end
    end)
  end
  defp test_class_tracking() do
    calc = Calculator.new()
    calc.add(5)
    calc.multiply(2)
    Log.trace("Calculator result: #{calc.get_value()}", %{:file_name => "Main.hx", :line_number => 58, :class_name => "Main", :method_name => "testClassTracking"})
  end
end