defmodule Main do
  def simple_nested() do
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
    Log.trace("Simple nested grid: " <> Std.string(grid), %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "simpleNested"})
    grid
  end
  def constant_range_unrolled() do
    unrolled = [(fn -> g = []
g = g ++ [0]
g = g ++ [1]
g end).(), (fn -> g = []
g = g ++ [0]
g = g ++ [1]
g end).()]
    Log.trace("Constant range unrolled: " <> Std.string(unrolled), %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "constantRangeUnrolled"})
    unrolled
  end
  def nested_with_condition() do
    filtered = [(fn -> g = []
if (rem(0, 2) == 0) do
  g = g ++ [0]
end
if (rem(1, 2) == 0) do
  g = g ++ [1]
end
if (rem(2, 2) == 0) do
  g = g ++ [2]
end
if (rem(3, 2) == 0) do
  g = g ++ [3]
end
g end).(), (fn -> g = []
if (rem(1, 2) == 0) do
  g = g ++ [4]
end
if (rem(2, 2) == 0) do
  g = g ++ [5]
end
if (rem(3, 2) == 0) do
  g = g ++ [6]
end
if (rem(4, 2) == 0) do
  g = g ++ [7]
end
g end).(), (fn -> g = []
if (rem(2, 2) == 0) do
  g = g ++ [8]
end
if (rem(3, 2) == 0) do
  g = g ++ [9]
end
if (rem(4, 2) == 0) do
  g = g ++ [10]
end
if (rem(5, 2) == 0) do
  g = g ++ [11]
end
g end).(), (fn -> g = []
if (rem(3, 2) == 0) do
  g = g ++ [12]
end
if (rem(4, 2) == 0) do
  g = g ++ [13]
end
if (rem(5, 2) == 0) do
  g = g ++ [14]
end
if (rem(6, 2) == 0) do
  g = g ++ [15]
end
g end).()]
    Log.trace("Filtered nested: " <> Std.string(filtered), %{:file_name => "Main.hx", :line_number => 36, :class_name => "Main", :method_name => "nestedWithCondition"})
    filtered
  end
  def deeply_nested() do
    cube = [(fn -> g = []
g = g ++ [(fn -> g = []
g = g ++ [0]
g = g ++ [1]
g end).()]
g = g ++ [(fn -> g = []
g = g ++ [2]
g = g ++ [3]
g end).()]
g end).(), (fn -> g = []
g = g ++ [(fn -> g = []
g = g ++ [4]
g = g ++ [5]
g end).()]
g = g ++ [(fn -> g = []
g = g ++ [6]
g = g ++ [7]
g end).()]
g end).()]
    Log.trace("3D cube: " <> Std.string(cube), %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "deeplyNested"})
    cube
  end
  def four_level_nesting() do
    hypercube = [(fn -> g = []
g = g ++ [(fn -> g = []
g = g ++ [(fn -> g = []
g = g ++ [0]
g = g ++ [1]
g end).()]
g = g ++ [(fn -> g = []
g = g ++ [2]
g = g ++ [3]
g end).()]
g end).()]
g = g ++ [(fn -> g = []
g = g ++ [(fn -> g = []
g = g ++ [4]
g = g ++ [5]
g end).()]
g = g ++ [(fn -> g = []
g = g ++ [6]
g = g ++ [7]
g end).()]
g end).()]
g end).(), (fn -> g = []
g = g ++ [(fn -> g = []
g = g ++ [(fn -> g = []
g = g ++ [8]
g = g ++ [9]
g end).()]
g = g ++ [(fn -> g = []
g = g ++ [10]
g = g ++ [11]
g end).()]
g end).()]
g = g ++ [(fn -> g = []
g = g ++ [(fn -> g = []
g = g ++ [12]
g = g ++ [13]
g end).()]
g = g ++ [(fn -> g = []
g = g ++ [14]
g = g ++ [15]
g end).()]
g end).()]
g end).()]
    Log.trace("4D hypercube: " <> Std.string(hypercube), %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "fourLevelNesting"})
    hypercube
  end
  def nested_with_expression() do
    table = [(fn -> g = []
g = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(0)]
g = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(1)]
g = g ++ ["R" <> Kernel.to_string(0) <> "C" <> Kernel.to_string(2)]
g end).(), (fn -> g = []
g = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(0)]
g = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(1)]
g = g ++ ["R" <> Kernel.to_string(1) <> "C" <> Kernel.to_string(2)]
g end).(), (fn -> g = []
g = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(0)]
g = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(1)]
g = g ++ ["R" <> Kernel.to_string(2) <> "C" <> Kernel.to_string(2)]
g end).()]
    Log.trace("String table: " <> Std.string(table), %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "nestedWithExpression"})
    table
  end
  def nested_with_block() do
    computed = [(fn -> g = []
g = g ++ [(0)]
g = g ++ [(0) + 1]
g = g ++ [(0) + 2]
g end).(), (fn -> g = []
g = g ++ [(0) + 1]
g = g ++ [(1) + 2]
g = g ++ [(2) + 3]
g end).(), (fn -> g = []
g = g ++ [(0) + 2]
g = g ++ [(2) + 3]
g = g ++ [(4) + 4]
g end).()]
    Log.trace("Block computed: " <> Std.string(computed), %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "nestedWithBlock"})
    computed
  end
  def mixed_constant_variable() do
    n = 3
    g = []
    g1 = 0
    g2 = n
    mixed = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g2, :ok}, fn _, {acc_g1, acc_g2, acc_state} ->
  i = acc_g1 = acc_g1 + 1
  if (acc_g1 < acc_g2) do
    g = g ++ [(fn -> g = []
g = g ++ [i]
g = g ++ [i + 1]
g end).()]
    {:cont, {acc_g1, acc_g2, acc_state}}
  else
    {:halt, {acc_g1, acc_g2, acc_state}}
  end
end)
g
    Log.trace("Mixed ranges: " <> Std.string(mixed), %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "mixedConstantVariable"})
    mixed
  end
  def nested_in_expression() do
    sum = 0
    data = [(fn -> g = []
g = g ++ [0]
g = g ++ [1]
g = g ++ [2]
g end).(), (fn -> g = []
g = g ++ [1]
g = g ++ [2]
g = g ++ [3]
g end).(), (fn -> g = []
g = g ++ [2]
g = g ++ [3]
g = g ++ [4]
g end).()]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, data, g, g, :ok}, fn _, {acc_sum, acc_data, acc_g, acc_g, acc_state} -> nil end)
    Log.trace("Sum of nested: " <> Kernel.to_string(sum), %{:file_name => "Main.hx", :line_number => 97, :class_name => "Main", :method_name => "nestedInExpression"})
    sum
  end
  def with_meta_and_parens() do
    wrapped = [(fn -> g = []
g = g ++ [0]
g = g ++ [1]
g end).(), (fn -> g = []
g = g ++ [2]
g = g ++ [3]
g end).()]
    Log.trace("Wrapped comprehension: " <> Std.string(wrapped), %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "withMetaAndParens"})
    wrapped
  end
  def mixed_with_literals() do
    mixed = [(fn ->
  g = []
  g = g ++ [0]
  g = g ++ [2]
  g = g ++ [4]
  g
end).(), [10, 20, 30], (fn ->
  g = []
  g = g ++ [100]
  g = g ++ [101]
  g = g ++ [102]
  g
end).()]
    Log.trace("Mixed with literals: " <> Std.string(mixed), %{:file_name => "Main.hx", :line_number => 115, :class_name => "Main", :method_name => "mixedWithLiterals"})
    mixed
  end
  def comprehension_from_iterable() do
    source = [1, 2, 3]
    g = []
    g1 = 0
    from_array = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {source, g1, g1, :ok}, fn _, {acc_source, acc_g1, acc_g1, acc_state} ->
  x = source[g1]
  if (acc_g1 < length(acc_source)) do
    acc_g1 = acc_g1 + 1
    g = g ++ [(fn -> g = []
acc_g1 = 0
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {acc_source, acc_g1, :ok}, fn _, {acc_source, acc_g1, acc_state} ->
  if (acc_g1 < length(acc_source)) do
    y = source[g1]
    acc_g1 = acc_g1 + 1
    g = g ++ [x * y]
    {:cont, {acc_source, acc_g1, acc_state}}
  else
    {:halt, {acc_source, acc_g1, acc_state}}
  end
end)
g end).()]
    {:cont, {acc_source, acc_g1, acc_g1, acc_state}}
  else
    {:halt, {acc_source, acc_g1, acc_g1, acc_state}}
  end
end)
g
    Log.trace("From iterable: " <> Std.string(from_array), %{:file_name => "Main.hx", :line_number => 123, :class_name => "Main", :method_name => "comprehensionFromIterable"})
    from_array
  end
  def empty_comprehensions() do
    empty = ([])
    Log.trace("Empty comprehension: " <> Std.string(empty), %{:file_name => "Main.hx", :line_number => 130, :class_name => "Main", :method_name => "emptyComprehensions"})
    empty
  end
  def single_element_nested() do
    single = [(fn -> g = []
g = g ++ [0]
g end).()]
    Log.trace("Single element: " <> Std.string(single), %{:file_name => "Main.hx", :line_number => 137, :class_name => "Main", :method_name => "singleElementNested"})
    single
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