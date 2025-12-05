defmodule Main do
  defp test_while_loop() do
    k = 10
    pos = 0
    _ = Enum.each(k, (fn -> fn item ->
  item + 1
  (item - 1)
end end).())
    nil
  end
  defp test_for_loop() do
    count = 0
    count = count + 1
    count = count + 1
    count = count + 1
    count = count + 1
    count = count + 1
    nil
  end
end
