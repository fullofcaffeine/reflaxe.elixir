defmodule Main do
  def basic_array_ops() do
    numbers = [1, 2, 3, 4, 5]
    numbers = numbers ++ [6]
    _ = Array.unshift(numbers, 0)
    popped = Array.pop(numbers)
    shifted = Array.shift(numbers)
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, fn _, {i} ->
      if (i < length(fruits)) do
        _old_i = i
        i = i + 1
        {:cont, {i}}
      else
        {:halt, {i}}
      end
    end)
    nil
  end
  def array_methods() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    more = [6, 7, 8]
    combined = numbers ++ more
    words = ["Hello", "World", "from", "Haxe"]
    sentence = Enum.join(words, " ")
    reversed = numbers
    _ = Array.reverse(reversed)
    unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
    unsorted = Enum.sort(unsorted, fn a, b -> (fn a, b -> (a - b) end).(a, b) < 0 end)
    nil
  end
  def array_comprehensions() do
    squares = [1, 4, 9, 16, 25]
    g = []
    g ++ [4]
    g ++ [16]
    g ++ [36]
    g ++ [64]
    even_squares = g
    g = []
    _g = g ++ [%{:x => 1, :y => 3}]
    _g = g ++ [%{:x => 2, :y => 3}]
    _g = g ++ [%{:x => 3, :y => 2}]
    pairs = g
    nil
  end
  def multi_dimensional() do
    matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    _g = 0
    _ = Enum.each(matrix, fn row ->
  _g = 0
  _ = Enum.each(row, fn _ -> nil end)
end)
    [(fn ->
  [0]
  [1]
  [2]
  []
end).()]
    [(fn ->
  [3]
  [4]
  [5]
  []
end).()]
    [(fn ->
  [6]
  [7]
  [8]
  []
end).()]
    grid = []
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
    _ = Enum.each(0..(g - 1)//1, fn _ -> [arr[i]] end)
    []
  end
  def functional_methods() do
    numbers = [1, 2, 3, 4, 5]
    strings = ["hello", "world", "haxe", "elixir"]
    sum = ArrayTools.reduce(numbers, fn acc, item -> acc + item end, 0)
    product = ArrayTools.fold(numbers, fn acc, item -> acc * item end, 1)
    first_even = ArrayTools.find(numbers, fn n -> rem(n, 2) == 0 end)
    long_word = ArrayTools.find(strings, fn s -> String.length(s) > 4 end)
    even_index = ArrayTools.find_index(numbers, fn n -> rem(n, 2) == 0 end)
    long_word_index = ArrayTools.find_index(strings, fn s -> String.length(s) > 4 end)
    has_even = ArrayTools.exists(numbers, fn n -> rem(n, 2) == 0 end)
    has_very_long = ArrayTools.any(strings, fn s -> String.length(s) > 10 end)
    all_positive = ArrayTools.foreach(numbers, fn n -> n > 0 end)
    all_short = ArrayTools.all(strings, fn s -> String.length(s) < 10 end)
    _ = ArrayTools.for_each(numbers, fn _n -> nil end)
    _ = ArrayTools.take(numbers, 3)
    _ = ArrayTools.drop(numbers, 2)
    nested_arrays = [[1, 2], [3, 4], [5]]
    flattened = ArrayTools.flat_map(nested_arrays, fn arr -> Enum.map(arr, fn x -> x * 2 end) end)
    processed = ArrayTools.reduce(ArrayTools.take(Enum.map(Enum.filter(numbers, fn n -> n > 2 end), fn n -> n * n end), 2), fn acc, n -> acc + n end, 0)
    nil
  end
  def main() do
    _ = basic_array_ops()
    _ = array_iteration()
    _ = array_methods()
    _ = array_comprehensions()
    _ = multi_dimensional()
    result = process_array([1, 2, 3, 4, 5])
    _ = first_n(["a", "b", "c", "d", "e"], 3)
    _ = functional_methods()
  end
end
