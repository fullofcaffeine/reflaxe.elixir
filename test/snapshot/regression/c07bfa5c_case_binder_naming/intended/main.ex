defmodule Main do
  defp unwrap_or(result, default_value) do
    (case result do
      {:ok, value} ->
        default_value = value
        default_value
      {:error, defaultValue} -> defaultValue
    end)
  end
  defp to_option(result) do
    (case result do
      {:ok, value} -> value
      {:error, value} -> {:none}
    end)
  end
  def main() do
    r1 = 42
    r2 = "x"
    unwrap_or(r1, 0)
    unwrap_or(r2, 0)
    to_option(r1)
    to_option(r2)
  end
end
