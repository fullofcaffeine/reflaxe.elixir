defmodule Reflect do
  def copy(obj) do
    obj
  end
  def compare(a, b) do
    sa = Std.string(a)
    sb = Std.string(b)
    if (sa < sb), do: -1
    if (sa > sb), do: 1
    0
  end
end