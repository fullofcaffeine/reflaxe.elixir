defmodule Main do
  defp unwrap_or(result, default_value) do
    (case result do
      {:ok, value} -> value
      {:error, _reason} -> default_value
    end)
  end
  defp to_option(result) do
    (case result do
      {:ok, value} -> value
      {:error, _reason} -> nil
    end)
  end
  def main() do
    result = {:ok, 42}
    _value = unwrap_or(result, 0)
    _option = to_option(result)
    error_result = {:error, "Something went wrong"}
    _fallback = unwrap_or(error_result, -1)
    nil
  end
end
