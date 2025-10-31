defmodule StringUtils do
  def is_empty(str) do
    Kernel.is_nil(str) or length(str) == 0
  end
end
