defmodule Main do
  def main() do
    _ = test_unused_variable()
    _ = test_unused_enum_extraction()
    _ = test_unused_parameter(42)
  end
  defp test_unused_variable() do
    nil
  end
  defp test_unused_enum_extraction() do
    _result = (case {:ok, "success"} do
      {:ok, _value} -> nil
      {:error, _msg} -> nil
    end)
  end
  defp test_unused_parameter(_) do
    nil
  end
end
