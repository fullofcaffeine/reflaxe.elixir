defmodule Main do
  defp test_changeset_pattern() do
    
  end
  defp process_data(unused, data) do
    data * 2
  end
  defp test_pattern_matching_unused() do
    result = (case get_some_value() do
      {:some, value} ->
        _g1 = value.metadata
        _g = g_value.value
        _meta = g_metadata
        v = g_value
        v
      {:none} -> 0
    end)
    nil
  end
  defp test_lambda_unused() do
    items = [1, 2, 3]
    mapped = Enum.map(items, fn value -> value * 2 end)
    nil
  end
  defp get_some_value() do
    {:some, %{:value => 42, :metadata => "test"}}
  end
end
