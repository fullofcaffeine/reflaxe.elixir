defmodule Main do
  defp compare_params(p1, p2) do
    _p = p1
    _p = p2
    if (length(p1) == 0 && length(p2) == 0), do: 0
    compare_arrays(p1, p2)
  end
  defp compare_arrays(a1, a2) do
    (length(a1) - length(a2))
  end
  def main() do
    result = compare_params([1, 2], [3, 4, 5])
    Log.trace("Result: #{result}", %{:file_name => "Main.hx", :line_number => 18, :class_name => "Main", :method_name => "main"})
  end
end