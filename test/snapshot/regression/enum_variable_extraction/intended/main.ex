defmodule Main do
  def main() do
    test_result_unwrap_or()
    test_result_map()
    test_option_unwrap()
    test_option_map()
    test_nested_patterns()
  end
  defp unwrap_or(result, default_value) do
    (case result do
      {:ok, value} -> value
      {:error, _error} -> default_value
    end)
  end
  defp map_result(result, fn_param) do
    (case result do
      {:ok, value} -> {:ok, fn_param.(value)}
      {:error, error} -> {:error, error}
    end)
  end
  defp unwrap_option(option, default_value) do
    (case option do
      {:some, value} -> value
      {:none} -> default_value
    end)
  end
  defp map_option(option, fn_param) do
    (case option do
      {:some, value} -> {:some, fn_param.(value)}
      {:none} -> {:none}
    end)
  end
  defp process_nested_result(result) do
    (case result do
      {:ok, value} ->
        (case value do
          {:some, value} -> value
          {:none} -> 0
        end)
      {:error, _error} -> -1
    end)
  end
  defp test_result_unwrap_or() do
    result1 = {:ok, 42}
    result2 = {:error, "failed"}
    _ = unwrap_or(result1, 0)
    _ = unwrap_or(result2, 0)
    nil
  end
  defp test_result_map() do
    result = {:ok, 10}
    _mapped = (case map_result(result, fn x -> x * 2 end) do
      {:ok, _value} -> nil
      {:error, _error} -> nil
    end)
  end
  defp test_option_unwrap() do
    option1 = {:some, "hello"}
    option2 = {:none}
    _ = unwrap_option(option1, "default")
    _ = unwrap_option(option2, "default")
    nil
  end
  defp test_option_map() do
    option = {:some, 5}
    _mapped = (case map_option(option, fn x -> x + 10 end) do
      {:some, _value} -> nil
      {:none} -> nil
    end)
  end
  defp test_nested_patterns() do
    nested1 = {:ok, {:some, 100}}
    nested2 = {:ok, {:none}}
    nested3 = {:error, "failed"}
    _ = process_nested_result(nested1)
    _ = process_nested_result(nested2)
    _ = process_nested_result(nested3)
    nil
  end
end
