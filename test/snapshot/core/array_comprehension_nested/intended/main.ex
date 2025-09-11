defmodule Main do
  def simple_nested() do
    grid = for i <- 0..2, do: for j <- 0..2, do: i * 3 + j
    Log.trace("Simple nested grid: " <> Std.string(grid), %{:file_name => "Main.hx", :line_number => 14, :class_name => "Main", :method_name => "simpleNested"})
    grid
  end
  
  def nested_with_condition() do
    filtered = for i <- 0..3, do: for j <- 0..3, rem(i + j, 2) == 0, do: i * 4 + j
    Log.trace("Filtered nested: " <> Std.string(filtered), %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "nestedWithCondition"})
    filtered
  end
  
  def deeply_nested() do
    cube = for i <- 0..1, do: for j <- 0..1, do: for k <- 0..1, do: i * 4 + j * 2 + k
    Log.trace("3D cube: " <> Std.string(cube), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "deeplyNested"})
    cube
  end
  
  def nested_with_expression() do
    table = for row <- 0..2, do: for col <- 0..2, do: "R" <> Kernel.to_string(row) <> "C" <> Kernel.to_string(col)
    Log.trace("String table: " <> Std.string(table), %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "nestedWithExpression"})
    table
  end
  
  def mixed_constant_variable() do
    n = 3
    mixed = for i <- 0..(n - 1), do: for j <- 0..1, do: i + j
    Log.trace("Mixed ranges: " <> Std.string(mixed), %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "mixedConstantVariable"})
    mixed
  end
  
  def nested_in_expression() do
    sum = 0
    data = for i <- 0..2, do: for j <- 0..2, do: i + j
    {data, sum} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {data, sum, :ok}, fn _, {acc_data, acc_sum, acc_state} ->
      if (false) do
        {:cont, {acc_data, acc_sum, acc_state}}
      else
        {:halt, {acc_data, acc_sum, acc_state}}
      end
    end)
    {row, data, sum} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {nil, data, sum, :ok}, fn _, {acc_row, acc_data, acc_sum, acc_state} ->
      if (false) do
        {:cont, {acc_row, acc_data, acc_sum, acc_state}}
      else
        {:halt, {acc_row, acc_data, acc_sum, acc_state}}
      end
    end)
    {val, row, sum} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {nil, row, sum, :ok}, fn _, {acc_val, acc_row, acc_sum, acc_state} ->
      if (false) do
        acc_sum = acc_sum + val
        {:cont, {acc_val, acc_row, acc_sum, acc_state}}
      else
        {:halt, {acc_val, acc_row, acc_sum, acc_state}}
      end
    end)
    Log.trace("Sum of nested: " <> Kernel.to_string(sum), %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "nestedInExpression"})
    sum
  end
  
  def with_meta_and_parens() do
    wrapped = for i <- 0..1, do: for j <- 0..1, do: i * 2 + j
    Log.trace("Wrapped comprehension: " <> Std.string(wrapped), %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "withMetaAndParens"})
    wrapped
  end
  
  def main() do
    Log.trace("=== Testing Nested Array Comprehensions ===", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "main"})
    simple_nested()
    nested_with_condition()
    deeply_nested()
    nested_with_expression()
    mixed_constant_variable()
    nested_in_expression()
    with_meta_and_parens()
    Log.trace("=== All nested comprehension tests complete ===", %{:file_name => "Main.hx", :line_number => 82, :class_name => "Main", :method_name => "main"})
  end
end