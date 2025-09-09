defmodule StringUtils do
  def is_empty(str) do
    str == nil || length(str) == 0
  end
  defp sanitize(str) do
    str
  end
end