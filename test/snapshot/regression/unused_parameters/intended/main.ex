defmodule Main do
  def instance_method(struct, used, unused1, unused2) do
    used + 10
  end
  def main() do
    Main.test_unused_parameters(5, "test", true)
    Main.callback_example(fn x, y -> x end)
  end
  defp test_unused_parameters(used1, unused, used2) do
    if used2, do: used1 * 2
    used1
  end
  defp callback_example(callback) do
    callback.(42, "ignored")
  end
  defp fully_unused(x, y, z) do
    "constant"
  end
end