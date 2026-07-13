defmodule Main do
  def main() do
    test_complex_assignment_with_binary()
    test_method_call_in_binary_expression()
  end
  defp test_complex_assignment_with_binary() do
    c = 60000
    i = 0
    _ = Bitwise.bor(Bitwise.bsl((c - 55232), 10), index = i + 1)
    nil
  end
  defp test_method_call_in_binary_expression() do
    s = TestString.new("test")
    i = 0
    index = 0
    c = apply(Map.get(s, :__reflaxe_class__) || Map.get(s, :__struct__), :cca, (fn ->
        index = i + 1
        [s, index]
      end).())
    _ = if (c > 55296) do
      Bitwise.bor(Bitwise.bsl((c - 55232), 10), Bitwise.band(apply(Map.get(s, :__reflaxe_class__) || Map.get(s, :__struct__), :cca, (fn ->
          index = i + 1
          [s, index]
        end).()), 1023))
    else
      c
    end
    nil
  end
end
