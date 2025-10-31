defmodule Main do
  def simple_nested() do
    Log.trace("Simple nested grid: #{(fn -> inspect(grid) end).()}", %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "simpleNested"})
    g = []
    g = g ++ [(fn ->
  Enum.reduce(0..2, [], fn k, acc ->
    acc = Enum.concat(acc, [])
    acc
  end)
end).()]
    g = g ++ [(fn ->
  g = []
  g = g ++ [3]
  g = g ++ [4]
  g ++ [5]
end).()]
    g ++ [(fn ->
  g = []
  g = g ++ [6]
  g = g ++ [7]
  g ++ [8]
end).()]
  end
  def constant_range_unrolled() do
    Log.trace("Constant range unrolled: #{(fn -> inspect(unrolled) end).()}", %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "constantRangeUnrolled"})
    g = []
    g = g ++ [(fn ->
  Enum.reduce(0..1, [], fn k, acc ->
    acc = Enum.concat(acc, [])
    acc
  end)
end).()]
    g ++ [(fn ->
  Enum.reduce(0..1, [], fn k, acc ->
    acc = Enum.concat(acc, [])
    acc
  end)
end).()]
  end
  def nested_with_condition() do
    Log.trace("Filtered nested: #{(fn -> inspect(filtered) end).()}", %{:file_name => "Main.hx", :line_number => 36, :class_name => "Main", :method_name => "nestedWithCondition"})
    g = []
    g = g ++ [(fn ->
  g ++ [0]
  nil
  g ++ [2]
  nil
  []
end).()]
    g = g ++ [(fn ->
  nil
  g ++ [5]
  nil
  g ++ [7]
  []
end).()]
    g = g ++ [(fn ->
  g ++ [8]
  nil
  g ++ [10]
  nil
  []
end).()]
    g ++ [(fn ->
  nil
  g ++ [13]
  nil
  g ++ [15]
  []
end).()]
  end
  def deeply_nested() do
    Log.trace("3D cube: #{(fn -> inspect(cube) end).()}", %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "deeplyNested"})
    g = []
    g = g ++ [(fn ->
  g = []
  g = g ++ [(fn ->
  Enum.reduce(0..1, [], fn k, acc ->
    acc = Enum.concat(acc, [])
    acc
  end)
end).()]
  g ++ [(fn ->
  g ++ [2]
  g ++ [3]
  []
end).()]
end).()]
    g ++ [(fn ->
  g = []
  g = g ++ [(fn ->
  g ++ [4]
  g ++ [5]
  []
end).()]
  g ++ [(fn ->
  g ++ [6]
  g ++ [7]
  []
end).()]
end).()]
  end
  def four_level_nesting() do
    Log.trace("4D hypercube: #{(fn -> inspect(hypercube) end).()}", %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "fourLevelNesting"})
    g = []
    g = g ++ [(fn ->
  g = []
  g = g ++ [(fn ->
  g ++ [(fn ->
  Enum.reduce(0..1, [], fn k, acc ->
    acc = Enum.concat(acc, [])
    acc
  end)
end).()]
  g ++ [(fn ->
  g ++ [2]
  g ++ [3]
  []
end).()]
  []
end).()]
  g ++ [(fn ->
  g ++ [(fn ->
  g ++ [4]
  g ++ [5]
  []
end).()]
  g ++ [(fn ->
  g ++ [6]
  g ++ [7]
  []
end).()]
  []
end).()]
end).()]
    g ++ [(fn ->
  g = []
  g = g ++ [(fn ->
  g ++ [(fn ->
  g ++ [8]
  g ++ [9]
  []
end).()]
  g ++ [(fn ->
  g ++ [10]
  g ++ [11]
  []
end).()]
  []
end).()]
  g ++ [(fn ->
  g ++ [(fn ->
  g ++ [12]
  g ++ [13]
  []
end).()]
  g ++ [(fn ->
  g ++ [14]
  g ++ [15]
  []
end).()]
  []
end).()]
end).()]
  end
  def nested_with_expression() do
    Log.trace("String table: #{(fn -> inspect(table) end).()}", %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "nestedWithExpression"})
    g = []
    g = g ++ [(fn ->
  g = []
  g = g ++ ["R" <> 0.to_string() <> "C" <> 0.to_string()]
  g = g ++ ["R" <> 0.to_string() <> "C" <> 1.to_string()]
  g ++ ["R" <> 0.to_string() <> "C" <> 2.to_string()]
end).()]
    g = g ++ [(fn ->
  g = []
  g = g ++ ["R" <> 1.to_string() <> "C" <> 0.to_string()]
  g = g ++ ["R" <> 1.to_string() <> "C" <> 1.to_string()]
  g ++ ["R" <> 1.to_string() <> "C" <> 2.to_string()]
end).()]
    g ++ [(fn ->
  g = []
  g = g ++ ["R" <> 2.to_string() <> "C" <> 0.to_string()]
  g = g ++ ["R" <> 2.to_string() <> "C" <> 1.to_string()]
  g ++ ["R" <> 2.to_string() <> "C" <> 2.to_string()]
end).()]
  end
  def nested_with_block() do
    Log.trace("Block computed: #{(fn -> inspect(computed) end).()}", %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "nestedWithBlock"})
    g = []
    g = g ++ [(fn ->
  Enum.reduce(0..2, [], fn k, acc ->
    acc = Enum.concat(acc, [])
    acc
  end)
end).()]
    g = g ++ [(fn ->
  g = []
  g = g ++ [1]
  g = g ++ [3]
  g ++ [5]
end).()]
    g ++ [(fn ->
  g = []
  g = g ++ [2]
  g = g ++ [5]
  g ++ [8]
end).()]
  end
  def mixed_constant_variable() do
    n = 3
    Log.trace("Mixed ranges: #{(fn -> inspect(mixed) end).()}", %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "mixedConstantVariable"})
    Enum.reduce(0..(_g2 - 1), [], fn _g1, acc ->
      acc = (
Enum.concat(acc, [(fn -> g3 = []
_g3 = Enum.concat(_g3, [i])
_g3 = Enum.concat(_g3, [i + 0])
_g3 end).()])
)
      acc
    end)
    _ = 0
    _ = n
  end
  def nested_in_expression() do
    sum = 0
    data = [] ++ [(fn ->
  Enum.each(0..2, fn _ -> push(0) end)
  []
end).()]
    [] ++ [(fn ->
  [] ++ [1]
  [] ++ [2]
  [] ++ [3]
  []
end).()]
    [] ++ [(fn ->
  [] ++ [2]
  [] ++ [3]
  [] ++ [4]
  []
end).()]
    []
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, data}, fn _, {sum, data} ->
      if (0 < length(data)) do
        row = data[0]
        Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, row}, fn _, {sum, row} ->
          if (0 < length(row)) do
            val = row[0]
            sum = sum + val
            {:cont, {sum, row}}
          else
            {:halt, {sum, row}}
          end
        end)
        {:cont, {sum, data}}
      else
        {:halt, {sum, data}}
      end
    end)
    Log.trace("Sum of nested: #{(fn -> sum end).()}", %{:file_name => "Main.hx", :line_number => 97, :class_name => "Main", :method_name => "nestedInExpression"})
    sum
  end
  def with_meta_and_parens() do
    Log.trace("Wrapped comprehension: #{(fn -> inspect(wrapped) end).()}", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "withMetaAndParens"})
    g = []
    g = g ++ [(fn ->
  Enum.reduce(0..1, [], fn k, acc ->
    acc = Enum.concat(acc, [])
    acc
  end)
end).()]
    g ++ [(fn ->
  g = []
  g = g ++ [2]
  g ++ [3]
end).()]
  end
  def mixed_with_literals() do
    Log.trace("Mixed with literals: #{(fn -> inspect(mixed) end).()}", %{:file_name => "Main.hx", :line_number => 115, :class_name => "Main", :method_name => "mixedWithLiterals"})
    g = []
    g = g ++ [0]
    g = g ++ [2]
    g = g ++ [4]
    g = []
    g = g ++ [100]
    g = g ++ [101]
    g = g ++ [102]
    [g, [10, 20, 30], g]
  end
  def comprehension_from_iterable() do
    source = [1, 2, 3]
    Log.trace("From iterable: #{(fn -> inspect(from_array) end).()}", %{:file_name => "Main.hx", :line_number => 123, :class_name => "Main", :method_name => "comprehensionFromIterable"})
    _g = []
    _g1 = 0
    Enum.map(source, fn item ->
      x = source[_g1]
      _g1 + 1
      _g = Enum.concat(_g, [(fn -> g2 = []
g3 = 0
Enum.map(source, fn item ->
  y = source[_g3]
  _g3 + 1
  _g2 = Enum.concat(_g2, [x * y])
end)
_g2 end).()])
    end)
    _g
  end
  def empty_comprehensions() do
    Log.trace("Empty comprehension: #{(fn -> inspect(empty) end).()}", %{:file_name => "Main.hx", :line_number => 130, :class_name => "Main", :method_name => "emptyComprehensions"})
    _g = []
    _g
  end
  def single_element_nested() do
    Log.trace("Single element: #{(fn -> inspect(single) end).()}", %{:file_name => "Main.hx", :line_number => 137, :class_name => "Main", :method_name => "singleElementNested"})
    g = []
    g ++ [(fn ->
  g = []
  g ++ [0]
end).()]
  end
  def main() do
    Log.trace("=== Testing Nested Array Comprehensions ===", %{:file_name => "Main.hx", :line_number => 142, :class_name => "Main", :method_name => "main"})
    simple_nested()
    constant_range_unrolled()
    nested_with_condition()
    deeply_nested()
    four_level_nesting()
    nested_with_expression()
    nested_with_block()
    mixed_constant_variable()
    nested_in_expression()
    with_meta_and_parens()
    mixed_with_literals()
    comprehension_from_iterable()
    empty_comprehensions()
    single_element_nested()
    Log.trace("=== All nested comprehension tests complete ===", %{:file_name => "Main.hx", :line_number => 159, :class_name => "Main", :method_name => "main"})
  end
end
