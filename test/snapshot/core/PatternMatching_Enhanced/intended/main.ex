defmodule Main do
  def main() do
    Main.test_simple_enum_pattern()
    Main.test_complex_enum_pattern()
    Main.test_result_pattern()
    Main.test_guard_patterns()
    Main.test_array_patterns()
    Main.test_object_patterns()
    Log.trace("Pattern matching tests complete", %{:fileName => "Main.hx", :lineNumber => 41, :className => "Main", :methodName => "main"})
  end
  defp test_simple_enum_pattern() do
    color = :Red
    result = case (color.elem(0)) do
  0 ->
    "red"
  1 ->
    "green"
  2 ->
    "blue"
  3 ->
    g = color.elem(1)
    g = color.elem(2)
    g = color.elem(3)
    "custom"
end
    Log.trace("Simple enum result: " + result, %{:fileName => "Main.hx", :lineNumber => 54, :className => "Main", :methodName => "testSimpleEnumPattern"})
  end
  defp test_complex_enum_pattern() do
    color = {:RGB, 255, 128, 0}
    brightness = case (color.elem(0)) do
  0 ->
    "primary"
  1 ->
    "primary"
  2 ->
    "primary"
  3 ->
    g = color.elem(1)
    g1 = color.elem(2)
    g2 = color.elem(3)
    r = g
    g = g1
    b = g2
    if (r + g + b > 500) do
      "bright"
    else
      r = g
      g = g1
      b = g2
      if (r + g + b < 100) do
        "dark"
      else
        r = g
        g = g1
        b = g2
        "medium"
      end
    end
end
    Log.trace("Complex enum result: " + brightness, %{:fileName => "Main.hx", :lineNumber => 72, :className => "Main", :methodName => "testComplexEnumPattern"})
  end
  defp test_result_pattern() do
    result = {:Ok, "success"}
    message = case (result.elem(0)) do
  0 ->
    g = result.elem(1)
    value = g
    "Got value: " + value
  1 ->
    g = result.elem(1)
    error = g
    "Got error: " + error
end
    Log.trace("Result pattern: " + message, %{:fileName => "Main.hx", :lineNumber => 85, :className => "Main", :methodName => "testResultPattern"})
  end
  defp test_guard_patterns() do
    numbers = [1, 5, 10, 15, 20]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < numbers.length) do
  num = numbers[g]
  g + 1
  category = n = num
if (n < 5) do
  "small"
else
  n = num
  if (n >= 5 && n < 15) do
    "medium"
  else
    n = num
    if (n >= 15), do: "large", else: "unknown"
  end
end
  Log.trace("Number " + num + " is " + category, %{:fileName => "Main.hx", :lineNumber => 98, :className => "Main", :methodName => "testGuardPatterns"})
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  defp test_array_patterns() do
    arrays = [[], [1], [1, 2], [1, 2, 3], [1, 2, 3, 4, 5]]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < arrays.length) do
  arr = arrays[g]
  g + 1
  description = case (arr.length) do
  0 ->
    "empty"
  1 ->
    g = arr[0]
    x = g
    "single: " + x
  2 ->
    g = arr[0]
    g1 = arr[1]
    x = g
    y = g1
    "pair: " + x + ", " + y
  3 ->
    g = arr[0]
    g1 = arr[1]
    g2 = arr[2]
    x = g
    y = g1
    z = g2
    "triple: " + x + ", " + y + ", " + z
  _ ->
    "length=" + arr.length + ", first=" + (if (arr.length > 0) do
  Std.string(arr[0])
else
  "none"
end)
end
  Log.trace("Array pattern: " + description, %{:fileName => "Main.hx", :lineNumber => 119, :className => "Main", :methodName => "testArrayPatterns"})
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  defp test_object_patterns() do
    point_y = nil
    point_x = nil
    point_x = 10
    point_y = 20
    quadrant = g = point_x
g1 = point_y
x = g
y = g1
if (x > 0 && y > 0) do
  "first"
else
  x = g
  y = g1
  if (x < 0 && y > 0) do
    "second"
  else
    x = g
    y = g1
    if (x < 0 && y < 0) do
      "third"
    else
      x = g
      y = g1
      if (x > 0 && y < 0) do
        "fourth"
      else
        if (g == 0) do
          "axis"
        else
          if (g1 == 0), do: "axis", else: "origin"
        end
      end
    end
  end
end
    Log.trace("Point " + point_x + "," + point_y + " is in " + quadrant + " quadrant", %{:fileName => "Main.hx", :lineNumber => 135, :className => "Main", :methodName => "testObjectPatterns"})
  end
end