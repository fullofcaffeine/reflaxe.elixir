defmodule Main do
  def main() do
    _result = add(1, 2)
    _ = test_conditional()
    _ = test_loop()
    _ = test_lambda()
  end
  defp add(a, b) do
    a + b
  end
  defp test_conditional() do
    x = 10
    if (x > 5), do: nil, else: nil
  end
  defp test_loop() do
    items = [1, 2, 3, 4, 5]
    _g = 0
    _ = Enum.each(items, fn _ -> nil end)
  end
  defp test_lambda() do
    numbers = [1, 2, 3]
    _doubled = Enum.map(numbers, fn n -> n * 2 end)
    nil
  end
end
