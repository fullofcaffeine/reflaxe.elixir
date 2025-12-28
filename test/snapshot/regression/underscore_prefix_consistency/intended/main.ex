defmodule Main do
  def main() do
    _ = test_changeset_pattern()
    _result = process_data("unused", 42)
    _ = test_pattern_matching_unused()
    _ = test_lambda_unused()
  end
  defp test_changeset_pattern() do
    
  end
  defp process_data(_, data) do
    data * 2
  end
  defp test_pattern_matching_unused() do
    _result = (case get_some_value() do
      {:some, value} ->
        g_metadata = value.metadata
        g_value = g_value.value
        _meta = g_metadata
        v = g_value
        v
      {:none} -> 0
    end)
    nil
  end
  defp test_lambda_unused() do
    items = [1, 2, 3]
    _mapped = Enum.map(items, fn value -> value * 2 end)
    nil
  end
  defp get_some_value() do
    {:some, %{:value => 42, :metadata => "test"}}
  end
end
