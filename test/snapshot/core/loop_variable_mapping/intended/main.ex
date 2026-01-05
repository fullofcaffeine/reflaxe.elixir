defmodule Main do
  def main() do
    array = [1, 2, 3, 4, 5]
    result = []
    _g = 0
    result = Enum.reduce(array, result, fn item, result_acc ->
      if (item > 2) do
        result_acc = Enum.concat(result_acc, [item * 2])
        result_acc
      else
        result_acc
      end
    end)
    _g = 0
    array_length = length(array)
    result = Enum.reduce(0..(array_length - 1)//1, result, fn i, result_acc ->
      _g = 0
      array_length = length(array)
      Enum.reduce(0..(array_length - 1)//1, result_acc, fn j, result_acc ->
        if (array[i] < array[j]) do
          result_acc = Enum.concat(result_acc, [array[i] + array[j]])
          result_acc
        else
          result_acc
        end
      end)
    end)
    filtered = []
    _g = 0
    filtered = Enum.reduce(array, filtered, fn x, filtered_acc ->
      if (rem(x, 2) == 0) do
        filtered_acc = Enum.concat(filtered_acc, [x])
        filtered_acc
      else
        filtered_acc
      end
    end)
    functions = []
    functions = functions ++ [fn -> nil end]
    functions = functions ++ [fn -> nil end]
    functions = functions ++ [fn -> 2 end]
    i = 100
    result = result ++ [0]
    result = result ++ [1]
    result = result ++ [2]
    result = result ++ [i]
    sum = 0
    _g = 0
    sum = Enum.reduce(array, sum, fn n, sum_acc -> sum_acc + n end)
    _g = 0
    sum = Enum.reduce(array, sum, fn n, sum_acc -> (sum_acc - n) end)
    nil
  end
end
