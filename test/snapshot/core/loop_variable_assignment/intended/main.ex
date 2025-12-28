defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    g = []
    g = Enum.reduce(numbers, g, fn n, g_acc -> Enum.concat(g_acc, [n * 2]) end)
    _doubled = g
    g = []
    g = Enum.reduce(numbers, g, fn n, g_acc ->
      if (rem(n, 2) == 0) do
        Enum.concat(g_acc, [n])
      else
        g_acc
      end
    end)
    _evens = g
    g = []
    x = 1
    y = "a"
    g = g ++ [%{:x => x, :y => y}]
    y = "b"
    g = g ++ [%{:x => x, :y => y}]
    x = 2
    y = "a"
    g = g ++ [%{:x => x, :y => y}]
    y = "b"
    g = g ++ [%{:x => x, :y => y}]
    _pairs = g
    i = 0
    collected = []
    {_i, _collected} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, collected}, fn _, {acc_i, acc_collected} ->
      try do
        if (acc_i < 5) do
          acc_collected = acc_collected ++ [acc_i * acc_i]
          old_i = acc_i
          acc_i = acc_i + 1
          {:cont, {acc_i, acc_collected}}
        else
          {:halt, {acc_i, acc_collected}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_i, acc_collected}}
        :throw, :continue ->
          {:cont, {acc_i, acc_collected}}
      end
    end)
    j = 0
    results = []
    {_j, _results} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j, results}, fn _, {acc_j, acc_results} ->
      try do
        if (acc_j < 3) do
          acc_results = acc_results ++ [acc_j]
          old_j = acc_j
          acc_j = acc_j + 1
          {:cont, {acc_j, acc_results}}
        else
          {:halt, {acc_j, acc_results}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_j, acc_results}}
        :throw, :continue ->
          {:cont, {acc_j, acc_results}}
      end
    end)
    sum = 0
    g = 0
    sum = Enum.reduce(numbers, sum, fn n, sum_acc -> sum_acc + n end)
    output = []
    g = 0
    output = Enum.reduce(numbers, output, fn n, output_acc ->
      if (n > 2) do
        output_acc = Enum.concat(output_acc, [n])
        output_acc
      else
        output_acc
      end
    end)
    nil
  end
end
