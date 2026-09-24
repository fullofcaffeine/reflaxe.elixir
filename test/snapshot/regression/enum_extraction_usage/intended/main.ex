defmodule Main do
  def main() do
    assert_text(test_unused_extraction({:ok, "hello"}), "success")
    assert_text(test_unused_extraction({:error, "ignored"}), "failure")
    assert_text(test_used_extraction({:ok, "world"}), "Got: world")
    assert_text(test_used_extraction({:error, "offline"}), "Error: offline")
    assert_text(test_mixed_usage({:ok, 42}), "Number is 42")
    assert_text(test_mixed_usage({:error, "ignored"}), "Got an error")
    assert_text(test_nested_extraction({:some, {:ok, 123}}), "Nested value: 123")
    assert_text(test_nested_extraction({:some, {:error, "ignored"}}), "Nested error")
    assert_text(test_nested_extraction({:none}), "Nothing")
    assert_text(test_multiple_extractions({:node, {:leaf}, 42, {:leaf}}), "Value: 42")
    assert_text(test_multiple_extractions({:leaf}), "Empty")
    if (test_tree_extraction({:node, {:node, {:leaf}, 1, {:leaf}}, 2, {:node, {:leaf}, 3, {:leaf}}}) != 6) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested tree extraction must preserve all three independent bindings"]
    end
    if (test_tree_extraction({:node, {:leaf}, 7, {:leaf}}) != 7 or test_tree_extraction({:leaf}) != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Tree fallback branches must preserve their results"]
    end
    if (not test_option_extraction({:some, "test"}) or test_option_extraction({:none})) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Unused option payloads must not change constructor selection"]
    end
  end
  defp assert_text(actual, expected) do
    if (actual != expected) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected " <> expected <> ", got " <> actual]
    end
  end
  defp test_unused_extraction(result) do
    (case result do
      {:ok, _value} -> "success"
      {:error, _error} -> "failure"
    end)
  end
  defp test_used_extraction(result) do
    (case result do
      {:ok, value} -> "Got: #{value}"
      {:error, msg} -> "Error: #{msg}"
    end)
  end
  defp test_mixed_usage(result) do
    (case result do
      {:ok, num} -> "Number is #{Reflaxe.Elixir.HaxeFloat.to_string(num)}"
      {:error, _error} -> "Got an error"
    end)
  end
  defp test_nested_extraction(opt) do
    (case opt do
      {:some, result} ->
        (case result do
          {:ok, value} -> "Nested value: #{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
          {:error, _error} -> "Nested error"
        end)
      {:none} -> "Nothing"
    end)
  end
  defp test_multiple_extractions(node) do
    (case node do
      {:leaf} -> "Empty"
      {:node, _left, value, _right} -> "Value: #{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
    end)
  end
  defp test_tree_extraction(tree) do
    (case tree do
      {:leaf} -> 0
      {:node, left, center_val, right} ->
        (case left do
          {:node, _g3, left_val, _} ->
            (case right do
              {:node, _g, right_val, _} -> left_val + center_val + right_val
              _ ->
                value = center_val
                value
            end)
          _ ->
            value = center_val
            value
        end)
    end)
  end
  defp test_option_extraction(opt) do
    (case opt do
      {:some, _val} -> true
      {:none} -> false
    end)
  end
end
