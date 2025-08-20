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
    Log.trace("Popped: " <> Kernel.inspect(popped) <> ", Shifted: " <> Kernel.inspect(shifted), %{"fileName" => "Main.hx", "lineNumber" => 22, "className" => "Main", "methodName" => "basicArrayOps"})
    mixed = [1, "hello", true, 3.14]
    Log.trace(mixed, %{"fileName" => "Main.hx", "lineNumber" => 26, "className" => "Main", "methodName" => "basicArrayOps"})
  end

  @doc "Function array_iteration"
  @spec array_iteration() :: nil
  def array_iteration() do
    fruits = ["apple", "banana", "orange", "grape"]
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < fruits.length) do
          try do
            fruit = Enum.at(fruits, g)
          g = g + 1
          Log.trace("Fruit: " <> fruit, %{"fileName" => "Main.hx", "lineNumber" => 35, "className" => "Main", "methodName" => "arrayIteration"})
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    _g_counter = 0
    _g_1 = Enum.count(fruits)
    (
      loop_helper = fn loop_fn ->
        if (g < g) do
          i = g = g + 1
    Log.trace("" ++ i ++ ": " ++ Enum.at(fruits, i), %{"fileName" => "Main.hx", "lineNumber" => 40, "className" => "Main", "methodName" => "arrayIteration"})
          loop_fn.()
        else
          nil
        end
      end
      loop_helper.(loop_helper)
    )
    i = 0
    (
      loop_helper = fn loop_fn, {i} ->
        if (i < fruits.length) do
          try do
            Log.trace("While: " <> Enum.at(fruits, i), %{"fileName" => "Main.hx", "lineNumber" => 46, "className" => "Main", "methodName" => "arrayIteration"})
          i = i + 1
          loop_fn.({i + 1})
            loop_fn.(loop_fn, {i})
          catch
            :break -> {i}
            :continue -> loop_fn.(loop_fn, {i})
          end
        else
          {i}
        end
      end
      {i} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
  end

  @doc "Function array_methods"
  @spec array_methods() :: nil
  def array_methods() do
    numbers = [1, 2, 3, 4, 5]
    temp_array = nil
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < numbers.length) do
          try do
            v = Enum.at(numbers, g)
          g = g + 1
          g ++ [v * 2]
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array = g
    Log.trace("Doubled: " <> Std.string(temp_array), %{"fileName" => "Main.hx", "lineNumber" => 57, "className" => "Main", "methodName" => "arrayMethods"})
    temp_array1 = nil
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < numbers.length) do
          try do
            v = Enum.at(numbers, g)
          g = g + 1
          if (v rem 2 == 0), do: g ++ [v], else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array1 = g
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
    Enum.sort(unsorted, fn a, b -> a - b end)
    Log.trace("Sorted: " <> Std.string(unsorted), %{"fileName" => "Main.hx", "lineNumber" => 81, "className" => "Main", "methodName" => "arrayMethods"})
  end

  @doc "Function array_comprehensions"
  @spec array_comprehensions() :: nil
  def array_comprehensions() do
    temp_array = nil
    g_array = []
    g ++ [1]
    g ++ [4]
    g ++ [9]
    g ++ [16]
    g ++ [25]
    temp_array = g
    Log.trace("Squares: " <> Std.string(temp_array), %{"fileName" => "Main.hx", "lineNumber" => 88, "className" => "Main", "methodName" => "arrayComprehensions"})
    temp_array1 = nil
    g_array = []
    if (1 rem 2 == 0), do: g ++ [1], else: nil
    if (2 rem 2 == 0), do: g ++ [4], else: nil
    if (3 rem 2 == 0), do: g ++ [9], else: nil
    if (4 rem 2 == 0), do: g ++ [16], else: nil
    if (5 rem 2 == 0), do: g ++ [25], else: nil
    if (6 rem 2 == 0), do: g ++ [36], else: nil
    if (7 rem 2 == 0), do: g ++ [49], else: nil
    if (8 rem 2 == 0), do: g ++ [64], else: nil
    if (9 rem 2 == 0), do: g ++ [81], else: nil
    temp_array1 = g
    Log.trace("Even squares: " <> Std.string(temp_array1), %{"fileName" => "Main.hx", "lineNumber" => 92, "className" => "Main", "methodName" => "arrayComprehensions"})
    temp_array2 = nil
    g_array = []
    g ++ [%{"x" => 1, "y" => 2}]
    g ++ [%{"x" => 1, "y" => 3}]
    g ++ [%{"x" => 2, "y" => 1}]
    g ++ [%{"x" => 2, "y" => 3}]
    g ++ [%{"x" => 3, "y" => 1}]
    g ++ [%{"x" => 3, "y" => 2}]
    nil
    temp_array2 = g
    Log.trace("Pairs: " <> Std.string(temp_array2), %{"fileName" => "Main.hx", "lineNumber" => 96, "className" => "Main", "methodName" => "arrayComprehensions"})
  end

  @doc "Function multi_dimensional"
  @spec multi_dimensional() :: nil
  def multi_dimensional() do
    matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    Log.trace("Matrix element [1][2]: " <> Integer.to_string(Enum.at(Enum.at(matrix, 1), 2)), %{"fileName" => "Main.hx", "lineNumber" => 108, "className" => "Main", "methodName" => "multiDimensional"})
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < matrix.length) do
          try do
            row = Enum.at(matrix, g)
          g = g + 1
          g = 0
          (
      loop_helper = fn loop_fn, {g} ->
        if (g < row.length) do
          try do
            elem_ = Enum.at(row, g)
          g = g + 1
          Log.trace("Element: " <> Integer.to_string(elem_), %{"fileName" => "Main.hx", "lineNumber" => 113, "className" => "Main", "methodName" => "multiDimensional"})
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array = nil
    g_array = []
    temp_array1 = nil
    g_array = []
    g ++ [0]
    g ++ [1]
    g ++ [2]
    temp_array1 = g
    g ++ [temp_array1]
    temp_array2 = nil
    g_array = []
    g ++ [3]
    g ++ [4]
    g ++ [5]
    temp_array2 = g
    g ++ [temp_array2]
    temp_array3 = nil
    g_array = []
    g ++ [6]
    g ++ [7]
    g ++ [8]
    temp_array3 = g
    g ++ [temp_array3]
    temp_array = g
    Log.trace("Grid: " <> Std.string(temp_array), %{"fileName" => "Main.hx", "lineNumber" => 119, "className" => "Main", "methodName" => "multiDimensional"})
  end

  @doc "Function process_array"
  @spec process_array(Array.t()) :: Array.t()
  def process_array(arr) do
    temp_result = nil
    temp_array = nil
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < arr.length) do
          try do
            v = Enum.at(arr, g)
          g = g + 1
          g ++ [v * v]
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array = g
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < temp_array.length) do
          try do
            v = Enum.at(temp_array, g)
          g = g + 1
          if (v > 10), do: g ++ [v], else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_result = g
    temp_result
  end

  @doc "Function first_n"
  @spec first_n(Array.t(), integer()) :: Array.t()
  def first_n(arr, n) do
    _g_array = []
    _g_counter = 0
    _g_2 = Std.int(Math.min(n, Enum.count(arr)))
    (
      loop_helper = fn loop_fn ->
        if (g < g) do
          i = g = g + 1
    _g_2.push(Enum.at(arr, i))
          loop_fn.()
        else
          nil
        end
      end
      loop_helper.(loop_helper)
    )
    g
  end

  @doc "Function functional_methods"
  @spec functional_methods() :: nil
  def functional_methods() do
    numbers = [1, 2, 3, 4, 5]
    strings = ["hello", "world", "haxe", "elixir"]
    sum = Enum.reduce(numbers, 0, fn item, acc -> acc + item end)
    Log.trace("Sum via reduce: " <> Integer.to_string(sum), %{"fileName" => "Main.hx", "lineNumber" => 139, "className" => "Main", "methodName" => "functionalMethods"})
    product = Enum.reduce(numbers, 1, fn item, acc -> acc * item end)
    Log.trace("Product via fold: " <> Integer.to_string(product), %{"fileName" => "Main.hx", "lineNumber" => 142, "className" => "Main", "methodName" => "functionalMethods"})
    first_even = Enum.find(numbers, fn n -> n rem 2 == 0 end)
    Log.trace("First even number: " <> Kernel.inspect(first_even), %{"fileName" => "Main.hx", "lineNumber" => 146, "className" => "Main", "methodName" => "functionalMethods"})
    long_word = Enum.find(strings, fn s -> s.length > 4 end)
    Log.trace("First long word: " <> Kernel.inspect(long_word), %{"fileName" => "Main.hx", "lineNumber" => 149, "className" => "Main", "methodName" => "functionalMethods"})
    even_index = ArrayTools.find_index(numbers, fn n -> n rem 2 == 0 end)
    Log.trace("Index of first even: " <> Integer.to_string(even_index), %{"fileName" => "Main.hx", "lineNumber" => 153, "className" => "Main", "methodName" => "functionalMethods"})
    long_word_index = ArrayTools.find_index(strings, fn s -> s.length > 4 end)
    Log.trace("Index of first long word: " <> Integer.to_string(long_word_index), %{"fileName" => "Main.hx", "lineNumber" => 156, "className" => "Main", "methodName" => "functionalMethods"})
    has_even = Enum.any?(numbers, fn n -> n rem 2 == 0 end)
    Log.trace("Has even numbers: " <> Std.string(has_even), %{"fileName" => "Main.hx", "lineNumber" => 160, "className" => "Main", "methodName" => "functionalMethods"})
    has_very_long = Enum.any?(strings, fn s -> s.length > 10 end)
    Log.trace("Has very long word: " <> Std.string(has_very_long), %{"fileName" => "Main.hx", "lineNumber" => 163, "className" => "Main", "methodName" => "functionalMethods"})
    all_positive = Enum.all?(numbers, fn n -> n > 0 end)
    Log.trace("All positive: " <> Std.string(all_positive), %{"fileName" => "Main.hx", "lineNumber" => 167, "className" => "Main", "methodName" => "functionalMethods"})
    all_short = Enum.all?(strings, fn s -> s.length < 10 end)
    Log.trace("All short words: " <> Std.string(all_short), %{"fileName" => "Main.hx", "lineNumber" => 170, "className" => "Main", "methodName" => "functionalMethods"})
    Log.trace("Numbers via forEach:", %{"fileName" => "Main.hx", "lineNumber" => 173, "className" => "Main", "methodName" => "functionalMethods"})
    ArrayTools.for_each(numbers, fn n -> Log.trace("  - " <> Integer.to_string(n), %{"fileName" => "Main.hx", "lineNumber" => 174, "className" => "Main", "methodName" => "functionalMethods"}) end)
    first3 = Enum.take(numbers, 3)
    Log.trace("First 3 numbers: " <> Std.string(first3), %{"fileName" => "Main.hx", "lineNumber" => 178, "className" => "Main", "methodName" => "functionalMethods"})
    skip2 = Enum.drop(numbers, 2)
    Log.trace("Skip first 2: " <> Std.string(skip2), %{"fileName" => "Main.hx", "lineNumber" => 182, "className" => "Main", "methodName" => "functionalMethods"})
    nested_arrays = [[1, 2], [3, 4], [5]]
    flattened = ArrayTools.flat_map(nested_arrays, fn arr -> temp_result = nil
    g_array = []
    _g_counter = 0
    _g_1 = arr
    (
      loop_helper = fn loop_fn, {g_1} ->
        if (g < g.length) do
          try do
            v = Enum.at(g, g)
    g = g + 1
    _g_1.push(v * 2)
            loop_fn.(loop_fn, {g_1})
          catch
            :break -> {g_1}
            :continue -> loop_fn.(loop_fn, {g_1})
          end
        else
          {g_1}
        end
      end
      {g_1} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_result = g
    temp_result end)
    Log.trace("FlatMap doubled: " <> Std.string(flattened), %{"fileName" => "Main.hx", "lineNumber" => 187, "className" => "Main", "methodName" => "functionalMethods"})
    temp_array = nil
    temp_array1 = nil
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < numbers.length) do
          try do
            v = Enum.at(numbers, g)
          g = g + 1
          if (v > 2), do: g ++ [v], else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array1 = g
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < temp_array1.length) do
          try do
            v = Enum.at(temp_array1, g)
          g = g + 1
          g ++ [v * v]
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array = g
    processed = Enum.reduce(Enum.take(temp_array, 2), 0, fn item, acc -> acc + item end)
    Log.trace("Chained operations result: " <> Integer.to_string(processed), %{"fileName" => "Main.hx", "lineNumber" => 195, "className" => "Main", "methodName" => "functionalMethods"})
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
