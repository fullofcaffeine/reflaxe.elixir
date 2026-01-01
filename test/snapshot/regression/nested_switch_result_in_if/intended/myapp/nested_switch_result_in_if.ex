defmodule NestedSwitchResultInIf do
  defp outer(flag) do
    if (flag), do: {:ok, 1}, else: {:error, "nope"}
  end
  defp inner(value) do
    if (value > 0), do: {:ok, value + 1}, else: {:error, "bad"}
  end
  def run(flag) do
    (case outer(flag) do
      {:ok, value} ->
        v = value
        if (v > 0) do
          v
        else
          (case inner(v) do
            {:ok, value} -> value
            {:error, _error} -> 0
          end)
        end
      {:error, _error} -> -1
    end)
  end
  def run_inner_only(value) do
    (case inner(value) do
      {:ok, updated} -> updated
      {:error, _error} -> 0
    end)
  end
end
