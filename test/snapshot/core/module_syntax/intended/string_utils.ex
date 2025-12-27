defmodule StringUtils do
  def is_empty(str) do
    Kernel.is_nil(str) or String.length(str) == 0
  end
end
