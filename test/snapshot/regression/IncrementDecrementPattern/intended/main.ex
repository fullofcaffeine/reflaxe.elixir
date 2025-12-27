defmodule Main do
  defp test_while_loop() do
    k = 10
    pos = 0
    {k, pos} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, 0}, fn _, {k, pos} ->
      if (k > 0) do
        _old_pos = pos
        pos = pos + 1
        old_k = k
        k = (k - 1)
        old_k
        {:cont, {k, pos}}
      else
        {:halt, {k, pos}}
      end
    end)
    nil
    nil
  end
  defp test_for_loop() do
    count = 0
    _old_count = count
    count = count + 1
    _old_count = count
    count = count + 1
    _old_count = count
    count = count + 1
    _old_count = count
    count = count + 1
    old_count = count
    count = count + 1
    old_count
    nil
  end
end
