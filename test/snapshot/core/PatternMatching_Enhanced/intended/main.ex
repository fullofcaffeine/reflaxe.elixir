defmodule Main do
  def main() do
    test_simple_enum_pattern()
    test_complex_enum_pattern()
    test_result_pattern()
    test_guard_patterns()
    test_array_patterns()
    test_object_patterns()
    nil
  end
  defp test_simple_enum_pattern() do
    _result = (case {:red} do
      {:red} -> "red"
      {:green} -> "green"
      {:blue} -> "blue"
      {:rgb, _, _, _} -> "custom"
    end)
    nil
  end
  defp test_complex_enum_pattern() do
    brightness = (case {:rgb, 255, 128, 0} do
      {:red} -> "primary"
      {:green} -> "primary"
      {:blue} -> "primary"
      {:rgb, r, g, b} ->
        if (r + g + b > 500) do
          "bright"
        else
          if (r + g + b < 100), do: "dark", else: "medium"
        end
    end)
    if (brightness != "medium") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "RGB guard must use each distinct channel"]
    end
    nil
  end
  defp test_result_pattern() do
    _message = (case {:ok, "success"} do
      {:ok, value} -> "Got value: #{value}"
      {:error, error} -> "Got error: #{error}"
    end)
    nil
  end
  defp test_guard_patterns() do
    numbers = [1, 5, 10, 15, 20]
    Enum.each(numbers, fn num ->
      n = num
      _category = if (n < 5) do
        "small"
      else
        n = num
        if (n >= 5 and n < 15) do
          "medium"
        else
          n = num
          if (n >= 15), do: "large", else: "unknown"
        end
      end
      nil
    end)
  end
  defp test_array_patterns() do
    arrays = [[], [1], [1, 2], [1, 2, 3], [1, 2, 3, 4, 5]]
    Enum.each(arrays, fn arr ->
      _description = (case length(arr) do
        0 -> "empty"
        1 ->
          array_read_node_0 = Enum.at(arr, 0)
          x = array_read_node_0
          "single: " <> Reflaxe.Elixir.HaxeFloat.to_string(x)
        2 ->
          array_read_node_1 = Enum.at(arr, 0)
          array_read_node_2 = Enum.at(arr, 1)
          x = array_read_node_1
          y = array_read_node_2
          "pair: " <> Reflaxe.Elixir.HaxeFloat.to_string(x) <> ", " <> Reflaxe.Elixir.HaxeFloat.to_string(y)
        3 ->
          array_read_node_3 = Enum.at(arr, 0)
          array_read_node_4 = Enum.at(arr, 1)
          array_read_node_5 = Enum.at(arr, 2)
          x = array_read_node_3
          y = array_read_node_4
          z = array_read_node_5
          "triple: " <> Reflaxe.Elixir.HaxeFloat.to_string(x) <> ", " <> Reflaxe.Elixir.HaxeFloat.to_string(y) <> ", " <> Reflaxe.Elixir.HaxeFloat.to_string(z)
        _ ->
          "length=" <> Reflaxe.Elixir.HaxeFloat.to_string(length(arr)) <> ", first=" <> (if (length(arr) > 0) do
            Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(arr, 0))
          else
            "none"
          end)
      end)
      nil
    end)
  end
  defp test_object_patterns() do
    point_x = 10
    point_y = 20
    g = point_x
    g_value = point_y
    x = g
    y = g_value
    _quadrant = if (x > 0 and y > 0) do
      "first"
    else
      x = g
      y = g_value
      if (x < 0 and y > 0) do
        "second"
      else
        x = g
        y = g_value
        if (x < 0 and y < 0) do
          "third"
        else
          x = g
          y = g_value
          cond do
            x > 0 and y < 0 -> "fourth"
            g == 0 -> "axis"
            g_value == 0 -> "axis"
            true -> "origin"
          end
        end
      end
    end
    nil
  end
end
