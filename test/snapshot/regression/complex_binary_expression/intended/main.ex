defmodule Main do
  def main() do
    _ = test_complex_assignment_with_binary()
    _ = test_method_call_in_binary_expression()
  end
  defp test_complex_assignment_with_binary() do
    c = 60000
    i = 0
    c = Bitwise.bor(Bitwise.bsl((c - 55232), 10), index = i + 1)
    nil
  end
  defp test_method_call_in_binary_expression() do
    s = TestString.new("test")
    i = 0
    c = TestString.cca(s, index = i + 1)
    c = if (c > 55296) do
      Bitwise.bor(Bitwise.bsl((c - 55232), 10), Bitwise.band(TestString.cca(s, index = i + 1), 1023))
    else
      c
    end
    nil
  end
end
