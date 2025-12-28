defmodule Main do
  def instance_method(_, used, _, _) do
    used + 10
  end
  def main() do
    _ = test_unused_parameters(5, "test", true)
    _ = callback_example(fn x, _ -> x end)
  end
  defp test_unused_parameters(used1, _, used2) do
    if (used2), do: used1 * 2, else: used1
  end
  defp callback_example(callback) do
    callback.(42, "ignored")
  end
end
