defmodule Main do
  def main() do
    _ = unused_parameter("test")
    _ = partially_used("used", 42, true)
    _ = all_unused("a", 1, false)
  end
  defp unused_parameter(_) do
    nil
  end
  defp partially_used(_, _, also_used) do
    if (also_used), do: nil
  end
  defp all_unused(_, _, _) do
    nil
  end
end
