defmodule Main do
  def simple_nested() do
    # Simple 2-level nested comprehension
    grid = for i <- 0..2, do: (for j <- 0..2, do: i * 3 + j)
    Log.trace("Simple nested grid: " <> Std.string(grid), %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "simpleNested"})
    grid
  end

  def constant_range_unrolled() do
    # This will be completely unrolled by Haxe due to constant ranges
    unrolled = for i <- 0..1, do: (for j <- 0..1, do: j)
    Log.trace("Constant range unrolled: " <> Std.string(unrolled), %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "constantRangeUnrolled"})
    unrolled
  end

  def nested_with_condition() do
    # Nested comprehension with filter condition
    filtered = for i <- 0..3 do
      for j <- 0..3, rem(i + j, 2) == 0, do: i * 4 + j
    end
    Log.trace("Filtered nested: " <> Std.string(filtered), %{:file_name => "Main.hx", :line_number => 36, :class_name => "Main", :method_name => "nestedWithCondition"})
    filtered
  end

  def deeply_nested() do
    # 3-level deep nesting
    cube = for i <- 0..1 do
      for j <- 0..1 do
        for k <- 0..1, do: i * 4 + j * 2 + k
      end
    end
    Log.trace("3D cube: " <> Std.string(cube), %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "deeplyNested"})
    cube
  end

  def four_level_nesting() do
    # 4-level deep nesting to test recursion depth
    hypercube = for i <- 0..1 do
      for j <- 0..1 do
        for k <- 0..1 do
          for l <- 0..1, do: i * 8 + j * 4 + k * 2 + l
        end
      end
    end
    Log.trace("4D hypercube: " <> Std.string(hypercube), %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "fourLevelNesting"})
    hypercube
  end

  def mixed_nesting() do
    # Mix of different nesting patterns
    mixed = for i <- 0..2 do
      if rem(i, 2) == 0 do
        for j <- 0..2, do: i + j
      else
        for j <- 0..1, do: i * j
      end
    end
    Log.trace("Mixed nesting: " <> Std.string(mixed), %{:file_name => "Main.hx", :line_number => 65, :class_name => "Main", :method_name => "mixedNesting"})
    mixed
  end

  def main() do
    simple_nested()
    constant_range_unrolled()
    nested_with_condition()
    deeply_nested()
    four_level_nesting()
    mixed_nesting()
    Log.trace("All nested comprehension tests completed", %{:file_name => "Main.hx", :line_number => 88, :class_name => "Main", :method_name => "main"})
  end
end