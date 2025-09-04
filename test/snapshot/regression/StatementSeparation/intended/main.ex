defmodule Main do
  import Bitwise
  defp test_complex_assignment() do
    i = 0
    index = nil
    index = i + 1
    c = index
    _result = some_function(index)
    index = i + 1
    c = (c - 55232) <<< 10 ||| index
    masked = some_function(index) &&& 1023
    Log.trace("c: " <> c <> ", masked: " <> masked, %{:fileName => "Main.hx", :lineNumber => 21, :className => "Main", :methodName => "testComplexAssignment"})
  end
  defp some_function(x) do
    x * 2
  end
  defp main() do
    test_complex_assignment()
  end
end