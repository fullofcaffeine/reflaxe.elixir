defmodule Main do
  def basic_array_ops() do
    numbers = [1, 2, 3, 4, 5]
    _ = numbers ++ [6]
    _ = numbers.unshift(0)
    popped = :List.delete_at(numbers, -1)
    shifted = numbers.shift()
    _ = nil
    _ = nil
    _ = nil
    _ = nil
    _ = 1
    _ = "hello"
    _ = true
    _ = 3.14
    nil
  end
  def array_iteration() do
    fruits = ["apple", "banana", "orange", "grape"]
    _ = Enum.each(fruits, (fn -> fn _ ->
    nil
end end).())
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fruits}, (fn -> fn _, {fruits} ->
  if (0 < length(fruits)) do
    i = 1
    nil
    {:cont, {fruits}}
  else
    {:halt, {fruits}}
  end
end end).())
    i = 0
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fruits, i}, (fn -> fn _, {fruits, i} ->
  if (i < length(fruits)) do
    i + 1
    {:cont, {fruits, i}}
  else
    {:halt, {fruits, i}}
  end
end end).())
  end
  def array_methods() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    more = [6, 7, 8]
    combined = numbers ++ more
    words = ["Hello", "World", "from", "Haxe"]
    sentence = Enum.join((fn -> " " end).())
    reversed = numbers.copy()
    _ = Enum.reverse(reversed)
    unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
    _ = Enum.sort(unsorted, fn a, b -> (a - b) end)
    nil
  end
  def array_comprehensions() do
    squares = [1, 4, 9, 16, 25]
    even_squares = g = []
    nil
    g ++ [4]
    nil
    g ++ [16]
    nil
    g ++ [36]
    nil
    g ++ [64]
    nil
    g
    pairs = g = []
    _ = g ++ [%{:x => 1, :y => 2}]
    _ = g ++ [%{:x => 1, :y => 3}]
    _ = g ++ [%{:x => 2, :y => 1}]
    _ = g ++ [%{:x => 2, :y => 3}]
    _ = g ++ [%{:x => 3, :y => 1}]
    _ = g ++ [%{:x => 3, :y => 2}]
    g
    nil
  end
  def multi_dimensional() do
    matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    _ = Enum.each(matrix, (fn -> fn row ->
    Enum.reduce_while(Stream.iterate(0, fn n -> row + 1 end), {row}, (fn -> fn _, {row} ->
    if (0 < length(row)) do
      elem = row[0]
      nil
      {:cont, {row}}
    else
      {:halt, {row}}
    end
  end end).())
end end).())
    grid = _ = [(fn ->
  _ = [0]
  _ = [1]
  _ = [2]
  []
end).()]
    _ = [(fn ->
  _ = [3]
  _ = [4]
  _ = [5]
  []
end).()]
    _ = [(fn ->
  _ = [6]
  _ = [7]
  _ = [8]
  []
end).()]
    []
    nil
  end
  def process_array(arr) do
    Enum.filter(Enum.map(arr, fn x -> x * x end), fn x -> x > 10 end)
  end
  def first_n(arr, n) do
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {arr, n, b}, (fn -> fn _, {arr, n, b} ->
  if (0 < trunc.((fn -> b = length(arr)
  if (n < b), do: n, else: b end).())) do
    i = 1
    [].push(arr[i])
    {:cont, {arr, n, b}}
  else
    {:halt, {arr, n, b}}
  end
end end).())
    []
  end
  def functional_methods() do
    numbers = [1, 2, 3, 4, 5]
    strings = ["hello", "world", "haxe", "elixir"]
    sum = MyApp.ArrayTools.reduce(numbers, fn acc, item -> acc + item end, 0)
    product = MyApp.ArrayTools.fold(numbers, fn acc, item -> acc * item end, 1)
    first_even = MyApp.ArrayTools.find(numbers, fn n -> rem(n, 2) == 0 end)
    long_word = MyApp.ArrayTools.find(strings, fn s -> length(s) > 4 end)
    even_index = MyApp.ArrayTools.find_index(numbers, fn n -> rem(n, 2) == 0 end)
    long_word_index = MyApp.ArrayTools.find_index(strings, fn s -> length(s) > 4 end)
    has_even = MyApp.ArrayTools.exists(numbers, fn n -> rem(n, 2) == 0 end)
    has_very_long = MyApp.ArrayTools.any(strings, fn s -> length(s) > 10 end)
    all_positive = MyApp.ArrayTools.foreach(numbers, fn n -> n > 0 end)
    all_short = MyApp.ArrayTools.all(strings, fn s -> length(s) < 10 end)
    _ = MyApp.ArrayTools.for_each(numbers, fn _n -> nil end)
    _ = MyApp.ArrayTools.take(numbers, 3)
    _ = MyApp.ArrayTools.drop(numbers, 2)
    nested_arrays = [[1, 2], [3, 4], [5]]
    flattened = MyApp.ArrayTools.flat_map(nested_arrays, fn arr -> Enum.map(arr, fn x -> x * 2 end) end)
    processed = MyApp.ArrayTools.reduce(ArrayTools.take(Enum.map(Enum.filter(numbers, fn n -> n > 2 end), fn n -> n * n end), 2), fn acc, n -> acc + n end, 0)
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
