defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Arrays test case
     * Tests array operations and list comprehensions
  """

  # Static functions
  @doc "Function basic_array_ops"
  @spec basic_array_ops() :: nil
  def basic_array_ops() do
    numbers = [1, 2, 3, 4, 5]
    Log.trace(Enum.at(numbers, 0), %{"fileName" => "Main.hx", "lineNumber" => 14, "className" => "Main", "methodName" => "basicArrayOps"})
    Log.trace(numbers.length, %{"fileName" => "Main.hx", "lineNumber" => 15, "className" => "Main", "methodName" => "basicArrayOps"})
    numbers ++ [6]
    [0 | numbers]
    popped = List.last(numbers)
    shifted = hd(numbers)
    Log.trace("Popped: " <> to_string(popped) <> ", Shifted: " <> to_string(shifted), %{"fileName" => "Main.hx", "lineNumber" => 22, "className" => "Main", "methodName" => "basicArrayOps"})
    mixed = [1, "hello", true, 3.14]
    Log.trace(mixed, %{"fileName" => "Main.hx", "lineNumber" => 26, "className" => "Main", "methodName" => "basicArrayOps"})
  end

  @doc "Function array_iteration"
  @spec array_iteration() :: nil
  def array_iteration() do
    (
          fruits = ["apple", "banana", "orange", "grape"]
          (
          g_counter = 0
          while_loop(fn -> ((g < fruits.length)) end, fn -> (
          fruit = Enum.at(fruits, g)
          g + 1
          Log.trace("Fruit: " <> fruit, %{"fileName" => "Main.hx", "lineNumber" => 35, "className" => "Main", "methodName" => "arrayIteration"})
        ) end)
        )
          (
          g_counter = 0
          g = fruits.length
          while_loop(fn -> ((g < g)) end, fn -> (
          i = g + 1
          Log.trace("" <> to_string(i) <> ": " <> Enum.at(fruits, i), %{"fileName" => "Main.hx", "lineNumber" => 40, "className" => "Main", "methodName" => "arrayIteration"})
        ) end)
        )
          i = 0
          while_loop(fn -> ((i < fruits.length)) end, fn -> (
          Log.trace("While: " <> Enum.at(fruits, i), %{"fileName" => "Main.hx", "lineNumber" => 46, "className" => "Main", "methodName" => "arrayIteration"})
          i + 1
        ) end)
        )
  end

  @doc "Function array_methods"
  @spec array_methods() :: nil
  def array_methods() do
    numbers = [1, 2, 3, 4, 5]
    temp_array = nil
    (
          g_array = []
          (
          g_counter = 0
          while_loop(fn -> ((g < numbers.length)) end, fn -> (
          v = Enum.at(numbers, g)
          g + 1
          g ++ [(v * 2)]
        ) end)
        )
          temp_array = g
        )
    Log.trace("Doubled: " <> Std.string(temp_array), %{"fileName" => "Main.hx", "lineNumber" => 57, "className" => "Main", "methodName" => "arrayMethods"})
    temp_array1 = nil
    (
          g_array = []
          (
          g_counter = 0
          while_loop(fn -> ((g < numbers.length)) end, fn -> (
          v = Enum.at(numbers, g)
          g + 1
          if ((rem(v, 2) == 0)) do
          g ++ [v]
        end
        ) end)
        )
          temp_array1 = g
        )
    Log.trace("Evens: " <> Std.string(temp_array1), %{"fileName" => "Main.hx", "lineNumber" => 61, "className" => "Main", "methodName" => "arrayMethods"})
    more = [6, 7, 8]
    combined = numbers ++ more
    Log.trace("Combined: " <> Std.string(combined), %{"fileName" => "Main.hx", "lineNumber" => 66, "className" => "Main", "methodName" => "arrayMethods"})
    words = ["Hello", "World", "from", "Haxe"]
    sentence = Enum.join(words, " ")
    Log.trace("Sentence: " <> sentence, %{"fileName" => "Main.hx", "lineNumber" => 71, "className" => "Main", "methodName" => "arrayMethods"})
    reversed = numbers
    Enum.reverse(reversed)
    Log.trace("Reversed: " <> Std.string(reversed), %{"fileName" => "Main.hx", "lineNumber" => 76, "className" => "Main", "methodName" => "arrayMethods"})
    unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
    Enum.sort(unsorted, fn a, b -> (a - b) end)
    Log.trace("Sorted: " <> Std.string(unsorted), %{"fileName" => "Main.hx", "lineNumber" => 81, "className" => "Main", "methodName" => "arrayMethods"})
  end

  @doc "Function array_comprehensions"
  @spec array_comprehensions() :: nil
  def array_comprehensions() do
    temp_array = nil
    (
          g_array = []
          (
          g ++ [1]
          g ++ [4]
          g ++ [9]
          g ++ [16]
          g ++ [25]
        )
          temp_array = g
        )
    Log.trace("Squares: " <> Std.string(temp_array), %{"fileName" => "Main.hx", "lineNumber" => 88, "className" => "Main", "methodName" => "arrayComprehensions"})
    temp_array1 = nil
    (
          g_array = []
          if ((rem(1, 2) == 0)) do
          g ++ [1]
        end
    if ((rem(2, 2) == 0)) do
          g ++ [4]
        end
    if ((rem(3, 2) == 0)) do
          g ++ [9]
        end
    if ((rem(4, 2) == 0)) do
          g ++ [16]
        end
    if ((rem(5, 2) == 0)) do
          g ++ [25]
        end
    if ((rem(6, 2) == 0)) do
          g ++ [36]
        end
    if ((rem(7, 2) == 0)) do
          g ++ [49]
        end
    if ((rem(8, 2) == 0)) do
          g ++ [64]
        end
    if ((rem(9, 2) == 0)) do
          g ++ [81]
        end
          temp_array1 = g
        )
    Log.trace("Even squares: " <> Std.string(temp_array1), %{"fileName" => "Main.hx", "lineNumber" => 92, "className" => "Main", "methodName" => "arrayComprehensions"})
    temp_array2 = nil
    (
          g_array = []
          (
          (
          g ++ [%{"x" => 1, "y" => 2}]
          g ++ [%{"x" => 1, "y" => 3}]
        )
          (
          g ++ [%{"x" => 2, "y" => 1}]
          g ++ [%{"x" => 2, "y" => 3}]
        )
          (
          g ++ [%{"x" => 3, "y" => 1}]
          g ++ [%{"x" => 3, "y" => 2}]
          nil
        )
        )
          temp_array2 = g
        )
    Log.trace("Pairs: " <> Std.string(temp_array2), %{"fileName" => "Main.hx", "lineNumber" => 96, "className" => "Main", "methodName" => "arrayComprehensions"})
  end

  @doc "Function multi_dimensional"
  @spec multi_dimensional() :: nil
  def multi_dimensional() do
    (
          matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
          Log.trace("Matrix element [1][2]: " <> to_string(Enum.at(Enum.at(matrix, 1), 2)), %{"fileName" => "Main.hx", "lineNumber" => 108, "className" => "Main", "methodName" => "multiDimensional"})
          (
          g_counter = 0
          while_loop(fn -> ((g < matrix.length)) end, fn -> (
          row = Enum.at(matrix, g)
          g + 1
          (
          g_counter = 0
          while_loop(fn -> ((g < row.length)) end, fn -> (
          elem_ = Enum.at(row, g)
          g + 1
          Log.trace("Element: " <> to_string(elem_), %{"fileName" => "Main.hx", "lineNumber" => 113, "className" => "Main", "methodName" => "multiDimensional"})
        ) end)
        )
        ) end)
        )
          temp_array = nil
          (
          g_array = []
          temp_array1 = nil
    (
          g_array = []
          (
          g ++ [0]
          g ++ [1]
          g ++ [2]
        )
          temp_array1 = g
        )
    g ++ [temp_array1]
    temp_array2 = nil
    (
          g_array = []
          (
          g ++ [3]
          g ++ [4]
          g ++ [5]
        )
          temp_array2 = g
        )
    g ++ [temp_array2]
    temp_array3 = nil
    (
          g_array = []
          (
          g ++ [6]
          g ++ [7]
          g ++ [8]
        )
          temp_array3 = g
        )
    g ++ [temp_array3]
          temp_array = g
        )
          Log.trace("Grid: " <> Std.string(temp_array), %{"fileName" => "Main.hx", "lineNumber" => 119, "className" => "Main", "methodName" => "multiDimensional"})
        )
  end

  @doc "Function process_array"
  @spec process_array(Array.t()) :: Array.t()
  def process_array(arr) do
    (
          temp_result = nil
          temp_array = nil
          (
          g_array = []
          (
          g_counter = 0
          while_loop(fn -> ((g < arr.length)) end, fn -> (
          v = Enum.at(arr, g)
          g + 1
          g ++ [(v * v)]
        ) end)
        )
          temp_array = g
        )
          (
          g_array = []
          (
          g_counter = 0
          while_loop(fn -> ((g < temp_array.length)) end, fn -> (
          v = Enum.at(temp_array, g)
          g + 1
          if ((v > 10)) do
          g ++ [v]
        end
        ) end)
        )
          temp_result = g
        )
          temp_result
        )
  end

  @doc "Function first_n"
  @spec first_n(Array.t(), integer()) :: Array.t()
  def first_n(arr, n) do
    (
          g_array = []
          g_counter = 0
          g = Std.int(Math.min(n, arr.length))
          while_loop(fn -> ((g < g)) end, fn -> (
          i = g + 1
          g ++ [Enum.at(arr, i)]
        ) end)
          g
        )
  end

  @doc "Function functional_methods"
  @spec functional_methods() :: nil
  def functional_methods() do
    numbers = [1, 2, 3, 4, 5]
    strings = ["hello", "world", "haxe", "elixir"]
    sum = Enum.reduce(numbers, 0, fn item, acc -> (acc + item) end)
    Log.trace("Sum via reduce: " <> to_string(sum), %{"fileName" => "Main.hx", "lineNumber" => 139, "className" => "Main", "methodName" => "functionalMethods"})
    product = Enum.reduce(numbers, 1, fn item, acc -> (acc * item) end)
    Log.trace("Product via fold: " <> to_string(product), %{"fileName" => "Main.hx", "lineNumber" => 142, "className" => "Main", "methodName" => "functionalMethods"})
    first_even = Enum.find(numbers, fn n -> (rem(n, 2) == 0) end)
    Log.trace("First even number: " <> to_string(first_even), %{"fileName" => "Main.hx", "lineNumber" => 146, "className" => "Main", "methodName" => "functionalMethods"})
    long_word = Enum.find(strings, fn s -> (s.length > 4) end)
    Log.trace("First long word: " <> to_string(long_word), %{"fileName" => "Main.hx", "lineNumber" => 149, "className" => "Main", "methodName" => "functionalMethods"})
    even_index = ArrayTools.find_index(numbers, fn n -> (rem(n, 2) == 0) end)
    Log.trace("Index of first even: " <> to_string(even_index), %{"fileName" => "Main.hx", "lineNumber" => 153, "className" => "Main", "methodName" => "functionalMethods"})
    long_word_index = ArrayTools.find_index(strings, fn s -> (s.length > 4) end)
    Log.trace("Index of first long word: " <> to_string(long_word_index), %{"fileName" => "Main.hx", "lineNumber" => 156, "className" => "Main", "methodName" => "functionalMethods"})
    has_even = Enum.any?(numbers, fn n -> (rem(n, 2) == 0) end)
    Log.trace("Has even numbers: " <> Std.string(has_even), %{"fileName" => "Main.hx", "lineNumber" => 160, "className" => "Main", "methodName" => "functionalMethods"})
    has_very_long = Enum.any?(strings, fn s -> (s.length > 10) end)
    Log.trace("Has very long word: " <> Std.string(has_very_long), %{"fileName" => "Main.hx", "lineNumber" => 163, "className" => "Main", "methodName" => "functionalMethods"})
    all_positive = Enum.all?(numbers, fn n -> (n > 0) end)
    Log.trace("All positive: " <> Std.string(all_positive), %{"fileName" => "Main.hx", "lineNumber" => 167, "className" => "Main", "methodName" => "functionalMethods"})
    all_short = Enum.all?(strings, fn s -> (s.length < 10) end)
    Log.trace("All short words: " <> Std.string(all_short), %{"fileName" => "Main.hx", "lineNumber" => 170, "className" => "Main", "methodName" => "functionalMethods"})
    Log.trace("Numbers via forEach:", %{"fileName" => "Main.hx", "lineNumber" => 173, "className" => "Main", "methodName" => "functionalMethods"})
    ArrayTools.for_each(numbers, fn n -> Log.trace("  - " <> to_string(n), %{"fileName" => "Main.hx", "lineNumber" => 174, "className" => "Main", "methodName" => "functionalMethods"}) end)
    first3 = Enum.take(numbers, 3)
    Log.trace("First 3 numbers: " <> Std.string(first3), %{"fileName" => "Main.hx", "lineNumber" => 178, "className" => "Main", "methodName" => "functionalMethods"})
    skip2 = Enum.drop(numbers, 2)
    Log.trace("Skip first 2: " <> Std.string(skip2), %{"fileName" => "Main.hx", "lineNumber" => 182, "className" => "Main", "methodName" => "functionalMethods"})
    nested_arrays = [[1, 2], [3, 4], [5]]
    flattened = ArrayTools.flat_map(nested_arrays, fn arr -> (
          temp_result = nil
          (
          g_array = []
          (
          g_counter = 0
          g = arr
          while_loop(fn -> ((g < g.length)) end, fn -> (
          v = Enum.at(g, g)
          g + 1
          g ++ [(v * 2)]
        ) end)
        )
          temp_result = g
        )
          temp_result
        ) end)
    Log.trace("FlatMap doubled: " <> Std.string(flattened), %{"fileName" => "Main.hx", "lineNumber" => 187, "className" => "Main", "methodName" => "functionalMethods"})
    temp_array = nil
    temp_array1 = nil
    (
          g_array = []
          (
          g_counter = 0
          while_loop(fn -> ((g < numbers.length)) end, fn -> (
          v = Enum.at(numbers, g)
          g + 1
          if ((v > 2)) do
          g ++ [v]
        end
        ) end)
        )
          temp_array1 = g
        )
    (
          g_array = []
          (
          g_counter = 0
          while_loop(fn -> ((g < temp_array1.length)) end, fn -> (
          v = Enum.at(temp_array1, g)
          g + 1
          g ++ [(v * v)]
        ) end)
        )
          temp_array = g
        )
    processed = Enum.reduce(Enum.take(temp_array, 2), 0, fn item, acc -> (acc + item) end)
    Log.trace("Chained operations result: " <> to_string(processed), %{"fileName" => "Main.hx", "lineNumber" => 195, "className" => "Main", "methodName" => "functionalMethods"})
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("=== Basic Array Operations ===", %{"fileName" => "Main.hx", "lineNumber" => 199, "className" => "Main", "methodName" => "main"})
    Main.basic_array_ops()
    Log.trace("\n=== Array Iteration ===", %{"fileName" => "Main.hx", "lineNumber" => 202, "className" => "Main", "methodName" => "main"})
    Main.array_iteration()
    Log.trace("\n=== Array Methods ===", %{"fileName" => "Main.hx", "lineNumber" => 205, "className" => "Main", "methodName" => "main"})
    Main.array_methods()
    Log.trace("\n=== Array Comprehensions ===", %{"fileName" => "Main.hx", "lineNumber" => 208, "className" => "Main", "methodName" => "main"})
    Main.array_comprehensions()
    Log.trace("\n=== Multi-dimensional Arrays ===", %{"fileName" => "Main.hx", "lineNumber" => 211, "className" => "Main", "methodName" => "main"})
    Main.multi_dimensional()
    Log.trace("\n=== Array Functions ===", %{"fileName" => "Main.hx", "lineNumber" => 214, "className" => "Main", "methodName" => "main"})
    result = Main.process_array([1, 2, 3, 4, 5])
    Log.trace("Processed: " <> Std.string(result), %{"fileName" => "Main.hx", "lineNumber" => 216, "className" => "Main", "methodName" => "main"})
    first3 = Main.first_n(["a", "b", "c", "d", "e"], 3)
    Log.trace("First 3: " <> Std.string(first3), %{"fileName" => "Main.hx", "lineNumber" => 219, "className" => "Main", "methodName" => "main"})
    Log.trace("\n=== NEW: Functional Array Methods ===", %{"fileName" => "Main.hx", "lineNumber" => 221, "className" => "Main", "methodName" => "main"})
    Main.functional_methods()
  end

end
