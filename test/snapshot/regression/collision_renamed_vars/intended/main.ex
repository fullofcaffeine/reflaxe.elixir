defmodule Main do
  defp compare_params(p1, p2) do
    p = p1
    p = p2
    if (p1.length == 0 && p2.length == 0), do: 0
    compare_arrays(p1, p2)
  end
  defp compare_arrays(a1, a2) do
    a1.length - a2.length
  end
  defp main() do
    result = compare_params([1, 2], [3, 4, 5])
    Log.trace("Result: " <> result, %{:fileName => "Main.hx", :lineNumber => 18, :className => "Main", :methodName => "main"})
  end
end