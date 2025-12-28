defmodule Main do
  def basic_array_ops() do
    numbers = [1, 2, 3, 4, 5]
    numbers = numbers ++ [6]
    _ = Array.unshift(numbers, 0)
    _popped = Array.pop(numbers)
    _shifted = Array.shift(numbers)
    _ = 1
    _ = "hello"
    _ = true
    _ = 3.14
    nil
  end
  def array_iteration() do
    fruits = ["apple", "banana", "orange", "grape"]
    _g = 0
    _ = Enum.each(fruits, fn _ -> nil end)
    _g = 0
    fruits_length = length(fruits)
    _ = Enum.each(0..(fruits_length - 1)//1, fn _ -> nil end)
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i}, fn _, {acc_i} ->
      try do
        if (acc_i < length(fruits)) do
          old_i = acc_i
          acc_i = acc_i + 1
          {:cont, {acc_i}}
        else
          {:halt, {acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_i}}
        :throw, :continue ->
          {:cont, {acc_i}}
      end
    end)
  end
  def array_methods() do
    numbers = [1, 2, 3, 4, 5]
    _doubled = Enum.map(numbers, fn n -> n * 2 end)
    _evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    more = [6, 7, 8]
    _combined = numbers ++ more
    words = ["Hello", "World", "from", "Haxe"]
    _sentence = Enum.join(words, " ")
    reversed = numbers
    _ = Array.reverse(reversed)
    unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
    unsorted = Enum.sort(unsorted, fn a, b -> (fn a, b -> (a - b) end).(a, b) < 0 end)
    nil
  end
  def array_comprehensions() do
    g = []
    g = g ++ [4]
    g = g ++ [16]
    g = g ++ [36]
    _even_squares = g ++ [64]
    g = []
    g = g ++ [%{:x => 1, :y => 2}]
    g = g ++ [%{:x => 1, :y => 3}]
    g = g ++ [%{:x => 2, :y => 1}]
    g = g ++ [%{:x => 2, :y => 3}]
    g = g ++ [%{:x => 3, :y => 1}]
    g = g ++ [%{:x => 3, :y => 2}]
    _pairs = g
    nil
  end
  def multi_dimensional() do
    matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    g = 0
    _ = Enum.each(matrix, fn row ->
  _g = 0
  _ = Enum.each(row, fn _ -> nil end)
end)
    _grid = [(fn ->
  g = []
  g = g ++ [0]
  g = g ++ [1]
  g = g ++ [2]
  g
end).(), (fn ->
  g = []
  g = g ++ [3]
  g = g ++ [4]
  g = g ++ [5]
  g
end).(), (fn ->
  g = []
  g = g ++ [6]
  g = g ++ [7]
  g = g ++ [8]
  g
end).()]
    nil
  end
  def process_array(arr) do
    Enum.filter(Enum.map(arr, fn x -> x * x end), fn x -> x > 10 end)
  end
  def first_n(arr, n) do
    g_value = 0
    g = trunc((fn ->
        b = length(arr)
        if (n < b), do: n, else: b
      end).())
    g = Enum.reduce(0..(g_value - 1)//1, g, fn i, g_acc -> Enum.concat(g_acc, [arr[i]]) end)
    g
  end
  def functional_methods() do
    numbers = [1, 2, 3, 4, 5]
    strings = ["hello", "world", "haxe", "elixir"]
    _sum = ArrayTools.reduce(numbers, fn acc, item -> acc + item end, 0)
    _product = ArrayTools.fold(numbers, fn acc, item -> acc * item end, 1)
    _first_even = ArrayTools.find(numbers, fn n -> rem(n, 2) == 0 end)
    _long_word = ArrayTools.find(strings, fn s -> String.length(s) > 4 end)
    _even_index = ArrayTools.find_index(numbers, fn n -> rem(n, 2) == 0 end)
    _long_word_index = ArrayTools.find_index(strings, fn s -> String.length(s) > 4 end)
    _has_even = ArrayTools.exists(numbers, fn n -> rem(n, 2) == 0 end)
    _has_very_long = ArrayTools.any(strings, fn s -> String.length(s) > 10 end)
    _all_positive = ArrayTools.foreach(numbers, fn n -> n > 0 end)
    _all_short = ArrayTools.all(strings, fn s -> String.length(s) < 10 end)
    _ = ArrayTools.for_each(numbers, fn _ -> nil end)
    _ = ArrayTools.take(numbers, 3)
    _ = ArrayTools.drop(numbers, 2)
    nested_arrays = [[1, 2], [3, 4], [5]]
    _flattened = ArrayTools.flat_map(nested_arrays, fn arr -> Enum.map(arr, fn x -> x * 2 end) end)
    _processed = ArrayTools.reduce(ArrayTools.take(Enum.map(Enum.filter(numbers, fn n -> n > 2 end), fn n -> n * n end), 2), fn acc, n -> acc + n end, 0)
    nil
  end
  def main() do
    _ = basic_array_ops()
    _ = array_iteration()
    _ = array_methods()
    _ = array_comprehensions()
    _ = multi_dimensional()
    _result = process_array([1, 2, 3, 4, 5])
    _ = first_n(["a", "b", "c", "d", "e"], 3)
    _ = functional_methods()
  end
end
