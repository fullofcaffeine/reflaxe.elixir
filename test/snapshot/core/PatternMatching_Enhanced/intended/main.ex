defmodule Main do
  def main() do
    test_simple_enum_pattern()
    test_complex_enum_pattern()
    test_result_pattern()
    test_guard_patterns()
    test_array_patterns()
    test_object_patterns()
    Log.trace("Pattern matching tests complete", %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "main"})
  end
  defp test_simple_enum_pattern() do
    color = {:red}
    result = case color do
      {:red} -> "red"
      {:green} -> "green"
      {:blue} -> "blue"
      {:rgb, _r, _g, _b} -> "custom"
    end
    Log.trace("Simple enum result: #{result}", %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "testSimpleEnumPattern"})
  end
  defp test_complex_enum_pattern() do
    color = {:rgb, 255, 128, 0}
    brightness = case color do
      {:red} -> "primary"
      {:green} -> "primary"
      {:blue} -> "primary"
      {:rgb, r, g, b} ->
        cond do
          r + g + b > 500 -> "bright"
          r + g + b < 100 -> "dark"
          true -> "medium"
        end
    end
    Log.trace("Complex enum result: #{brightness}", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "testComplexEnumPattern"})
  end
  defp test_result_pattern() do
    result = {:ok, "success"}
    message = case result do
      {:ok, value} -> "Got value: #{value}"
      {:error, error} -> "Got error: #{error}"
    end
    Log.trace("Result pattern: #{message}", %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "testResultPattern"})
  end
  defp test_guard_patterns() do
    numbers = [1, 5, 10, 15, 20]
    Enum.each(numbers, fn num ->
      category = cond do
        num < 5 -> "small"
        num >= 5 and num < 15 -> "medium"
        num >= 15 -> "large"
        true -> "unknown"
      end
      Log.trace("Number #{num} is #{category}", %{:file_name => "Main.hx", :line_number => 98, :class_name => "Main", :method_name => "testGuardPatterns"})
    end)
  end
  defp test_array_patterns() do
    arrays = [[], [1], [1, 2], [1, 2, 3], [1, 2, 3, 4, 5]]
    Enum.each(arrays, fn arr ->
      description = case arr do
        [] -> "empty"
        [x] -> "single: #{x}"
        [x, y] -> "pair: #{x}, #{y}"
        [x, y, z] -> "triple: #{x}, #{y}, #{z}"
        _ -> "length=#{length(arr)}, first=#{if length(arr) > 0, do: Enum.at(arr, 0), else: "none"}"
      end
      Log.trace("Array pattern: #{description}", %{:file_name => "Main.hx", :line_number => 119, :class_name => "Main", :method_name => "testArrayPatterns"})
    end)
  end
  defp test_object_patterns() do
    point_x = 10
    point_y = 20
    x = point_x
    y = point_y
    quadrant = cond do
      x > 0 and y > 0 -> "first"
      x < 0 and y > 0 -> "second"
      x < 0 and y < 0 -> "third"
      x > 0 and y < 0 -> "fourth"
      x == 0 or y == 0 -> "axis"
      true -> "origin"
    end
    Log.trace("Point #{point_x},#{point_y} is in #{quadrant} quadrant", %{:file_name => "Main.hx", :line_number => 135, :class_name => "Main", :method_name => "testObjectPatterns"})
  end
end