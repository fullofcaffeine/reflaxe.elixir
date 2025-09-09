defmodule Main do
  import Bitwise
  defp test_complex_assignment() do
    i = 0
    index = nil
    c = nil
    index = i + 1
    c = index
    _result = some_function(index)
    index = i + 1
    c = (c - 55232) <<< 10 ||| index
    masked = some_function(index) &&& 1023
    Log.trace("c: " <> Kernel.to_string(c) <> ", masked: " <> Kernel.to_string(masked), %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "testComplexAssignment"})
  end
  defp some_function(x) do
    x * 2
  end
  def main() do
    test_complex_assignment()
  end
end