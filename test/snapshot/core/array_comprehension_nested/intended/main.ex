defmodule Main do
  def simple_nested() do
    _ = Log.trace("Simple nested grid: #{(fn -> inspect(grid) end).()}", %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "simpleNested"})
    g = []
    _ = g ++ [(fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  _ = g ++ [2]
  []
end).()]
    _ = g ++ [(fn ->
  _ = g ++ [3]
  _ = g ++ [4]
  _ = g ++ [5]
  []
end).()]
    _ = g ++ [(fn ->
  _ = g ++ [6]
  _ = g ++ [7]
  _ = g ++ [8]
  []
end).()]
    g
  end
  def constant_range_unrolled() do
    _ = Log.trace("Constant range unrolled: #{(fn -> inspect(unrolled) end).()}", %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "constantRangeUnrolled"})
    g = []
    _ = g ++ [(fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  []
end).()]
    _ = g ++ [(fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  []
end).()]
    g
  end
  def nested_with_condition() do
    _ = Log.trace("Filtered nested: #{(fn -> inspect(filtered) end).()}", %{:file_name => "Main.hx", :line_number => 36, :class_name => "Main", :method_name => "nestedWithCondition"})
    g = []
    _ = g ++ [(fn ->
  g ++ [0]
  nil
  g ++ [2]
  nil
  []
end).()]
    _ = g ++ [(fn ->
  nil
  g ++ [5]
  nil
  g ++ [7]
  []
end).()]
    _ = g ++ [(fn ->
  g ++ [8]
  nil
  g ++ [10]
  nil
  []
end).()]
    _ = g ++ [(fn ->
  nil
  g ++ [13]
  nil
  g ++ [15]
  []
end).()]
    g
  end
  def deeply_nested() do
    _ = Log.trace("3D cube: #{(fn -> inspect(cube) end).()}", %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "deeplyNested"})
    g = []
    _ = g ++ [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [2]
  _ = g ++ [3]
  []
end).()]
  []
end).()]
    _ = g ++ [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [4]
  _ = g ++ [5]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [6]
  _ = g ++ [7]
  []
end).()]
  []
end).()]
    g
  end
  def four_level_nesting() do
    _ = Log.trace("4D hypercube: #{(fn -> inspect(hypercube) end).()}", %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "fourLevelNesting"})
    g = []
    _ = g ++ [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [2]
  _ = g ++ [3]
  []
end).()]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [4]
  _ = g ++ [5]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [6]
  _ = g ++ [7]
  []
end).()]
  []
end).()]
  []
end).()]
    _ = g ++ [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [8]
  _ = g ++ [9]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [10]
  _ = g ++ [11]
  []
end).()]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [(fn ->
  _ = g ++ [12]
  _ = g ++ [13]
  []
end).()]
  _ = g ++ [(fn ->
  _ = g ++ [14]
  _ = g ++ [15]
  []
end).()]
  []
end).()]
  []
end).()]
    g
  end
  def nested_with_expression() do
    _ = Log.trace("String table: #{(fn -> inspect(table) end).()}", %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "nestedWithExpression"})
    g = []
    _ = g ++ [(fn ->
  _ = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(0)]
  _ = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(1)]
  _ = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(2)]
  []
end).()]
    _ = g ++ [(fn ->
  _ = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(0)]
  _ = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(1)]
  _ = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(2)]
  []
end).()]
    _ = g ++ [(fn ->
  _ = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(0)]
  _ = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(1)]
  _ = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(2)]
  []
end).()]
    g
  end
  def nested_with_block() do
    _ = Log.trace("Block computed: #{(fn -> inspect(computed) end).()}", %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "nestedWithBlock"})
    g = []
    _ = g ++ [(fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  _ = g ++ [2]
  []
end).()]
    _ = g ++ [(fn ->
  _ = g ++ [1]
  _ = g ++ [3]
  _ = g ++ [5]
  []
end).()]
    _ = g ++ [(fn ->
  _ = g ++ [2]
  _ = g ++ [5]
  _ = g ++ [8]
  []
end).()]
    g
  end
  def mixed_constant_variable() do
    n = 3
    _ = Log.trace("Mixed ranges: #{(fn -> inspect(mixed) end).()}", %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "mixedConstantVariable"})
    g = []
    g = 0
    _ = Enum.each(0..(_g2 - 1), (fn -> fn item ->
  i = _g1 + 1
  _g = Enum.concat(_g, [(fn -> g3 = []
item = Enum.concat(item, [i])
item = Enum.concat(item, [i + 1])
item end).()])
end end).())
    n
  end
  def nested_in_expression() do
    sum = 0
    data = _ = [(fn ->
  _ = [0]
  _ = [1]
  _ = [2]
  []
end).()]
    _ = [(fn ->
  _ = [1]
  _ = [2]
  _ = [3]
  []
end).()]
    _ = [(fn ->
  _ = [2]
  _ = [3]
  _ = [4]
  []
end).()]
    []
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, data}, (fn -> fn _, {sum, data} ->
  if (0 < length(data)) do
    row = data[0]
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, row}, (fn -> fn _, {sum, row} ->
      if (0 < length(row)) do
        val = row[0]
        sum = sum + val
        {:cont, {sum, row}}
      else
        {:halt, {sum, row}}
      end
    end end).())
    {:cont, {sum, data}}
  else
    {:halt, {sum, data}}
  end
end end).())
    _ = Log.trace("Sum of nested: #{(fn -> sum end).()}", %{:file_name => "Main.hx", :line_number => 97, :class_name => "Main", :method_name => "nestedInExpression"})
    sum
  end
  def with_meta_and_parens() do
    _ = Log.trace("Wrapped comprehension: #{(fn -> inspect(wrapped) end).()}", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "withMetaAndParens"})
    g = []
    _ = g ++ [(fn ->
  _ = g ++ [0]
  _ = g ++ [1]
  []
end).()]
    _ = g ++ [(fn ->
  _ = g ++ [2]
  _ = g ++ [3]
  []
end).()]
    g
  end
  def mixed_with_literals() do
    _ = Log.trace("Mixed with literals: #{(fn -> inspect(mixed) end).()}", %{:file_name => "Main.hx", :line_number => 115, :class_name => "Main", :method_name => "mixedWithLiterals"})
    g = []
    _ = g ++ [0]
    _ = g ++ [2]
    _ = g ++ [4]
    g = []
    _ = g ++ [100]
    _ = g ++ [101]
    _ = g ++ [102]
    [g, [10, 20, 30], g]
  end
  def comprehension_from_iterable() do
    source = [1, 2, 3]
    _ = Log.trace("From iterable: #{(fn -> inspect(from_array) end).()}", %{:file_name => "Main.hx", :line_number => 123, :class_name => "Main", :method_name => "comprehensionFromIterable"})
    g = []
    _ = Enum.map(source, (fn -> fn item ->
  x = source[_g1]
  _g1 + 1
  _g = Enum.concat(_g, [(fn -> g2 = []
g3 = 0
Enum.map(source, (fn -> fn item ->
  y = source[_g3]
  _g3 + 1
  _g2 = Enum.concat(_g2, [x * y])
end end).())
_g2 end).()])
end end).())
  end
  def empty_comprehensions() do
    _ = Log.trace("Empty comprehension: #{(fn -> inspect(empty) end).()}", %{:file_name => "Main.hx", :line_number => 130, :class_name => "Main", :method_name => "emptyComprehensions"})
    []
  end
  def single_element_nested() do
    _ = Log.trace("Single element: #{(fn -> inspect(single) end).()}", %{:file_name => "Main.hx", :line_number => 137, :class_name => "Main", :method_name => "singleElementNested"})
    g = []
    _ = g ++ [(fn ->
  _ = g ++ [0]
  []
end).()]
    g
  end
  def main() do
    _ = Log.trace("=== Testing Nested Array Comprehensions ===", %{:file_name => "Main.hx", :line_number => 142, :class_name => "Main", :method_name => "main"})
    _ = simple_nested()
    _ = constant_range_unrolled()
    _ = nested_with_condition()
    _ = deeply_nested()
    _ = four_level_nesting()
    _ = nested_with_expression()
    _ = nested_with_block()
    _ = mixed_constant_variable()
    _ = nested_in_expression()
    _ = with_meta_and_parens()
    _ = mixed_with_literals()
    _ = comprehension_from_iterable()
    _ = empty_comprehensions()
    _ = single_element_nested()
    _ = Log.trace("=== All nested comprehension tests complete ===", %{:file_name => "Main.hx", :line_number => 159, :class_name => "Main", :method_name => "main"})
  end
end
