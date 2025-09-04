defmodule Main do
  defp main() do
    test_map_put()
    test_function_calls()
    test_multiple_inline_ifs()
    test_nested_calls()
    test_complex_conditions()
  end
  defp test_map_put() do
    map = %{}
    condition = true
    value = 42
    map = Map.put(map, "bool_key", (if condition, do: "true", else: "false"))
    map = Map.put(map, "number_key", (if (value > 10), do: "high", else: "low"))
    is_active = false
    map = Map.put(map, "status", (if is_active, do: "active", else: "inactive"))
    maybe = nil
    map = Map.put(map, "nullable", (if (maybe != nil), do: maybe, else: "default"))
  end
  defp test_function_calls() do
    flag = true
    count = 5
    process_string((if flag, do: "yes", else: "no"))
    process_two("first", (if (count > 3), do: "many", else: "few"))
    process_two((if flag, do: "enabled", else: "disabled"), "second")
  end
  defp test_multiple_inline_ifs() do
    a = true
    b = false
    c = 10
    process_three((if a, do: "a_true", else: "a_false"), (if b, do: "b_true", else: "b_false"), (if (c > 5), do: "c_high", else: "c_low"))
    process_mixed("regular", (if a, do: "conditional", else: "alternative"), 42, (if b, do: 1, else: 0))
  end
  defp test_nested_calls() do
    enabled = true
    level = 7
    _result = wrap_string((if enabled, do: get_value("on"), else: get_value("off")))
    _nested = process_string(wrap_string((if (level > 5), do: "high", else: "low")))
    _complex = process_string((if enabled, do: compute_value(10), else: compute_value(5)))
  end
  defp test_complex_conditions() do
    x = 10
    y = 20
    flag = true
    process_string((if (x > 5 && y < 30), do: "in_range", else: "out_of_range"))
    process_string(if flag do
  if (x > y), do: "x_greater", else: "y_greater"
else
  "disabled"
end)
    str = "test"
    process_string((if (str.length > 3), do: "long", else: "short"))
  end
  defp process_string(s) do
    "Processed: " <> s
  end
  defp process_two(a, b) do
    "" <> a <> ", " <> b
  end
  defp process_three(a, b, c) do
    "" <> a <> ", " <> b <> ", " <> c
  end
  defp process_mixed(a, b, c, d) do
    "" <> a <> ", " <> b <> ", " <> c <> ", " <> d
  end
  defp get_value(key) do
    "value_" <> key
  end
  defp wrap_string(s) do
    "[" <> s <> "]"
  end
  defp compute_value(n) do
    "computed_" <> n
  end
end