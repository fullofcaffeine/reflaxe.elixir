defmodule Main do
  def main() do
    test_changeset_pattern()
    _result = process_data("unused", 42)
    if (test_pattern_matching_unused(get_some_value()) != 42 or test_pattern_matching_unused({:none}) != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Pattern matching must preserve the used value and the empty case"]
    end
    test_lambda_unused()
  end
  defp test_changeset_pattern() do

  end
  defp process_data(_unused, data) do
    data * 2
  end
  defp test_pattern_matching_unused(input) do
    (case input do
      {:some, value} ->
        g_metadata = value.metadata
        g_value = value.value
        _meta = g_metadata
        v = g_value
        v
      {:none} -> 0
    end)
  end
  defp test_lambda_unused() do
    items = [1, 2, 3]
    _mapped = Enum.map(items, fn value -> value * 2 end)
    nil
  end
  defp get_some_value() do
    {:some, %{value: 42, metadata: "test"}}
  end
end
