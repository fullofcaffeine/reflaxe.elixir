defmodule Main do
  def main() do
    _ = test_mutable_ops()
    _ = test_variable_reassignment()
    _ = test_loop_counters()
  end
  defp test_mutable_ops() do
    x = 10
    x = x + 5
    x = (x - 3)
    x = x * 2
    x = rem(x, 3)
    str = "Hello"
    str = "#{(fn -> str end).()} World"
    arr = [1, 2, 3]
    arr = arr ++ [4, 5]
    nil
  end
  defp test_variable_reassignment() do
    count = 0
    count = count + 1
    count = count + 1
    count = count + 1
    value = 5
    if (value > 0) do
      value = value * 2
    else
      value = value * -1
    end
    result = 1
    result = result * 2
    result = result + 10
    result = (result - 5)
    nil
  end
  defp test_loop_counters() do
    i = 0
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i}, (fn -> fn _, {i} ->
  if (i < 5) do
    i + 1
    {:cont, {i}}
  else
    {:halt, {i}}
  end
end end).())
    j = 5
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j}, (fn -> fn _, {j} ->
  if (j > 0) do
    (j - 1)
    {:cont, {j}}
  else
    {:halt, {j}}
  end
end end).())
    sum = 0
    k = 1
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, k}, (fn -> fn _, {sum, k} ->
  if (k <= 5) do
    sum = sum + k
    k + 1
    {:cont, {sum, k}}
  else
    {:halt, {sum, k}}
  end
end end).())
    total = 0
    x = 0
    _ = Enum.each(0..(3 - 1), (fn -> fn x ->
  y = 0
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, y}, (fn -> fn _, {total, y} ->
    if (y < 3) do
      total = total + 1
      y + 1
      {:cont, {total, y}}
    else
      {:halt, {total, y}}
    end
  end end).())
  x + 1
end end).())
    nil
  end
end
