defmodule Main do
  import Bitwise
  defp main() do
    test_complex_assignment_with_binary()
    test_method_call_in_binary_expression()
  end
  defp test_complex_assignment_with_binary() do
    c = 60000
    i = 0
    index = 0
    index = i + 1
    c = (c - 55232) <<< 10 ||| (index)
    Log.trace("c: " <> c <> ", index: " <> index, %{:fileName => "Main.hx", :lineNumber => 22, :className => "Main", :methodName => "testComplexAssignmentWithBinary"})
  end
  defp test_method_call_in_binary_expression() do
    s = TestString.new("test")
    i = 0
    index = 0
    c = 0
    index = i + 1
    c = s.cca(index)
    if (c > 55296) do
      index = i + 1
      c = (c - 55232) <<< 10 ||| s.cca(index) &&& 1023
    end
    Log.trace("final c: " <> c, %{:fileName => "Main.hx", :lineNumber => 41, :className => "Main", :methodName => "testMethodCallInBinaryExpression"})
  end
end