defmodule Main do
  defp test_complex_assignment() do
    i = 0
    index = i + 1
    c = index
    _result = some_function(index)
    _ = Bitwise.bor(Bitwise.bsl((c - 55232), 10), index = i + 1)
    _masked = Bitwise.band(some_function(index), 1023)
    nil
  end
  defp some_function(x) do
    x * 2
  end
  def main() do
    test_complex_assignment()
  end
end
