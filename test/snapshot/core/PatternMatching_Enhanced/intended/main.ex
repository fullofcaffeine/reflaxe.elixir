defmodule Main do
  def main() do
    _ = test_simple_enum_pattern()
    _ = test_complex_enum_pattern()
    _ = test_result_pattern()
    _ = test_guard_patterns()
    _ = test_array_patterns()
    _ = test_object_patterns()
    _ = Log.trace("Pattern matching tests complete", %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "main"})
    _
  end
  defp test_simple_enum_pattern() do
    _ = {:red}
    _ = ((case color do
  {:red} -> "red"
  {:green} -> "green"
  {:blue} -> "blue"
  {:rgb, r, g, b} -> "custom"
end))
    _ = Log.trace("Simple enum result: #{(fn -> result end).()}", %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "testSimpleEnumPattern"})
    _
  end
  defp test_complex_enum_pattern() do
    _ = {:rgb, 255, 128, 0}
    _ = ((case color do
  {:red} -> "primary"
  {:green} -> "primary"
  {:blue} -> "primary"
  {:rgb, r, g, b} when r + g + b > 500 -> "bright"
  {:rgb, r, g, b} when r + g + b < 100 -> "dark"
  {:rgb, r, g, b} -> "medium"
end))
    _ = Log.trace("Complex enum result: #{(fn -> brightness end).()}", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "testComplexEnumPattern"})
    _
  end
  defp test_result_pattern() do
    _ = {:ok, "success"}
    _ = ((case result do
  {:ok, value} -> "Got value: #{(fn -> value end).()}"
  {:error, error} -> "Got error: #{(fn -> error end).()}"
end))
    _ = Log.trace("Result pattern: #{(fn -> message end).()}", %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "testResultPattern"})
    _
  end
  defp test_guard_patterns() do
    _ = [1, 5, 10, 15, 20]
    _ = Enum.each(numbers, (fn -> fn item ->
    category = n = item
  if (n < 5) do
    "small"
  else
    n2 = item
    if (n2 >= 5 and n2 < 15) do
      "medium"
    else
      n3 = item
      if (n3 >= 15), do: "large", else: "unknown"
    end
  end
  Log.trace("Number " <> Kernel.to_string(num) <> " is " <> category, %{:file_name => "Main.hx", :line_number => 98, :class_name => "Main", :method_name => "testGuardPatterns"})
end end).())
    _
  end
  defp test_array_patterns() do
    _ = [[], [1], [1, 2], [1, 2, 3], [1, 2, 3, 4, 5]]
    _ = Enum.each(arrays, (fn -> fn item ->
    description = (case length(item) do
    0 -> "empty"
    1 -> "single: " <> Kernel.to_string(x)
    2 -> "pair: " <> Kernel.to_string(x) <> ", " <> Kernel.to_string(y)
    3 -> "triple: " <> Kernel.to_string(x) <> ", " <> Kernel.to_string(y) <> ", " <> Kernel.to_string(z)
    _ -> "length=" <> Kernel.to_string(length(arr)) <> ", first=" <> (if (length(item) > 0), do: inspect(arr[0]), else: "none")
  end)
  Log.trace("Array pattern: " <> description, %{:file_name => "Main.hx", :line_number => 119, :class_name => "Main", :method_name => "testArrayPatterns"})
end end).())
    _
  end
  defp test_object_patterns() do
    point_x = 10
    point_y = 20
    _ = point_x
    _ = point_y
    if (point_x > 0 and point_y > 0) do
      "first"
    else
      if (x2 < 0 and y2 > 0) do
        "second"
      else
        if (x3 < 0 and y3 < 0) do
          "third"
        else
          cond do
            x4 > 0 and y4 < 0 -> "fourth"
            _g == 0 -> "axis"
            _g1 == 0 -> "axis"
            :true -> "origin"
          end
        end
      end
    end
    _ = Log.trace("Point #{(fn -> point_x end).()},#{(fn -> point_y end).()} is in #{(fn -> quadrant end).()} quadrant", %{:file_name => "Main.hx", :line_number => 135, :class_name => "Main", :method_name => "testObjectPatterns"})
    _
  end
end
