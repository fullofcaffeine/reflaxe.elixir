defmodule Main do
  def main() do
    result = get_result()
    _value = unwrap_or(result, "default")
    nil
  end
  defp unwrap_or(result, default_value) do
    (case result do
      {:ok, value} -> value
      {:error, _message} -> default_value
    end)
  end
  defp get_result() do
    {:error, "test error"}
  end
end
