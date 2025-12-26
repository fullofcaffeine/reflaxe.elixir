defmodule Main do
  @import :Bitwise

  defp test_complex_assignment_with_binary() do
    c = 60000
    i = 0
    index = 0
    c = Bitwise.bor(Bitwise.bsl((c - 55232), 10), index = i + 1)
    nil
  end
  defp test_method_call_in_binary_expression() do
    s = TestString.new("test")
    i = 0
    index = 0
    c = 0
    c = s.cca(index = i + 1)
    c = if (c > 55296), do: Bitwise.bor(Bitwise.bsl((c - 55232), 10), Bitwise.band(s.cca(index = i + 1), 1023)), else: c
    nil
  end
end
