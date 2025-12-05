defmodule Main do
  defp test_changeset_pattern() do
    
  end
  defp process_data(_unused, data) do
    data * 2
  end
  defp test_pattern_matching_unused() do
    result = (case get_some_value() do
      {:some, v} ->
        _meta = v
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
