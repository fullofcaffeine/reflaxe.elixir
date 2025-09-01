defmodule Main do
  def basic_array_ops() do
    numbers = [1, 2, 3, 4, 5]
    Log.trace(numbers[0], %{:fileName => "Main.hx", :lineNumber => 14, :className => "Main", :methodName => "basicArrayOps"})
    Log.trace(numbers.length, %{:fileName => "Main.hx", :lineNumber => 15, :className => "Main", :methodName => "basicArrayOps"})
    numbers.push(6)
    [0 | numbers]
    popped = List.last(numbers)
    shifted = List.first(numbers)
    Log.trace("Popped: " + popped + ", Shifted: " + shifted, %{:fileName => "Main.hx", :lineNumber => 22, :className => "Main", :methodName => "basicArrayOps"})
    mixed = [1, "hello", true, 3.14]
    Log.trace(mixed, %{:fileName => "Main.hx", :lineNumber => 26, :className => "Main", :methodName => "basicArrayOps"})
  end
  def array_iteration() do
    fruits = ["apple", "banana", "orange", "grape"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < fruits.length) do
  fruit = fruits[g]
  g + 1
  Log.trace("Fruit: " + fruit, %{:fileName => "Main.hx", :lineNumber => 35, :className => "Main", :methodName => "arrayIteration"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    g = 0
    g1 = fruits.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  Log.trace("" + i + ": " + fruits[i], %{:fileName => "Main.hx", :lineNumber => 40, :className => "Main", :methodName => "arrayIteration"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (i < fruits.length) do
  Log.trace("While: " + fruits[i], %{:fileName => "Main.hx", :lineNumber => 46, :className => "Main", :methodName => "arrayIteration"})
  i + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  def array_methods() do
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    Log.trace("Doubled: " + Std.string(doubled), %{:fileName => "Main.hx", :lineNumber => 57, :className => "Main", :methodName => "arrayMethods"})
    evens = Enum.filter(numbers, fn n -> n rem 2 == 0 end)
    Log.trace("Evens: " + Std.string(evens), %{:fileName => "Main.hx", :lineNumber => 61, :className => "Main", :methodName => "arrayMethods"})
    more = [6, 7, 8]
    combined = numbers ++ more
    Log.trace("Combined: " + Std.string(combined), %{:fileName => "Main.hx", :lineNumber => 66, :className => "Main", :methodName => "arrayMethods"})
    words = ["Hello", "World", "from", "Haxe"]
    sentence = Enum.join(words, " ")
    Log.trace("Sentence: " + sentence, %{:fileName => "Main.hx", :lineNumber => 71, :className => "Main", :methodName => "arrayMethods"})
    reversed = numbers
    Enum.reverse(reversed)
    Log.trace("Reversed: " + Std.string(reversed), %{:fileName => "Main.hx", :lineNumber => 76, :className => "Main", :methodName => "arrayMethods"})
    unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
    Enum.sort(unsorted, fn a, b -> a - b end)
    Log.trace("Sorted: " + Std.string(unsorted), %{:fileName => "Main.hx", :lineNumber => 81, :className => "Main", :methodName => "arrayMethods"})
  end
  def array_comprehensions() do
    squares = g = []
g.push(1)
g.push(4)
g.push(9)
g.push(16)
g.push(25)
g
    Log.trace("Squares: " + Std.string(squares), %{:fileName => "Main.hx", :lineNumber => 88, :className => "Main", :methodName => "arrayComprehensions"})
    even_squares = g = []
if (1 rem 2 == 0), do: g.push(1)
if (2 rem 2 == 0), do: g.push(4)
if (3 rem 2 == 0), do: g.push(9)
if (4 rem 2 == 0), do: g.push(16)
if (5 rem 2 == 0), do: g.push(25)
if (6 rem 2 == 0), do: g.push(36)
if (7 rem 2 == 0), do: g.push(49)
if (8 rem 2 == 0), do: g.push(64)
if (9 rem 2 == 0), do: g.push(81)
g
    Log.trace("Even squares: " + Std.string(even_squares), %{:fileName => "Main.hx", :lineNumber => 92, :className => "Main", :methodName => "arrayComprehensions"})
    pairs = g = []
g.push(%{:x => 1, :y => 2})
g.push(%{:x => 1, :y => 3})
g.push(%{:x => 2, :y => 1})
g.push(%{:x => 2, :y => 3})
g.push(%{:x => 3, :y => 1})
g.push(%{:x => 3, :y => 2})
nil
g
    Log.trace("Pairs: " + Std.string(pairs), %{:fileName => "Main.hx", :lineNumber => 96, :className => "Main", :methodName => "arrayComprehensions"})
  end
  def multi_dimensional() do
    matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    Log.trace("Matrix element [1][2]: " + matrix[1][2], %{:fileName => "Main.hx", :lineNumber => 108, :className => "Main", :methodName => "multiDimensional"})
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < matrix.length) do
  row = matrix[g]
  g + 1
  g = 0
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < row.length) do
  elem = row[g]
  g + 1
  Log.trace("Element: " + elem, %{:fileName => "Main.hx", :lineNumber => 113, :className => "Main", :methodName => "multiDimensional"})
  {:cont, acc}
else
  {:halt, acc}
end end)
  {:cont, acc}
else
  {:halt, acc}
end end)
    grid = g = []
g.push(g = []
g.push(0)
g.push(1)
g.push(2)
g)
g.push(g = []
g.push(3)
g.push(4)
g.push(5)
g)
g.push(g = []
g.push(6)
g.push(7)
g.push(8)
g)
g
    Log.trace("Grid: " + Std.string(grid), %{:fileName => "Main.hx", :lineNumber => 119, :className => "Main", :methodName => "multiDimensional"})
  end
  def process_array(arr) do
    Enum.filter(Enum.map(arr, fn x -> x * x end), fn x -> x > 10 end)
  end
  def first_n(arr, n) do
    g = []
    g1 = 0
    g2 = Std.int(Math.min(n, arr.length))
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g1 < g2) do
  i = g1 + 1
  g.push(arr[i])
  {:cont, acc}
else
  {:halt, acc}
end end)
    g
  end
  def functional_methods() do
    numbers = [1, 2, 3, 4, 5]
    strings = ["hello", "world", "haxe", "elixir"]
    sum = ArrayTools.reduce(numbers, fn acc, item -> acc + item end, 0)
    Log.trace("Sum via reduce: " + sum, %{:fileName => "Main.hx", :lineNumber => 139, :className => "Main", :methodName => "functionalMethods"})
    product = ArrayTools.fold(numbers, fn acc, item -> acc * item end, 1)
    Log.trace("Product via fold: " + product, %{:fileName => "Main.hx", :lineNumber => 142, :className => "Main", :methodName => "functionalMethods"})
    first_even = ArrayTools.find(numbers, fn n -> n rem 2 == 0 end)
    Log.trace("First even number: " + first_even, %{:fileName => "Main.hx", :lineNumber => 146, :className => "Main", :methodName => "functionalMethods"})
    long_word = ArrayTools.find(strings, fn s -> s.length > 4 end)
    Log.trace("First long word: " + long_word, %{:fileName => "Main.hx", :lineNumber => 149, :className => "Main", :methodName => "functionalMethods"})
    even_index = ArrayTools.find_index(numbers, fn n -> n rem 2 == 0 end)
    Log.trace("Index of first even: " + even_index, %{:fileName => "Main.hx", :lineNumber => 153, :className => "Main", :methodName => "functionalMethods"})
    long_word_index = ArrayTools.find_index(strings, fn s -> s.length > 4 end)
    Log.trace("Index of first long word: " + long_word_index, %{:fileName => "Main.hx", :lineNumber => 156, :className => "Main", :methodName => "functionalMethods"})
    has_even = ArrayTools.exists(numbers, fn n -> n rem 2 == 0 end)
    Log.trace("Has even numbers: " + Std.string(has_even), %{:fileName => "Main.hx", :lineNumber => 160, :className => "Main", :methodName => "functionalMethods"})
    has_very_long = ArrayTools.any(strings, fn s -> s.length > 10 end)
    Log.trace("Has very long word: " + Std.string(has_very_long), %{:fileName => "Main.hx", :lineNumber => 163, :className => "Main", :methodName => "functionalMethods"})
    all_positive = ArrayTools.foreach(numbers, fn n -> n > 0 end)
    Log.trace("All positive: " + Std.string(all_positive), %{:fileName => "Main.hx", :lineNumber => 167, :className => "Main", :methodName => "functionalMethods"})
    all_short = ArrayTools.all(strings, fn s -> s.length < 10 end)
    Log.trace("All short words: " + Std.string(all_short), %{:fileName => "Main.hx", :lineNumber => 170, :className => "Main", :methodName => "functionalMethods"})
    Log.trace("Numbers via forEach:", %{:fileName => "Main.hx", :lineNumber => 173, :className => "Main", :methodName => "functionalMethods"})
    ArrayTools.for_each(numbers, fn n -> Log.trace("  - " + n, %{:fileName => "Main.hx", :lineNumber => 174, :className => "Main", :methodName => "functionalMethods"}) end)
    first_3 = ArrayTools.take(numbers, 3)
    Log.trace("First 3 numbers: " + Std.string(first), %{:fileName => "Main.hx", :lineNumber => 178, :className => "Main", :methodName => "functionalMethods"})
    skip_2 = ArrayTools.drop(numbers, 2)
    Log.trace("Skip first 2: " + Std.string(skip), %{:fileName => "Main.hx", :lineNumber => 182, :className => "Main", :methodName => "functionalMethods"})
    nested_arrays = [[1, 2], [3, 4], [5]]
    flattened = ArrayTools.flat_map(nested_arrays, fn arr -> Enum.map(arr, fn x -> x * 2 end) end)
    Log.trace("FlatMap doubled: " + Std.string(flattened), %{:fileName => "Main.hx", :lineNumber => 187, :className => "Main", :methodName => "functionalMethods"})
    processed = ArrayTools.reduce(ArrayTools.take(Enum.map(Enum.filter(numbers, fn n -> n > 2 end), fn n -> n * n end), 2), fn acc, n -> acc + n end, 0)
    Log.trace("Chained operations result: " + processed, %{:fileName => "Main.hx", :lineNumber => 195, :className => "Main", :methodName => "functionalMethods"})
  end
  def main() do
    Log.trace("=== Basic Array Operations ===", %{:fileName => "Main.hx", :lineNumber => 199, :className => "Main", :methodName => "main"})
    Main.basic_array_ops()
    Log.trace("\n=== Array Iteration ===", %{:fileName => "Main.hx", :lineNumber => 202, :className => "Main", :methodName => "main"})
    Main.array_iteration()
    Log.trace("\n=== Array Methods ===", %{:fileName => "Main.hx", :lineNumber => 205, :className => "Main", :methodName => "main"})
    Main.array_methods()
    Log.trace("\n=== Array Comprehensions ===", %{:fileName => "Main.hx", :lineNumber => 208, :className => "Main", :methodName => "main"})
    Main.array_comprehensions()
    Log.trace("\n=== Multi-dimensional Arrays ===", %{:fileName => "Main.hx", :lineNumber => 211, :className => "Main", :methodName => "main"})
    Main.multi_dimensional()
    Log.trace("\n=== Array Functions ===", %{:fileName => "Main.hx", :lineNumber => 214, :className => "Main", :methodName => "main"})
    result = Main.process_array([1, 2, 3, 4, 5])
    Log.trace("Processed: " + Std.string(result), %{:fileName => "Main.hx", :lineNumber => 216, :className => "Main", :methodName => "main"})
    first_3 = Main.first_n(["a", "b", "c", "d", "e"], 3)
    Log.trace("First 3: " + Std.string(first), %{:fileName => "Main.hx", :lineNumber => 219, :className => "Main", :methodName => "main"})
    Log.trace("\n=== NEW: Functional Array Methods ===", %{:fileName => "Main.hx", :lineNumber => 221, :className => "Main", :methodName => "main"})
    Main.functional_methods()
  end
end