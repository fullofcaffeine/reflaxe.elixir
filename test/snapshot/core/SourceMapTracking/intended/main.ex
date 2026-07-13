defmodule Main do
  def main() do
    test_basic_tracking()
    test_complex_expressions()
    test_class_tracking()
  end
  defp test_basic_tracking() do
    x = 10
    y = 20
    _result = x + y
    nil
  end
  defp test_complex_expressions() do
    items = [1, 2, 3, 4, 5]
    doubled = Enum.map(items, fn item -> item * 2 end)
    is_even = fn n -> rem(n, 2) == 0 end
    _g = 0
    Enum.each(doubled, fn item ->
      if (is_even.(item)), do: nil, else: nil
    end)
  end
  defp test_class_tracking() do
    calc = Calculator.new()
    apply(Map.get(calc, :__reflaxe_class__) || Map.get(calc, :__struct__), :add, [calc, 5])
    apply(Map.get(calc, :__reflaxe_class__) || Map.get(calc, :__struct__), :multiply, [calc, 2])
    nil
  end
end
