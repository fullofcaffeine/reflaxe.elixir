defmodule Main do
  def main() do
    _ = test_simple_if_push()
    _ = test_if_else_push()
    _ = test_conditional_accumulation()
    _ = test_nested_if_push()
  end
  defp test_simple_if_push() do
    errors = []
    has_error = true
    errors = if (has_error), do: errors ++ ["Error occurred"], else: errors
    nil
  end
  defp test_if_else_push() do
    messages = []
    success = false
    messages = if (success), do: messages ++ ["Success!"], else: messages ++ ["Failed!"]
    nil
  end
  defp test_conditional_accumulation() do
    errors = []
    errors = errors ++ ["Error 1"]
    errors = errors ++ ["Error 3"]
    nil
  end
  defp test_nested_if_push() do
    results = []
    level1 = true
    level2 = true
    results = if (level1) do
      results = results ++ ["Level 1"]
      if (level2), do: results ++ ["Level 2"], else: results
    else
      results
    end
    nil
  end
end
