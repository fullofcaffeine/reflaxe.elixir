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
    result = case (color) do
  {:red} ->
    "red"
  {:green} ->
    "green"
  {:blue} ->
    "blue"
  {:rgb, r, g, b} ->
    _g = elem(color, 1)
    _g = elem(color, 2)
    _g = elem(color, 3)
    "custom"
end
    Log.trace("Simple enum result: " <> result, %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "testSimpleEnumPattern"})
  end
  defp test_complex_enum_pattern() do
    color = {:rgb, 255, 128, 0}
    brightness = case (color) do
  {:red} ->
    "primary"
  {:green} ->
    "primary"
  {:blue} ->
    "primary"
  {:rgb, r, g, b} ->
    g = elem(color, 1)
    g1 = elem(color, 2)
    g2 = elem(color, 3)
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
    Log.trace("Complex enum result: " <> brightness, %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "testComplexEnumPattern"})
  end
  defp test_result_pattern() do
    result = {:ok, "success"}
    message = case (result) do
  {:ok, value} ->
    g = elem(result, 1)
    value = g
    "Got value: " <> value
  {:error, error} ->
    g = elem(result, 1)
    error = g
    "Got error: " <> error
end
    Log.trace("Result pattern: " <> message, %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "testResultPattern"})
  end
  defp test_guard_patterns() do
    numbers = [1, 5, 10, 15, 20]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, g, :ok}, fn _, {acc_numbers, acc_g, acc_state} ->
  if (acc_g < length(acc_numbers)) do
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
    Log.trace("Number " <> Kernel.to_string(num) <> " is " <> category, %{:file_name => "Main.hx", :line_number => 98, :class_name => "Main", :method_name => "testGuardPatterns"})
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
  if (acc_g < length(acc_arrays)) do
    arr = arrays[g]
    acc_g = acc_g + 1
    description = case (length(arr)) do
  0 ->
    "empty"
  1 ->
    acc_g = arr[0]
    x = acc_g
    "single: " <> Kernel.to_string(x)
  2 ->
    acc_g = arr[0]
    g1 = arr[1]
    x = acc_g
    y = g1
    "pair: " <> Kernel.to_string(x) <> ", " <> Kernel.to_string(y)
  3 ->
    acc_g = arr[0]
    g1 = arr[1]
    g2 = arr[2]
    x = acc_g
    y = g1
    z = g2
    "triple: " <> Kernel.to_string(x) <> ", " <> Kernel.to_string(y) <> ", " <> Kernel.to_string(z)
  _ ->
    "length=" <> Kernel.to_string(length(arr)) <> ", first=" <> (if (length(arr) > 0) do
  Std.string(arr[0])
else
  "none"
end)
end
    Log.trace("Array pattern: " <> description, %{:file_name => "Main.hx", :line_number => 119, :class_name => "Main", :method_name => "testArrayPatterns"})
    {:cont, {acc_arrays, acc_g, acc_state}}
  else
    {:halt, {acc_arrays, acc_g, acc_state}}
  end
end)
  end
  defp test_object_patterns() do
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
    Log.trace("Point " <> Kernel.to_string(point_x) <> "," <> Kernel.to_string(point_y) <> " is in " <> quadrant <> " quadrant", %{:file_name => "Main.hx", :line_number => 135, :class_name => "Main", :method_name => "testObjectPatterns"})
  end
end