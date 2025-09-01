defmodule StringUtils do
  def is_empty(str) do
    str == nil || str.length == 0
  end
  defp sanitize(str) do
    str
  end
end