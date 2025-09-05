defmodule Main do
  defp main() do
    test_basic_tracking()
    test_complex_expressions()
    test_class_tracking()
  end
  defp test_basic_tracking() do
    x = 10
    y = 20
    result = x + y
    Log.trace("Result: " <> result, %{:fileName => "Main.hx", :lineNumber => 27, :className => "Main", :methodName => "testBasicTracking"})
  end
  defp test_complex_expressions() do
    items = [1, 2, 3, 4, 5]
    doubled = Enum.map(items, fn item -> item * 2 end)
    is_even = fn n -> n rem 2 == 0 end
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {doubled, g, :ok}, fn _, {acc_doubled, acc_g, acc_state} ->
  if (acc_g < acc_doubled.length) do
    item = doubled[g]
    acc_g = acc_g + 1
    if (is_even.(item)) do
      Log.trace("Even: " <> item, %{:fileName => "Main.hx", :lineNumber => 47, :className => "Main", :methodName => "testComplexExpressions"})
    else
      Log.trace("Odd: " <> item, %{:fileName => "Main.hx", :lineNumber => 49, :className => "Main", :methodName => "testComplexExpressions"})
    end
    {:cont, {acc_doubled, acc_g, acc_state}}
  else
    {:halt, {acc_doubled, acc_g, acc_state}}
  end
end)
  end
  defp test_class_tracking() do
    calc = Calculator.new()
    calc.add(5)
    calc.multiply(2)
    Log.trace("Calculator result: " <> calc.getValue(), %{:fileName => "Main.hx", :lineNumber => 58, :className => "Main", :methodName => "testClassTracking"})
  end
end