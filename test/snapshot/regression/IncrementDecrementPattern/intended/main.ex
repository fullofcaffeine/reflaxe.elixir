defmodule Main do
  defp test_while_loop() do
    k = 10
    pos = 0
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k}, (fn -> fn _, {k} ->
  if (k > 0) do
    pos + 1
    (k - 1)
    {:cont, {k}}
  else
    {:halt, {k}}
  end
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
