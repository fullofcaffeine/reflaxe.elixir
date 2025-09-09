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
    Log.trace("Result: " <> Kernel.to_string(result), %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "testBasicTracking"})
  end
  defp test_complex_expressions() do
    items = [1, 2, 3, 4, 5]
    doubled = Enum.map(items, fn item -> item * 2 end)
    is_even = fn n -> rem(n, 2) == 0 end
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, doubled, :ok}, fn _, {acc_g, acc_doubled, acc_state} ->
  if (acc_g < length(acc_doubled)) do
    item = doubled[g]
    acc_g = acc_g + 1
    if (is_even.(item)) do
      Log.trace("Even: " <> Kernel.to_string(item), %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "testComplexExpressions"})
    else
      Log.trace("Odd: " <> Kernel.to_string(item), %{:file_name => "Main.hx", :line_number => 49, :class_name => "Main", :method_name => "testComplexExpressions"})
    end
    {:cont, {acc_g, acc_doubled, acc_state}}
  else
    {:halt, {acc_g, acc_doubled, acc_state}}
  end
end)
  end
  defp test_class_tracking() do
    calc = Calculator.new()
    calc.add(5)
    calc.multiply(2)
    Log.trace("Calculator result: " <> Kernel.to_string(calc.get_value()), %{:file_name => "Main.hx", :line_number => 58, :class_name => "Main", :method_name => "testClassTracking"})
  end
end