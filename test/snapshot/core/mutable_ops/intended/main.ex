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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, (fn -> fn _, {i} ->
      if (i < 5) do
        (old_i = i
i = i + 1
old_i)
        {:cont, {i}}
      else
        {:halt, {i}}
      end
    end end).())
    nil
    j = 5
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, (fn -> fn _, {j} ->
      if (j > 0) do
        (old_j = j
j = (j - 1)
old_j)
        {:cont, {j}}
      else
        {:halt, {j}}
      end
    end end).())
    nil
    sum = 0
    k = 1
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, 0}, (fn -> fn _, {sum, k} ->
      if (k <= 5) do
        sum = sum + k
        (old_k = k
k = k + 1
old_k)
        {:cont, {sum, k}}
      else
        {:halt, {sum, k}}
      end
    end end).())
    nil
    total = 0
    x = 0
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, 0}, (fn -> fn _, {total, x} ->
      if (x < 3) do
        y = 0
        {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, 0}, (fn -> fn _, {total, y} ->
          if (y < 3) do
            total = total + 1
            (old_y = y
y = y + 1
old_y)
            {:cont, {total, y}}
          else
            {:halt, {total, y}}
          end
        end end).())
        nil
        (old_x = x
x = x + 1
old_x)
        {:cont, {total, x}}
      else
        {:halt, {total, x}}
      end
    end end).())
    nil
    nil
  end
end
