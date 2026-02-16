defmodule Main do
  def main() do
    _ = unused_parameter("test")
    _ = partially_used("used", 42, true)
    _ = all_unused("a", 1, false)
    _ = handle_result({:error, "boom"})
  end
  defp unused_parameter(_unused) do
    nil
  end
  defp partially_used(_used, _unused, also_used) do
    if (also_used), do: nil
  end
  defp all_unused(_a, _b, _c) do
    nil
  end
  defp handle_result(result) do
    (case result do
      {:ok, value} -> value
      {:error, _err} -> 0
    end)
  end
end
