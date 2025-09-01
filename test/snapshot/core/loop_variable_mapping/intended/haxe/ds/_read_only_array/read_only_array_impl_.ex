defmodule ReadOnlyArray_Impl_ do
  defp get_length(this1) do
    this1.length
  end
  defp get(this1, i) do
    this1[i]
  end
  def concat(this1, a) do
    this1 ++ a
  end
end