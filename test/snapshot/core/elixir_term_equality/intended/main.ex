defmodule Main do
  def same(left, right) do
    left == right
  end
  def different(left, right) do
    left != right
  end
  def non_null(value) do
    not Kernel.is_nil(value)
  end
end
