defmodule Main do
  def main() do
    _ = test_unused_extraction()
    _ = test_used_extraction()
    _ = test_mixed_usage()
    _ = test_nested_extraction()
    _ = test_multiple_extractions()
    _ = test_tree_extraction()
  end
  defp test_unused_extraction() do
    result = {:ok, "hello"}
    switch_result_1 = (case result do
      {:ok, _value} -> "success"
      {:error, _error} -> "failure"
    end)
    switch_result_1
  end
  defp test_used_extraction() do
    result = {:ok, "world"}
    switch_result_2 = (case result do
      {:ok, value} -> "Got: #{value}"
      {:error, msg} -> "Error: #{msg}"
    end)
    switch_result_2
  end
  defp test_mixed_usage() do
    result = {:ok, 42}
    switch_result_3 = (case result do
      {:ok, num} -> "Number is #{inspect(num)}"
      {:error, _error} -> "Got an error"
    end)
    switch_result_3
  end
  defp test_nested_extraction() do
    opt = {:some, {:ok, 123}}
    switch_result_4 = (case opt do
      {:some, result} ->
        (case result do
          {:ok, value} -> "Nested value: #{inspect(value)}"
          {:error, _error} -> "Nested error"
        end)
      {:none} -> "Nothing"
    end)
    switch_result_4
  end
  defp test_multiple_extractions() do
    node = {:node, {:leaf}, 42, {:leaf}}
    switch_result_5 = (case node do
      {:leaf} -> "Empty"
      {:node, _left, value, _right} -> "Value: #{inspect(value)}"
    end)
    switch_result_5
  end
  defp test_tree_extraction() do
    tree = {:node, {:node, {:leaf}, 1, {:leaf}}, 2, {:node, {:leaf}, 3, {:leaf}}}
    switch_result_6 = (case tree do
      {:leaf} -> 0
      {:node, left, value, right} when left == 1 ->
        (case right do
          {:node, _, _, _} -> left_val + center_val + right_val
          _ -> value
        end)
      {:node, _left, value, _right} -> value
    end)
    switch_result_6
  end
end
