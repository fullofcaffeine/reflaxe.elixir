defmodule Main do
  def main() do
    test_simple_enum_pattern()
    test_complex_enum_pattern()
    test_result_pattern()
    test_guard_patterns()
    test_array_patterns()
    test_object_patterns()
    Log.trace("Pattern matching tests complete", %{:fileName => "Main.hx", :lineNumber => 41, :className => "Main", :methodName => "main"})
  end
  defp test_simple_enum_pattern() do
    color = :red
    result = case (color.elem(0)) do
  0 ->
    "red"
  1 ->
    "green"
  2 ->
    "blue"
  3 ->
    _g = color.elem(1)
    _g = color.elem(2)
    _g = color.elem(3)
    "custom"
end
    Log.trace("Simple enum result: " <> result, %{:fileName => "Main.hx", :lineNumber => 54, :className => "Main", :methodName => "testSimpleEnumPattern"})
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
        _r = g
        _g = g1
        _b = g2
        "medium"
      end
    end
end
    Log.trace("Complex enum result: " <> brightness, %{:fileName => "Main.hx", :lineNumber => 72, :className => "Main", :methodName => "testComplexEnumPattern"})
  end
  defp test_result_pattern() do
    result = {:Ok, "success"}
    message = case (result.elem(0)) do
  0 ->
    g = result.elem(1)
    value = g
    "Got value: " <> value
  1 ->
    g = result.elem(1)
    error = g
    "Got error: " <> error
end
    Log.trace("Result pattern: " <> message, %{:fileName => "Main.hx", :lineNumber => 85, :className => "Main", :methodName => "testResultPattern"})
  end
  defp test_guard_patterns() do
    numbers = [1, 5, 10, 15, 20]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, g, :ok}, fn _, {acc_numbers, acc_g, acc_state} ->
  if (acc_g < acc_numbers.length) do
    num = numbers[g]
    acc_g = acc_g + 1
    n = num
    n = num
    n = num
    category = if n < 5 do
  "small"
else
  if n >= 5 && n < 15 do
    "medium"
  else
    if n >= 15, do: "large", else: "unknown"
  end
end
    Log.trace("Number " <> num <> " is " <> category, %{:fileName => "Main.hx", :lineNumber => 98, :className => "Main", :methodName => "testGuardPatterns"})
    {:cont, {acc_numbers, acc_g, acc_state}}
  else
    {:halt, {acc_numbers, acc_g, acc_state}}
  end
end)
  end
  defp test_array_patterns() do
    arrays = [[], [1], [1, 2], [1, 2, 3], [1, 2, 3, 4, 5]]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {arrays, g, :ok}, fn _, {acc_arrays, acc_g, acc_state} ->
  if (acc_g < acc_arrays.length) do
    arr = arrays[g]
    acc_g = acc_g + 1
    description = case (arr.length) do
  0 ->
    "empty"
  1 ->
    acc_g = arr[0]
    x = acc_g
    "single: " <> x
  2 ->
    acc_g = arr[0]
    g1 = arr[1]
    x = acc_g
    y = g1
    "pair: " <> x <> ", " <> y
  3 ->
    acc_g = arr[0]
    g1 = arr[1]
    g2 = arr[2]
    x = acc_g
    y = g1
    z = g2
    "triple: " <> x <> ", " <> y <> ", " <> z
  _ ->
    "length=" <> arr.length <> ", first=" <> (if (arr.length > 0) do
  Std.string(arr[0])
else
  "none"
end)
end
    Log.trace("Array pattern: " <> description, %{:fileName => "Main.hx", :lineNumber => 119, :className => "Main", :methodName => "testArrayPatterns"})
    {:cont, {acc_arrays, acc_g, acc_state}}
  else
    {:halt, {acc_arrays, acc_g, acc_state}}
  end
end)
  end
  defp test_object_patterns() do
    point_y = nil
    point_x = 10
    point_y = 20
    g = point_x
    g1 = point_y
    x = g
    y = g1
    x = g
    y = g1
    x = g
    y = g1
    x = g
    y = g1
    quadrant = if x > 0 && y > 0 do
  "first"
else
  if x < 0 && y > 0 do
    "second"
  else
    if x < 0 && y < 0 do
      "third"
    else
      if x > 0 && y < 0 do
        "fourth"
      else
        if g == 0 do
          "axis"
        else
          if g1 == 0, do: "axis", else: "origin"
        end
      end
    end
  end
end
    Log.trace("Point " <> point_x <> "," <> point_y <> " is in " <> quadrant <> " quadrant", %{:fileName => "Main.hx", :lineNumber => 135, :className => "Main", :methodName => "testObjectPatterns"})
  end
end