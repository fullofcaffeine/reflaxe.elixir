defmodule Main do
  defp main() do
    test_changeset_pattern()
    result = process_data("unused", 42)
    Log.trace(result, %{:fileName => "Main.hx", :lineNumber => 18, :className => "Main", :methodName => "main"})
    test_pattern_matching_unused()
    test_lambda_unused()
  end
  defp test_changeset_pattern() do
    nil
  end
  defp process_data(__unused, data) do
    data * 2
  end
  defp test_pattern_matching_unused() do
    g = {:GetSomeValue}
    result = case (g.elem(0)) do
  0 ->
    g = g.elem(1)
    g1 = g[:metadata]
    g = g[:value]
    __meta = g1
    v = g
    v
  1 ->
    0
end
    Log.trace(result, %{:fileName => "Main.hx", :lineNumber => 57, :className => "Main", :methodName => "testPatternMatchingUnused"})
  end
  defp test_lambda_unused() do
    items = [1, 2, 3]
    mapped = Enum.map(items, fn value -> value * 2 end)
    Log.trace(mapped, %{:fileName => "Main.hx", :lineNumber => 69, :className => "Main", :methodName => "testLambdaUnused"})
  end
  defp get_some_value() do
    {:Some, %{:value => 42, :metadata => "test"}}
  end
end