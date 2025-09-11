defmodule Main do
  def basic_array_ops() do
    numbers = [1, 2, 3, 4, 5]
    Log.trace(numbers[0], %{:file_name => "Main.hx", :line_number => 14, :class_name => "Main", :method_name => "basicArrayOps"})
    Log.trace(length(numbers), %{:file_name => "Main.hx", :line_number => 15, :class_name => "Main", :method_name => "basicArrayOps"})
    numbers = numbers ++ [6]
    [0 | numbers]
    popped = List.last(numbers)
    shifted = List.first(numbers)
    Log.trace("Popped: " <> Kernel.to_string(popped) <> ", Shifted: " <> Kernel.to_string(shifted), %{:file_name => "Main.hx", :line_number => 22, :class_name => "Main", :method_name => "basicArrayOps"})
    mixed = [1, "hello", true, 3.14]
    Log.trace(mixed, %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "basicArrayOps"})
  end
  def array_iteration() do
    fruits = ["apple", "banana", "orange", "grape"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fruits, g, :ok}, fn _, {acc_fruits, acc_g, acc_state} ->
  if (acc_g < length(acc_fruits)) do
    fruit = fruits[g]
    acc_g = acc_g + 1
    Log.trace("Fruit: " <> fruit, %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "arrayIteration"})
    {:cont, {acc_fruits, acc_g, acc_state}}
  else
    {:halt, {acc_fruits, acc_g, acc_state}}
  end
end)
    g = 0
    g1 = length(fruits)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    Log.trace("" <> Kernel.to_string(i) <> ": " <> fruits[i], %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "arrayIteration"})
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fruits, i, :ok}, fn _, {acc_fruits, acc_i, acc_state} ->
  if (acc_i < length(acc_fruits)) do
    Log.trace("While: " <> fruits[i], %{:file_name => "Main.hx", :line_number => 46, :class_name => "Main", :method_name => "arrayIteration"})
    acc_i = acc_i + 1
    {:cont, {acc_fruits, acc_i, acc_state}}
  else
    {:halt, {acc_fruits, acc_i, acc_state}}
  end
end)
  end
  def array_methods() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    Log.trace("Doubled: " <> Std.string(doubled), %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "arrayMethods"})
    evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Evens: " <> Std.string(evens), %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "arrayMethods"})
    more = [6, 7, 8]
    combined = numbers ++ more
    Log.trace("Combined: " <> Std.string(combined), %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "arrayMethods"})
    words = ["Hello", "World", "from", "Haxe"]
    sentence = Enum.join(words, " ")
    Log.trace("Sentence: " <> sentence, %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "arrayMethods"})
    reversed = numbers
    Enum.reverse(reversed)
    Log.trace("Reversed: " <> Std.string(reversed), %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "arrayMethods"})
    unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
    Enum.sort(unsorted, fn a, b -> (a - b) end)
    Log.trace("Sorted: " <> Std.string(unsorted), %{:file_name => "Main.hx", :line_number => 81, :class_name => "Main", :method_name => "arrayMethods"})
  end
  def array_comprehensions() do
    squares = [1, 4, 9, 16, 25]
    Log.trace("Squares: " <> Std.string(squares), %{:file_name => "Main.hx", :line_number => 88, :class_name => "Main", :method_name => "arrayComprehensions"})
    g = []
    even_squares = if rem(1, 2) == 0 do
  g = g ++ [1]
end
if rem(2, 2) == 0 do
  g = g ++ [4]
end
if rem(3, 2) == 0 do
  g = g ++ [9]
end
if rem(4, 2) == 0 do
  g = g ++ [16]
end
if rem(5, 2) == 0 do
  g = g ++ [25]
end
if rem(6, 2) == 0 do
  g = g ++ [36]
end
if rem(7, 2) == 0 do
  g = g ++ [49]
end
if rem(8, 2) == 0 do
  g = g ++ [64]
end
if rem(9, 2) == 0 do
  g = g ++ [81]
end
g
    Log.trace("Even squares: " <> Std.string(even_squares), %{:file_name => "Main.hx", :line_number => 92, :class_name => "Main", :method_name => "arrayComprehensions"})
    g = []
    pairs = g = g ++ [%{:x => 1, :y => 2}]
g = g ++ [%{:x => 1, :y => 3}]
g = g ++ [%{:x => 2, :y => 1}]
g = g ++ [%{:x => 2, :y => 3}]
g = g ++ [%{:x => 3, :y => 1}]
g = g ++ [%{:x => 3, :y => 2}]
nil
g
    Log.trace("Pairs: " <> Std.string(pairs), %{:file_name => "Main.hx", :line_number => 96, :class_name => "Main", :method_name => "arrayComprehensions"})
  end
  def multi_dimensional() do
    matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    Log.trace("Matrix element [1][2]: " <> Kernel.to_string(matrix[1][2]), %{:file_name => "Main.hx", :line_number => 108, :class_name => "Main", :method_name => "multiDimensional"})
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {matrix, g, g, :ok}, fn _, {acc_matrix, acc_g, acc_g, acc_state} -> nil end)
    grid = [(fn -> g = []
g = g ++ [0]
g = g ++ [1]
g = g ++ [2]
g end).(), (fn -> g = []
g = g ++ [3]
g = g ++ [4]
g = g ++ [5]
g end).(), (fn -> g = []
g = g ++ [6]
g = g ++ [7]
g = g ++ [8]
g end).()]
    Log.trace("Grid: " <> Std.string(grid), %{:file_name => "Main.hx", :line_number => 119, :class_name => "Main", :method_name => "multiDimensional"})
  end
  def process_array(arr) do
    Enum.filter(Enum.map(arr, fn x -> x * x end), fn x -> x > 10 end)
  end
  def first_n(arr, n) do
    g = []
    g1 = 0
    g2 = Std.int(if (n < b) do
  n
else
  (length(arr))
end)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g2, :ok}, fn _, {acc_g1, acc_g2, acc_state} ->
  if (acc_g1 < acc_g2) do
    i = acc_g1 = acc_g1 + 1
    g = g ++ [arr[i]]
    {:cont, {acc_g1, acc_g2, acc_state}}
  else
    {:halt, {acc_g1, acc_g2, acc_state}}
  end
end)
    g
  end
  def functional_methods() do
    numbers = [1, 2, 3, 4, 5]
    strings = ["hello", "world", "haxe", "elixir"]
    sum = ArrayTools.reduce(numbers, fn acc, item -> acc + item end, 0)
    Log.trace("Sum via reduce: " <> Kernel.to_string(sum), %{:file_name => "Main.hx", :line_number => 139, :class_name => "Main", :method_name => "functionalMethods"})
    product = ArrayTools.fold(numbers, fn acc, item -> acc * item end, 1)
    Log.trace("Product via fold: " <> Kernel.to_string(product), %{:file_name => "Main.hx", :line_number => 142, :class_name => "Main", :method_name => "functionalMethods"})
    first_even = ArrayTools.find(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("First even number: " <> Kernel.to_string(first_even), %{:file_name => "Main.hx", :line_number => 146, :class_name => "Main", :method_name => "functionalMethods"})
    long_word = ArrayTools.find(strings, fn s -> length(s) > 4 end)
    Log.trace("First long word: " <> Kernel.to_string(long_word), %{:file_name => "Main.hx", :line_number => 149, :class_name => "Main", :method_name => "functionalMethods"})
    even_index = ArrayTools.find_index(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Index of first even: " <> Kernel.to_string(even_index), %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "functionalMethods"})
    long_word_index = ArrayTools.find_index(strings, fn s -> length(s) > 4 end)
    Log.trace("Index of first long word: " <> Kernel.to_string(long_word_index), %{:file_name => "Main.hx", :line_number => 156, :class_name => "Main", :method_name => "functionalMethods"})
    has_even = ArrayTools.exists(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Has even numbers: " <> Std.string(has_even), %{:file_name => "Main.hx", :line_number => 160, :class_name => "Main", :method_name => "functionalMethods"})
    has_very_long = ArrayTools.any(strings, fn s -> length(s) > 10 end)
    Log.trace("Has very long word: " <> Std.string(has_very_long), %{:file_name => "Main.hx", :line_number => 163, :class_name => "Main", :method_name => "functionalMethods"})
    all_positive = ArrayTools.foreach(numbers, fn n -> n > 0 end)
    Log.trace("All positive: " <> Std.string(all_positive), %{:file_name => "Main.hx", :line_number => 167, :class_name => "Main", :method_name => "functionalMethods"})
    all_short = ArrayTools.all(strings, fn s -> length(s) < 10 end)
    Log.trace("All short words: " <> Std.string(all_short), %{:file_name => "Main.hx", :line_number => 170, :class_name => "Main", :method_name => "functionalMethods"})
    Log.trace("Numbers via forEach:", %{:file_name => "Main.hx", :line_number => 173, :class_name => "Main", :method_name => "functionalMethods"})
    ArrayTools.for_each(numbers, fn n -> Log.trace("  - " <> Kernel.to_string(n), %{:file_name => "Main.hx", :line_number => 174, :class_name => "Main", :method_name => "functionalMethods"}) end)
    first3 = ArrayTools.take(numbers, 3)
    Log.trace("First 3 numbers: " <> Std.string(first3), %{:file_name => "Main.hx", :line_number => 178, :class_name => "Main", :method_name => "functionalMethods"})
    skip2 = ArrayTools.drop(numbers, 2)
    Log.trace("Skip first 2: " <> Std.string(skip2), %{:file_name => "Main.hx", :line_number => 182, :class_name => "Main", :method_name => "functionalMethods"})
    nested_arrays = [[1, 2], [3, 4], [5]]
    flattened = ArrayTools.flat_map(nested_arrays, fn arr -> Enum.map(arr, fn x -> x * 2 end) end)
    Log.trace("FlatMap doubled: " <> Std.string(flattened), %{:file_name => "Main.hx", :line_number => 187, :class_name => "Main", :method_name => "functionalMethods"})
    processed = ArrayTools.reduce(ArrayTools.take(Enum.map(Enum.filter(numbers, fn n -> n > 2 end), fn n -> n * n end), 2), fn acc, n -> acc + n end, 0)
    Log.trace("Chained operations result: " <> Kernel.to_string(processed), %{:file_name => "Main.hx", :line_number => 195, :class_name => "Main", :method_name => "functionalMethods"})
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
    Log.trace("Processed: " <> Std.string(result), %{:file_name => "Main.hx", :line_number => 216, :class_name => "Main", :method_name => "main"})
    first3 = first_n(["a", "b", "c", "d", "e"], 3)
    Log.trace("First 3: " <> Std.string(first3), %{:file_name => "Main.hx", :line_number => 219, :class_name => "Main", :method_name => "main"})
    Log.trace("\n=== NEW: Functional Array Methods ===", %{:file_name => "Main.hx", :line_number => 221, :class_name => "Main", :method_name => "main"})
    functional_methods()
  end
end