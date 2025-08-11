defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Arrays test case
 * Tests array operations and list comprehensions
 
  """

  # Static functions
  @doc "Function basic_array_ops"
  @spec basic_array_ops() :: TAbstract(Void,[]).t()
  def basic_array_ops() do
    (
  numbers = [1, 2, 3, 4, 5]
  Log.trace(Enum.at(numbers, 0), %{fileName: "Main.hx", lineNumber: 12, className: "Main", methodName: "basicArrayOps"})
  Log.trace(numbers.length, %{fileName: "Main.hx", lineNumber: 13, className: "Main", methodName: "basicArrayOps"})
  numbers.push(6)
  numbers.unshift(0)
  popped = numbers.pop()
  shifted = numbers.shift()
  Log.trace("Popped: " + popped + ", Shifted: " + shifted, %{fileName: "Main.hx", lineNumber: 20, className: "Main", methodName: "basicArrayOps"})
  mixed = [1, "hello", true, 3.14]
  Log.trace(mixed, %{fileName: "Main.hx", lineNumber: 24, className: "Main", methodName: "basicArrayOps"})
)
  end

  @doc "Function array_iteration"
  @spec array_iteration() :: TAbstract(Void,[]).t()
  def array_iteration() do
    (
  fruits = ["apple", "banana", "orange", "grape"]
  (
  _g = 0
  while (_g < fruits.length) do
  (
  fruit = Enum.at(fruits, _g)
  _g + 1
  Log.trace("Fruit: " + fruit, %{fileName: "Main.hx", lineNumber: 33, className: "Main", methodName: "arrayIteration"})
)
end
)
  (
  _g = 0
  _g1 = fruits.length
  while (_g < _g1) do
  (
  i = _g + 1
  Log.trace("" + i + ": " + Enum.at(fruits, i), %{fileName: "Main.hx", lineNumber: 38, className: "Main", methodName: "arrayIteration"})
)
end
)
  i = 0
  while (i < fruits.length) do
  (
  Log.trace("While: " + Enum.at(fruits, i), %{fileName: "Main.hx", lineNumber: 44, className: "Main", methodName: "arrayIteration"})
  i + 1
)
end
)
  end

  @doc "Function array_methods"
  @spec array_methods() :: TAbstract(Void,[]).t()
  def array_methods() do
    (
  numbers = [1, 2, 3, 4, 5]
  temp_array = nil
  (
  _g = []
  (
  _g1 = 0
  _g2 = numbers
  while (_g1 < _g2.length) do
  (
  v = Enum.at(_g2, _g1)
  _g1 + 1
  _g.push(v * 2)
)
end
)
  temp_array = _g
)
  doubled = temp_array
  Log.trace("Doubled: " + Std.string(doubled), %{fileName: "Main.hx", lineNumber: 55, className: "Main", methodName: "arrayMethods"})
  temp_array1 = nil
  (
  _g = []
  (
  _g1 = 0
  _g2 = numbers
  while (_g1 < _g2.length) do
  (
  v = Enum.at(_g2, _g1)
  _g1 + 1
  if (v rem 2 == 0), do: _g.push(v), else: nil
)
end
)
  temp_array1 = _g
)
  evens = temp_array1
  Log.trace("Evens: " + Std.string(evens), %{fileName: "Main.hx", lineNumber: 59, className: "Main", methodName: "arrayMethods"})
  more = [6, 7, 8]
  combined = numbers.concat(more)
  Log.trace("Combined: " + Std.string(combined), %{fileName: "Main.hx", lineNumber: 64, className: "Main", methodName: "arrayMethods"})
  words = ["Hello", "World", "from", "Haxe"]
  sentence = words.join(" ")
  Log.trace("Sentence: " + sentence, %{fileName: "Main.hx", lineNumber: 69, className: "Main", methodName: "arrayMethods"})
  reversed = numbers.copy()
  reversed.reverse()
  Log.trace("Reversed: " + Std.string(reversed), %{fileName: "Main.hx", lineNumber: 74, className: "Main", methodName: "arrayMethods"})
  unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
  unsorted.sort(fn a, b -> a - b end)
  Log.trace("Sorted: " + Std.string(unsorted), %{fileName: "Main.hx", lineNumber: 79, className: "Main", methodName: "arrayMethods"})
)
  end

  @doc "Function array_comprehensions"
  @spec array_comprehensions() :: TAbstract(Void,[]).t()
  def array_comprehensions() do
    (
  temp_array = nil
  (
  _g = []
  (
  _g.push(1)
  _g.push(4)
  _g.push(9)
  _g.push(16)
  _g.push(25)
)
  temp_array = _g
)
  squares = temp_array
  Log.trace("Squares: " + Std.string(squares), %{fileName: "Main.hx", lineNumber: 86, className: "Main", methodName: "arrayComprehensions"})
  temp_array1 = nil
  (
  _g = []
  (
  if (1 rem 2 == 0), do: _g.push(1), else: nil
  if (2 rem 2 == 0), do: _g.push(4), else: nil
  if (3 rem 2 == 0), do: _g.push(9), else: nil
  if (4 rem 2 == 0), do: _g.push(16), else: nil
  if (5 rem 2 == 0), do: _g.push(25), else: nil
  if (6 rem 2 == 0), do: _g.push(36), else: nil
  if (7 rem 2 == 0), do: _g.push(49), else: nil
  if (8 rem 2 == 0), do: _g.push(64), else: nil
  if (9 rem 2 == 0), do: _g.push(81), else: nil
)
  temp_array1 = _g
)
  even_squares = temp_array1
  Log.trace("Even squares: " + Std.string(even_squares), %{fileName: "Main.hx", lineNumber: 90, className: "Main", methodName: "arrayComprehensions"})
  temp_array2 = nil
  (
  _g = []
  (
  (
  _g.push(%{x: 1, y: 2})
  _g.push(%{x: 1, y: 3})
)
  (
  _g.push(%{x: 2, y: 1})
  _g.push(%{x: 2, y: 3})
)
  (
  _g.push(%{x: 3, y: 1})
  _g.push(%{x: 3, y: 2})
  nil
)
)
  temp_array2 = _g
)
  pairs = temp_array2
  Log.trace("Pairs: " + Std.string(pairs), %{fileName: "Main.hx", lineNumber: 94, className: "Main", methodName: "arrayComprehensions"})
)
  end

  @doc "Function multi_dimensional"
  @spec multi_dimensional() :: TAbstract(Void,[]).t()
  def multi_dimensional() do
    (
  matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
  Log.trace("Matrix element [1][2]: " + Enum.at(Enum.at(matrix, 1), 2), %{fileName: "Main.hx", lineNumber: 106, className: "Main", methodName: "multiDimensional"})
  (
  _g = 0
  while (_g < matrix.length) do
  (
  row = Enum.at(matrix, _g)
  _g + 1
  (
  _g2 = 0
  while (_g2 < row.length) do
  (
  elem = Enum.at(row, _g2)
  _g2 + 1
  Log.trace("Element: " + elem, %{fileName: "Main.hx", lineNumber: 111, className: "Main", methodName: "multiDimensional"})
)
end
)
)
end
)
  temp_array = nil
  (
  _g = []
  (
  temp_array1 = nil
  (
  _g2 = []
  (
  _g2.push(0)
  _g2.push(1)
  _g2.push(2)
)
  temp_array1 = _g2
)
  _g.push(temp_array1)
  temp_array2 = nil
  (
  _g2 = []
  (
  _g2.push(3)
  _g2.push(4)
  _g2.push(5)
)
  temp_array2 = _g2
)
  _g.push(temp_array2)
  temp_array3 = nil
  (
  _g2 = []
  (
  _g2.push(6)
  _g2.push(7)
  _g2.push(8)
)
  temp_array3 = _g2
)
  _g.push(temp_array3)
)
  temp_array = _g
)
  grid = temp_array
  Log.trace("Grid: " + Std.string(grid), %{fileName: "Main.hx", lineNumber: 117, className: "Main", methodName: "multiDimensional"})
)
  end

  @doc "Function process_array"
  @spec process_array(TInst(Array,[TAbstract(Int,[])]).t()) :: TInst(Array,[TAbstract(Int,[])]).t()
  def process_array(arg0) do
    (
  temp_result = nil
  (
  temp_array = nil
  (
  _g = []
  (
  _g1 = 0
  _g2 = arr
  while (_g1 < _g2.length) do
  (
  v = Enum.at(_g2, _g1)
  _g1 + 1
  _g.push(v * v)
)
end
)
  temp_array = _g
)
  _this = temp_array
  (
  _g = []
  (
  _g1 = 0
  _g2 = _this
  while (_g1 < _g2.length) do
  (
  v = Enum.at(_g2, _g1)
  _g1 + 1
  if (v > 10), do: _g.push(v), else: nil
)
end
)
  temp_result = _g
)
)
  temp_result
)
  end

  @doc "Function first_n"
  @spec first_n(TInst(Array,[TInst(firstN.T,[])]).t(), TAbstract(Int,[]).t()) :: TInst(Array,[TInst(firstN.T,[])]).t()
  def first_n(arg0, arg1) do
    (
  temp_result = nil
  (
  _g = []
  (
  _g1 = 0
  _g2 = Std.int(Math.min(n, arr.length))
  while (_g1 < _g2) do
  (
  i = _g1 + 1
  _g.push(Enum.at(arr, i))
)
end
)
  temp_result = _g
)
  temp_result
)
  end

  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    (
  Log.trace("=== Basic Array Operations ===", %{fileName: "Main.hx", lineNumber: 131, className: "Main", methodName: "main"})
  Main.basic_array_ops()
  Log.trace("
=== Array Iteration ===", %{fileName: "Main.hx", lineNumber: 134, className: "Main", methodName: "main"})
  Main.array_iteration()
  Log.trace("
=== Array Methods ===", %{fileName: "Main.hx", lineNumber: 137, className: "Main", methodName: "main"})
  Main.array_methods()
  Log.trace("
=== Array Comprehensions ===", %{fileName: "Main.hx", lineNumber: 140, className: "Main", methodName: "main"})
  Main.array_comprehensions()
  Log.trace("
=== Multi-dimensional Arrays ===", %{fileName: "Main.hx", lineNumber: 143, className: "Main", methodName: "main"})
  Main.multi_dimensional()
  Log.trace("
=== Array Functions ===", %{fileName: "Main.hx", lineNumber: 146, className: "Main", methodName: "main"})
  result = Main.process_array([1, 2, 3, 4, 5])
  Log.trace("Processed: " + Std.string(result), %{fileName: "Main.hx", lineNumber: 148, className: "Main", methodName: "main"})
  first3 = Main.first_n(["a", "b", "c", "d", "e"], 3)
  Log.trace("First 3: " + Std.string(first3), %{fileName: "Main.hx", lineNumber: 151, className: "Main", methodName: "main"})
)
  end

end
