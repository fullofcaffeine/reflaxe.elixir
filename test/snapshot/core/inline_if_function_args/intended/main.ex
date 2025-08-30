defmodule Main do
  defp main() do
    Main.test_map_put()
    Main.test_function_calls()
    Main.test_multiple_inline_ifs()
    Main.test_nested_calls()
    Main.test_complex_conditions()
  end
  defp testMapPut() do
    map = %{}
    condition = true
    value = 42
    Map.put(map, "bool_key", (if condition, do: "true", else: "false"))
    Map.put(map, "number_key", (if (value > 10), do: "high", else: "low"))
    is_active = false
    Map.put(map, "status", (if is_active, do: "active", else: "inactive"))
    maybe = nil
    Map.put(map, "nullable", (if (maybe != nil), do: maybe, else: "default"))
  end
  defp testFunctionCalls() do
    flag = true
    count = 5
    Main.process_string((if flag, do: "yes", else: "no"))
    Main.process_two("first", (if (count > 3), do: "many", else: "few"))
    Main.process_two((if flag, do: "enabled", else: "disabled"), "second")
  end
  defp testMultipleInlineIfs() do
    a = true
    b = false
    c = 10
    Main.process_three((if a, do: "a_true", else: "a_false"), (if b, do: "b_true", else: "b_false"), (if (c > 5), do: "c_high", else: "c_low"))
    Main.process_mixed("regular", (if a, do: "conditional", else: "alternative"), 42, (if b, do: 1, else: 0))
  end
  defp testNestedCalls() do
    enabled = true
    level = 7
    result = Main.wrap_string(if enabled do
  Main.get_value("on")
else
  Main.get_value("off")
end)
    nested = Main.process_string(Main.wrap_string((if (level > 5), do: "high", else: "low")))
    complex = Main.process_string(if enabled do
  Main.compute_value(10)
else
  Main.compute_value(5)
end)
  end
  defp testComplexConditions() do
    x = 10
    y = 20
    flag = true
    Main.process_string((if (x > 5 && y < 30), do: "in_range", else: "out_of_range"))
    Main.process_string(if flag do
  if (x > y), do: "x_greater", else: "y_greater"
else
  "disabled"
end)
    str = "test"
    Main.process_string((if (str.length > 3), do: "long", else: "short"))
  end
  defp processString(s) do
    "Processed: " + s
  end
  defp processTwo(a, b) do
    "" + a + ", " + b
  end
  defp processThree(a, b, c) do
    "" + a + ", " + b + ", " + c
  end
  defp processMixed(a, b, c, d) do
    "" + a + ", " + b + ", " + c + ", " + d
  end
  defp getValue(key) do
    "value_" + key
  end
  defp wrapString(s) do
    "[" + s + "]"
  end
  defp computeValue(n) do
    "computed_" + n
  end
end