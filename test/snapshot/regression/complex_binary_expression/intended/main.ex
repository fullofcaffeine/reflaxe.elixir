defmodule Main do
  @import :Bitwise

  defp test_complex_assignment_with_binary() do
    c = 60000
    i = 0
    index = 0
    c = Bitwise.bor(Bitwise.bsl((c - 55232), 10), index = i + 1)
    _ = Log.trace("c: #{(fn -> c end).()}, index: #{(fn -> index end).()}", %{:file_name => "Main.hx", :line_number => 22, :class_name => "Main", :method_name => "testComplexAssignmentWithBinary"})
  end
  defp test_method_call_in_binary_expression() do
    s = MyApp.TestString.new("test")
    i = 0
    index = 0
    c = s.cca(index = i + 1)
    c = if (c > 55296), do: Bitwise.bor(Bitwise.bsl((c - 55232), 10), Bitwise.band(s.cca(index = i + 1), 1023)), else: c
    _ = Log.trace("final c: #{(fn -> c end).()}", %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "testMethodCallInBinaryExpression"})
  end
end
