defmodule Main do
  def main() do
    _ = test_simple_enum_pattern()
    _ = test_complex_enum_pattern()
    _ = test_result_pattern()
    _ = test_guard_patterns()
    _ = test_array_patterns()
    _ = test_object_patterns()
    nil
  end
  defp test_simple_enum_pattern() do
    color = {:red}
    result = ((case color do
  {:red} -> "red"
  {:green} -> "green"
  {:blue} -> "blue"
  {:rgb, r, g, b} -> "custom"
end))
    nil
  end
  defp test_complex_enum_pattern() do
    color = {:rgb, 255, 128, 0}
    brightness = ((case color do
  {:red} -> "primary"
  {:green} -> "primary"
  {:blue} -> "primary"
  {:rgb, r, g, b} ->
    cond do
      r + g + b > 500 -> "bright"
      r + g + b < 100 -> "dark"
      true -> "medium"
    end
end))
    nil
  end
  defp test_result_pattern() do
    result = {:ok, "success"}
    message = ((case result do
  {:ok, _value} ->
    fn_ = _value
    value = _value
    "Got value: #{(fn -> value end).()}"
  {:error, _value} ->
    fn_ = _value
    error = _value
    "Got error: #{(fn -> error end).()}"
end))
    nil
  end
  defp test_guard_patterns() do
    numbers = [1, 5, 10, 15, 20]
    _ = Enum.each(numbers, (fn -> fn item ->
    category = n = item
  if (item < 5) do
    "small"
  else
    n = item
    if (item >= 5 and item < 15) do
      "medium"
    else
      n = item
      if (item >= 15), do: "large", else: "unknown"
    end
  end
  nil
end end).())
  end
  defp test_array_patterns() do
    arrays = [[], [1], [1, 2], [1, 2, 3], [1, 2, 3, 4, 5]]
    _ = Enum.each(arrays, (fn -> fn item ->
    description = (case length(item) do
    0 -> "empty"
    1 -> "single: " <> Kernel.to_string(x)
    2 -> "pair: " <> Kernel.to_string(x) <> ", " <> Kernel.to_string(y)
    3 -> "triple: " <> Kernel.to_string(x) <> ", " <> Kernel.to_string(y) <> ", " <> Kernel.to_string(z)
    _ -> "length=" <> Kernel.to_string(length(arr)) <> ", first=" <> (if (length(item) > 0), do: inspect(arr[0]), else: "none")
  end)
  nil
end end).())
  end
  defp test_object_patterns() do
    point_y = nil
    point_x = nil
    point_x = 10
    point_y = 20
    quadrant = g = point_x
    _ = point_y
    if (point_x > 0 and point_y > 0) do
      "first"
    else
      if (point_x < 0 and point_y > 0) do
        "second"
      else
        if (point_x < 0 and point_y < 0) do
          "third"
        else
          cond do
            x > 0 and y < 0 -> "fourth"
            _g == 0 -> "axis"
            _g1 == 0 -> "axis"
            :true -> "origin"
          end
        end
      end
    end
    nil
  end
end
