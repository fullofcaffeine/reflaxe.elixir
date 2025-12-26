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
  {:rgb, _r, _g, _b} -> "custom"
end))
    nil
  end
  defp test_complex_enum_pattern() do
    color = {:rgb, 255, 128, 0}
    brightness = ((case color do
  {:red} -> "primary"
  {:green} -> "primary"
  {:blue} -> "primary"
  {:rgb, r, _g, b} ->
    b = r
    if (r + r + b > 500) do
      "bright"
    else
      b = r
      if (r + r + b < 100) do
        "dark"
      else
        _b = r
        "medium"
      end
    end
end))
    nil
  end
  defp test_result_pattern() do
    result = {:ok, "success"}
    message = ((case result do
  {:ok, value} -> "Got value: #{(fn -> value end).()}"
  {:error, error} -> "Got error: #{(fn -> error end).()}"
end))
    nil
  end
  defp test_guard_patterns() do
    numbers = [1, 5, 10, 15, 20]
    _g = 0
    _ = Enum.each(numbers, (fn -> fn num ->
  _n = num
  category = if (num < 5) do
    "small"
  else
    _n = num
    if (num >= 5 and num < 15) do
      "medium"
    else
      _n = num
      if (num >= 15), do: "large", else: "unknown"
    end
  end
  nil
end end).())
  end
  defp test_array_patterns() do
    arrays = [[], [1], [1, 2], [1, 2, 3], [1, 2, 3, 4, 5]]
    _g = 0
    _ = Enum.each(arrays, (fn -> fn arr ->
  description = ((case arr do
  [] -> "empty"
  [_head | _tail] ->
    x = arr[0]
    "single: " <> Kernel.to_string(x)
  2 ->
    x = arr[0]
    y = arr[1]
    "pair: " <> Kernel.to_string(x) <> ", " <> Kernel.to_string(y)
  3 ->
    x = arr[0]
    y = arr[1]
    z = arr[2]
    "triple: " <> Kernel.to_string(x) <> ", " <> Kernel.to_string(y) <> ", " <> Kernel.to_string(z)
  _ -> "length=" <> Kernel.to_string(length(arr)) <> ", first=" <> (if (length(arr) > 0), do: inspect(arr[0]), else: "none")
end))
  nil
end end).())
  end
  defp test_object_patterns() do
    point_y = nil
    _ = nil
    point_x = 10
    point_y = 20
    g = point_y
    quadrant = x = g
    y = g
    if (x > 0 and y > 0) do
      "first"
    else
      x = g
      y = g
      if (x < 0 and y > 0) do
        "second"
      else
        x = g
        y = g
        if (x < 0 and y < 0) do
          "third"
        else
          x = g
          y = g
          cond do
            x > 0 and y < 0 -> "fourth"
            g == 0 -> "axis"
            g == 0 -> "axis"
            :true -> "origin"
          end
        end
      end
    end
    nil
  end
end
