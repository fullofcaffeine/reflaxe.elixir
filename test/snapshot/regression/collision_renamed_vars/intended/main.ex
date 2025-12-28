defmodule Main do
  defp compare_params(p1, p2) do
    _p = p1
    p = p2
    if (length(p1) == 0 and length(p2) == 0), do: 0, else: compare_arrays(p1, p2)
  end
  defp compare_arrays(a1, a2) do
    (length(a1) - length(a2))
  end
  def main() do
    _result = compare_params([1, 2], [3, 4, 5])
    nil
  end
end
