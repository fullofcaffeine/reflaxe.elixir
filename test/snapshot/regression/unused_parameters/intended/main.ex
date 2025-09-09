defmodule Main do
  def instance_method(struct, used, _unused1, _unused2) do
    used + 10
  end
  def main() do
    test_unused_parameters(5, "test", true)
    callback_example(fn x, _y -> x end)
  end
  defp test_unused_parameters(used1, _unused, used2) do
    if used2, do: used1 * 2
    used1
  end
  defp callback_example(callback) do
    callback.(42, "ignored")
  end
  defp fully_unused(_x, _y, _z) do
    "constant"
  end
end