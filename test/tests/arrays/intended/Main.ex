defmodule Main do
  use Bitwise
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
    Log.trace(Enum.at(numbers, 0), %{fileName => "Main.hx", lineNumber => 12, className => "Main", methodName => "basicArrayOps"})
    Log.trace(length(numbers), %{fileName => "Main.hx", lineNumber => 13, className => "Main", methodName => "basicArrayOps"})
    numbers ++ [6]
    [0 | numbers]
    popped = List.last(numbers)
    shifted = hd(numbers)
    Log.trace("Popped: " <> Kernel.inspect(popped) <> ", Shifted: " <> Kernel.inspect(shifted), %{fileName => "Main.hx", lineNumber => 20, className => "Main", methodName => "basicArrayOps"})
    mixed = [1, "hello", true, 3.14]
    Log.trace(mixed, %{fileName => "Main.hx", lineNumber => 24, className => "Main", methodName => "basicArrayOps"})
  end

  @doc "Function array_iteration"
  @spec array_iteration() :: nil
  def array_iteration() do
    fruits = ["apple", "banana", "orange", "grape"]
    _g = 0
    Enum.map(fruits, fn item -> fruit = Enum.at(fruits, _g)
    _g = _g + 1
    Log.trace("Fruit: " <> fruit, %{fileName => "Main.hx", lineNumber => 33, className => "Main", methodName => "arrayIteration"}) end)
    _g = 0
    _g = length(fruits)
    (
      try do
        loop_fn = fn ->
          if (_g < _g) do
            try do
              i = _g = _g + 1
    Log.trace("" <> Integer.to_string(i) <> ": " <> Enum.at(fruits, i), %{fileName => "Main.hx", lineNumber => 38, className => "Main", methodName => "arrayIteration"})
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    i = 0
    (
      try do
        loop_fn = fn {i} ->
          if (i < length(fruits)) do
            try do
              Log.trace("While: " <> Enum.at(fruits, i), %{fileName => "Main.hx", lineNumber => 44, className => "Main", methodName => "arrayIteration"})
          # i incremented
          loop_fn.({i + 1})
            catch
              :break -> {i}
              :continue -> loop_fn.({i})
            end
          else
            {i}
          end
        end
        loop_fn.({i})
      catch
        :break -> {i}
      end
    )
  end

  @doc "Function array_methods"
  @spec array_methods() :: nil
  def array_methods() do
    numbers = [1, 2, 3, 4, 5]
    temp_array = nil
    _g = []
    _g = 0
    Enum.map(numbers, fn item -> v = Enum.at(numbers, _g)
    _g = _g + 1
    _g ++ [v * 2] end)
    temp_array = _g
    Log.trace("Doubled: " <> Std.string(temp_array), %{fileName => "Main.hx", lineNumber => 55, className => "Main", methodName => "arrayMethods"})
    temp_array1 = nil
    _g = []
    _g = 0
    Enum.filter(numbers, fn item -> (v rem 2 == 0) end)
    temp_array1 = _g
    Log.trace("Evens: " <> Std.string(temp_array1), %{fileName => "Main.hx", lineNumber => 59, className => "Main", methodName => "arrayMethods"})
    more = [6, 7, 8]
    combined = numbers ++ more
    Log.trace("Combined: " <> Std.string(combined), %{fileName => "Main.hx", lineNumber => 64, className => "Main", methodName => "arrayMethods"})
    words = ["Hello", "World", "from", "Haxe"]
    sentence = Enum.join(words, " ")
    Log.trace("Sentence: " <> sentence, %{fileName => "Main.hx", lineNumber => 69, className => "Main", methodName => "arrayMethods"})
    reversed = numbers
    Enum.reverse(reversed)
    Log.trace("Reversed: " <> Std.string(reversed), %{fileName => "Main.hx", lineNumber => 74, className => "Main", methodName => "arrayMethods"})
    unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
    Enum.sort(unsorted, fn a, b -> a - b end)
    Log.trace("Sorted: " <> Std.string(unsorted), %{fileName => "Main.hx", lineNumber => 79, className => "Main", methodName => "arrayMethods"})
  end

  @doc "Function array_comprehensions"
  @spec array_comprehensions() :: nil
  def array_comprehensions() do
    temp_array = nil
    _g = []
    _g ++ [1]
    _g ++ [4]
    _g ++ [9]
    _g ++ [16]
    _g ++ [25]
    temp_array = _g
    Log.trace("Squares: " <> Std.string(temp_array), %{fileName => "Main.hx", lineNumber => 86, className => "Main", methodName => "arrayComprehensions"})
    temp_array1 = nil
    _g = []
    if (1 rem 2 == 0), do: _g ++ [1], else: nil
    if (2 rem 2 == 0), do: _g ++ [4], else: nil
    if (3 rem 2 == 0), do: _g ++ [9], else: nil
    if (4 rem 2 == 0), do: _g ++ [16], else: nil
    if (5 rem 2 == 0), do: _g ++ [25], else: nil
    if (6 rem 2 == 0), do: _g ++ [36], else: nil
    if (7 rem 2 == 0), do: _g ++ [49], else: nil
    if (8 rem 2 == 0), do: _g ++ [64], else: nil
    if (9 rem 2 == 0), do: _g ++ [81], else: nil
    temp_array1 = _g
    Log.trace("Even squares: " <> Std.string(temp_array1), %{fileName => "Main.hx", lineNumber => 90, className => "Main", methodName => "arrayComprehensions"})
    temp_array2 = nil
    _g = []
    _g ++ [%{x => 1, y => 2}]
    _g ++ [%{x => 1, y => 3}]
    _g ++ [%{x => 2, y => 1}]
    _g ++ [%{x => 2, y => 3}]
    _g ++ [%{x => 3, y => 1}]
    _g ++ [%{x => 3, y => 2}]
    nil
    temp_array2 = _g
    Log.trace("Pairs: " <> Std.string(temp_array2), %{fileName => "Main.hx", lineNumber => 94, className => "Main", methodName => "arrayComprehensions"})
  end

  @doc "Function multi_dimensional"
  @spec multi_dimensional() :: nil
  def multi_dimensional() do
    matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    Log.trace("Matrix element [1][2]: " <> Integer.to_string(Enum.at(Enum.at(matrix, 1), 2)), %{fileName => "Main.hx", lineNumber => 106, className => "Main", methodName => "multiDimensional"})
    _g = 0
    Enum.map(matrix, fn item -> row = Enum.at(matrix, _g)
    _g = _g + 1
    _g = 0
    Enum.map(row, fn item -> elem_ = Enum.at(row, _g)
    _g = _g + 1
    Log.trace("Element: " <> Integer.to_string(elem_), %{fileName => "Main.hx", lineNumber => 111, className => "Main", methodName => "multiDimensional"}) end) end)
    temp_array = nil
    _g = []
    temp_array1 = nil
    _g = []
    _g ++ [0]
    _g ++ [1]
    _g ++ [2]
    temp_array1 = _g
    _g ++ [temp_array1]
    temp_array2 = nil
    _g = []
    _g ++ [3]
    _g ++ [4]
    _g ++ [5]
    temp_array2 = _g
    _g ++ [temp_array2]
    temp_array3 = nil
    _g = []
    _g ++ [6]
    _g ++ [7]
    _g ++ [8]
    temp_array3 = _g
    _g ++ [temp_array3]
    temp_array = _g
    Log.trace("Grid: " <> Std.string(temp_array), %{fileName => "Main.hx", lineNumber => 117, className => "Main", methodName => "multiDimensional"})
  end

  @doc "Function process_array"
  @spec process_array(Array.t()) :: Array.t()
  def process_array(arr) do
    temp_result = nil
    temp_array = nil
    _g = []
    _g = 0
    Enum.map(arr, fn item -> v = Enum.at(arr, _g)
    _g = _g + 1
    _g ++ [v * v] end)
    temp_array = _g
    _g = []
    _g = 0
    Enum.filter(temp_array, fn item -> (v > 10) end)
    temp_result = _g
    temp_result
  end

  @doc "Function first_n"
  @spec first_n(Array.t(), integer()) :: Array.t()
  def first_n(arr, n) do
    _g = []
    _g = 0
    _g = Std.int(Math.min(n, length(arr)))
    (
      try do
        loop_fn = fn ->
          if (_g < _g) do
            try do
              i = _g = _g + 1
    _g ++ [Enum.at(arr, i)]
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    _g
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("=== Basic Array Operations ===", %{fileName => "Main.hx", lineNumber => 131, className => "Main", methodName => "main"})
    Main.basicArrayOps()
    Log.trace("\n=== Array Iteration ===", %{fileName => "Main.hx", lineNumber => 134, className => "Main", methodName => "main"})
    Main.arrayIteration()
    Log.trace("\n=== Array Methods ===", %{fileName => "Main.hx", lineNumber => 137, className => "Main", methodName => "main"})
    Main.arrayMethods()
    Log.trace("\n=== Array Comprehensions ===", %{fileName => "Main.hx", lineNumber => 140, className => "Main", methodName => "main"})
    Main.arrayComprehensions()
    Log.trace("\n=== Multi-dimensional Arrays ===", %{fileName => "Main.hx", lineNumber => 143, className => "Main", methodName => "main"})
    Main.multiDimensional()
    Log.trace("\n=== Array Functions ===", %{fileName => "Main.hx", lineNumber => 146, className => "Main", methodName => "main"})
    result = Main.processArray([1, 2, 3, 4, 5])
    Log.trace("Processed: " <> Std.string(result), %{fileName => "Main.hx", lineNumber => 148, className => "Main", methodName => "main"})
    first3 = Main.firstN(["a", "b", "c", "d", "e"], 3)
    Log.trace("First 3: " <> Std.string(first3), %{fileName => "Main.hx", lineNumber => 151, className => "Main", methodName => "main"})
  end

end
