defmodule Main do
  defp test_simple_nested_var() do
    Enum.find(0..(length(items) - 1), fn i -> i > 2 end)
  end
  defp test_reflect_fields_nested_var() do
    Enum.find(data, fn item -> item.status == "active" end)
  end
  defp test_deep_nesting() do
    Enum.find(0..(length(matrix) - 1), fn i -> length(i) > 0 end)
  end
end
