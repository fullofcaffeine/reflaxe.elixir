defmodule Main do
  def main() do
    (case compute(0) do
      {:ok, _value} -> nil
      {:error, _error} -> nil
    end)
    (case compute(1) do
      {:ok, _value} -> nil
      {:error, _error} -> nil
    end)
    (case compute(2) do
      {:ok, _value} -> nil
      {:error, _error} -> nil
    end)
  end
  defp compute(n) do
    if (n > 0), do: {:ok, "Value " <> Kernel.to_string(n)}, else: {:error, "Invalid"}
  end
end
