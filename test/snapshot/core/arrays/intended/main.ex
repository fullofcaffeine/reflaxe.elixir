defmodule Main do
  def basic_array_ops() do
    numbers = [1, 2, 3, 4, 5]
    Log.trace(numbers[0], %{:file_name => "Main.hx", :line_number => 14, :class_name => "Main", :method_name => "basicArrayOps"})
    Log.trace(length(numbers), %{:file_name => "Main.hx", :line_number => 15, :class_name => "Main", :method_name => "basicArrayOps"})
    numbers = numbers ++ [6]
    numbers.unshift(0)
    popped = :List.delete_at(numbers, -1)
    shifted = numbers.shift()
    Log.trace("Popped: #{(fn -> popped end).()}, Shifted: #{(fn -> shifted end).()}", %{:file_name => "Main.hx", :line_number => 22, :class_name => "Main", :method_name => "basicArrayOps"})
    mixed = [1, "hello", true, 3.14]
    Log.trace(mixed, %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "basicArrayOps"})
  end
  def array_iteration() do
    fruits = ["apple", "banana", "orange", "grape"]
    Enum.each(fruits, fn item ->
            Log.trace("Fruit: " <> item, %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "arrayIteration"})
    end)
    Enum.each(fruits, fn item ->
      i = 1
      Log.trace("" <> i.to_string() <> ": " <> fruits[i], %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "arrayIteration"})
    end)
    i = 0
    Enum.each(0..(length(fruits) - 1), fn i ->
      Log.trace("While: " <> fruits[i], %{:file_name => "Main.hx", :line_number => 46, :class_name => "Main", :method_name => "arrayIteration"})
      i + 1
    end)
  end
  def array_methods() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    Log.trace("Doubled: #{(fn -> inspect(doubled) end).()}", %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "arrayMethods"})
    evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Evens: #{(fn -> inspect(evens) end).()}", %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "arrayMethods"})
    more = [6, 7, 8]
    combined = Enum.concat(numbers, more)
    Log.trace("Combined: #{(fn -> inspect(combined) end).()}", %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "arrayMethods"})
    _ = ["Hello", "World", "from", "Haxe"]
    sentence = Enum.join((fn -> " " end).())
    Log.trace("Sentence: #{(fn -> sentence end).()}", %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "arrayMethods"})
    reversed = numbers.copy()
    Enum.reverse(reversed)
    Log.trace("Reversed: #{(fn -> inspect(reversed) end).()}", %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "arrayMethods"})
    unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
    Enum.sort(unsorted, fn a, b -> (a - b) end)
    Log.trace("Sorted: #{(fn -> inspect(unsorted) end).()}", %{:file_name => "Main.hx", :line_number => 81, :class_name => "Main", :method_name => "arrayMethods"})
  end
  def array_comprehensions() do
    squares = [1, 4, 9, 16, 25]
    Log.trace("Squares: #{(fn -> inspect(squares) end).()}", %{:file_name => "Main.hx", :line_number => 88, :class_name => "Main", :method_name => "arrayComprehensions"})
    even_squares = for item <- [4, 16, 36, 64], do: item
    Log.trace("Even squares: #{(fn -> inspect(even_squares) end).()}", %{:file_name => "Main.hx", :line_number => 92, :class_name => "Main", :method_name => "arrayComprehensions"})
    pairs = [%{:x => 1, :y => 2}, %{:x => 1, :y => 3}, %{:x => 2, :y => 1}, %{:x => 2, :y => 3}, %{:x => 3, :y => 1}, %{:x => 3, :y => 2}]
    Log.trace("Pairs: #{(fn -> inspect(pairs) end).()}", %{:file_name => "Main.hx", :line_number => 96, :class_name => "Main", :method_name => "arrayComprehensions"})
  end
  def multi_dimensional() do
    matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    Log.trace("Matrix element [1][2]: #{(fn -> matrix[1][2] end).()}", %{:file_name => "Main.hx", :line_number => 108, :class_name => "Main", :method_name => "multiDimensional"})
    Enum.each(matrix, fn item ->
            Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {row}, fn _, {row} ->
        if (0 < length(row)) do
          elem = row[0]
          Log.trace("Element: " <> elem.to_string(), %{:file_name => "Main.hx", :line_number => 113, :class_name => "Main", :method_name => "multiDimensional"})
          {:cont, {row}}
        else
          {:halt, {row}}
        end
      end)
    end)
    grid = [] ++ [(fn ->
  Enum.each(0..2, fn _ -> push(0) end)
  []
end).()]
    [] ++ [(fn ->
  [] ++ [3]
  [] ++ [4]
  [] ++ [5]
  []
end).()]
    [] ++ [(fn ->
  [] ++ [6]
  [] ++ [7]
  [] ++ [8]
  []
end).()]
    []
    Log.trace("Grid: #{(fn -> inspect(grid) end).()}", %{:file_name => "Main.hx", :line_number => 119, :class_name => "Main", :method_name => "multiDimensional"})
  end
  def process_array(arr) do
    Enum.filter(Enum.map(arr, fn x -> x * x end), fn x -> x > 10 end)
  end
  def first_n(arr, n) do
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {arr, n, b}, fn _, {arr, n, b} ->
      if (0 < trunc.((fn -> b = length(arr)
  if (n < b), do: n, else: b end).())) do
        i = 1
        [].push(arr[i])
        {:cont, {arr, n, b}}
      else
        {:halt, {arr, n, b}}
      end
    end)
    []
  end
  def functional_methods() do
    numbers = [1, 2, 3, 4, 5]
    strings = ["hello", "world", "haxe", "elixir"]
    sum = MyApp.ArrayTools.reduce(numbers, fn acc, item -> acc + item end, 0)
    Log.trace("Sum via reduce: #{(fn -> sum end).()}", %{:file_name => "Main.hx", :line_number => 139, :class_name => "Main", :method_name => "functionalMethods"})
    product = MyApp.ArrayTools.fold(numbers, fn acc, item -> acc * item end, 1)
    Log.trace("Product via fold: #{(fn -> product end).()}", %{:file_name => "Main.hx", :line_number => 142, :class_name => "Main", :method_name => "functionalMethods"})
    first_even = MyApp.ArrayTools.find(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("First even number: #{(fn -> first_even end).()}", %{:file_name => "Main.hx", :line_number => 146, :class_name => "Main", :method_name => "functionalMethods"})
    long_word = MyApp.ArrayTools.find(strings, fn s -> length(s) > 4 end)
    Log.trace("First long word: #{(fn -> long_word end).()}", %{:file_name => "Main.hx", :line_number => 149, :class_name => "Main", :method_name => "functionalMethods"})
    even_index = MyApp.ArrayTools.find_index(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Index of first even: #{(fn -> even_index end).()}", %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "functionalMethods"})
    long_word_index = MyApp.ArrayTools.find_index(strings, fn s -> length(s) > 4 end)
    Log.trace("Index of first long word: #{(fn -> long_word_index end).()}", %{:file_name => "Main.hx", :line_number => 156, :class_name => "Main", :method_name => "functionalMethods"})
    has_even = MyApp.ArrayTools.exists(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Has even numbers: #{(fn -> inspect(has_even) end).()}", %{:file_name => "Main.hx", :line_number => 160, :class_name => "Main", :method_name => "functionalMethods"})
    has_very_long = MyApp.ArrayTools.any(strings, fn s -> length(s) > 10 end)
    Log.trace("Has very long word: #{(fn -> inspect(has_very_long) end).()}", %{:file_name => "Main.hx", :line_number => 163, :class_name => "Main", :method_name => "functionalMethods"})
    all_positive = MyApp.ArrayTools.foreach(numbers, fn n -> n > 0 end)
    Log.trace("All positive: #{(fn -> inspect(all_positive) end).()}", %{:file_name => "Main.hx", :line_number => 167, :class_name => "Main", :method_name => "functionalMethods"})
    all_short = MyApp.ArrayTools.all(strings, fn s -> length(s) < 10 end)
    Log.trace("All short words: #{(fn -> inspect(all_short) end).()}", %{:file_name => "Main.hx", :line_number => 170, :class_name => "Main", :method_name => "functionalMethods"})
    Log.trace("Numbers via forEach:", %{:file_name => "Main.hx", :line_number => 173, :class_name => "Main", :method_name => "functionalMethods"})
    MyApp.ArrayTools.for_each(numbers, fn n -> Log.trace("  - " <> n.to_string(), %{:file_name => "Main.hx", :line_number => 174, :class_name => "Main", :method_name => "functionalMethods"}) end)
    first3 = MyApp.ArrayTools.take(numbers, 3)
    Log.trace("First 3 numbers: #{(fn -> inspect(first3) end).()}", %{:file_name => "Main.hx", :line_number => 178, :class_name => "Main", :method_name => "functionalMethods"})
    skip2 = MyApp.ArrayTools.drop(numbers, 2)
    Log.trace("Skip first 2: #{(fn -> inspect(skip2) end).()}", %{:file_name => "Main.hx", :line_number => 182, :class_name => "Main", :method_name => "functionalMethods"})
    nested_arrays = [[1, 2], [3, 4], [5]]
    flattened = MyApp.ArrayTools.flat_map(nested_arrays, fn arr -> Enum.map(arr, fn x -> x * 2 end) end)
    Log.trace("FlatMap doubled: #{(fn -> inspect(flattened) end).()}", %{:file_name => "Main.hx", :line_number => 187, :class_name => "Main", :method_name => "functionalMethods"})
    processed = MyApp.ArrayTools.reduce(ArrayTools.take(Enum.map(Enum.filter(numbers, fn n -> n > 2 end), fn n -> n * n end), 2), fn acc, n -> acc + n end, 0)
    Log.trace("Chained operations result: #{(fn -> processed end).()}", %{:file_name => "Main.hx", :line_number => 195, :class_name => "Main", :method_name => "functionalMethods"})
  end
  def main() do
    Log.trace("=== Basic Array Operations ===", %{:file_name => "Main.hx", :line_number => 199, :class_name => "Main", :method_name => "main"})
    basic_array_ops()
    Log.trace("\n=== Array Iteration ===", %{:file_name => "Main.hx", :line_number => 202, :class_name => "Main", :method_name => "main"})
    array_iteration()
    Log.trace("\n=== Array Methods ===", %{:file_name => "Main.hx", :line_number => 205, :class_name => "Main", :method_name => "main"})
    array_methods()
    Log.trace("\n=== Array Comprehensions ===", %{:file_name => "Main.hx", :line_number => 208, :class_name => "Main", :method_name => "main"})
    array_comprehensions()
    Log.trace("\n=== Multi-dimensional Arrays ===", %{:file_name => "Main.hx", :line_number => 211, :class_name => "Main", :method_name => "main"})
    multi_dimensional()
    Log.trace("\n=== Array Functions ===", %{:file_name => "Main.hx", :line_number => 214, :class_name => "Main", :method_name => "main"})
    result = process_array([1, 2, 3, 4, 5])
    Log.trace("Processed: #{(fn -> inspect(result) end).()}", %{:file_name => "Main.hx", :line_number => 216, :class_name => "Main", :method_name => "main"})
    first3 = first_n(["a", "b", "c", "d", "e"], 3)
    Log.trace("First 3: #{(fn -> inspect(first3) end).()}", %{:file_name => "Main.hx", :line_number => 219, :class_name => "Main", :method_name => "main"})
    Log.trace("\n=== NEW: Functional Array Methods ===", %{:file_name => "Main.hx", :line_number => 221, :class_name => "Main", :method_name => "main"})
    functional_methods()
  end
end
