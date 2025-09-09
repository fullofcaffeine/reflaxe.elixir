defmodule Main do
  def main() do
    test_changeset_pattern()
    result = process_data("unused", 42)
    Log.trace(result, %{:file_name => "Main.hx", :line_number => 18, :class_name => "Main", :method_name => "main"})
    test_pattern_matching_unused()
    test_lambda_unused()
  end
  defp test_changeset_pattern() do
    nil
  end
  defp process_data(_unused, data) do
    data * 2
  end
  defp test_pattern_matching_unused() do
    g = get_some_value()
    result = case (elem(g, 0)) do
  0 ->
    g = elem(g, 1)
    g1 = g.metadata
    g = g.value
    __meta = g1
    v = g
    v
  1 ->
    0
end
    Log.trace(result, %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "testPatternMatchingUnused"})
  end
  defp test_lambda_unused() do
    items = [1, 2, 3]
    mapped = Enum.map(items, fn value -> value * 2 end)
    Log.trace(mapped, %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "testLambdaUnused"})
  end
  defp get_some_value() do
    {:Some, %{:value => 42, :metadata => "test"}}
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()