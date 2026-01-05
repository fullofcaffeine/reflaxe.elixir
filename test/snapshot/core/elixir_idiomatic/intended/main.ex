defmodule Main do
  defp test_idiomatic_option() do
    nil
  end
  defp test_literal_option() do
    nil
  end
  defp test_idiomatic_result() do
    nil
  end
  defp test_pattern_matching() do
    _user_opt = (case {:some, 42} do
      {:some, _value} -> nil
      {:none} -> nil
    end)
    _result = (case {:ok, "data"} do
      {:ok, _value} -> nil
      {:error, _reason} -> nil
    end)
  end
  def main() do
    _ = test_idiomatic_option()
    _ = test_literal_option()
    _ = test_idiomatic_result()
    _ = test_pattern_matching()
    nil
  end
end
