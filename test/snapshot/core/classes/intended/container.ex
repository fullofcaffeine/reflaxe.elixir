defmodule Container do
  def add(struct, item) do
    items = items ++ [item]
  end
  def get(struct, index) do
    struct.items[index]
  end
  def size(struct) do
    length(struct.items)
  end
  def map(struct, fn_param) do
    _g = 0
    _g1 = struct.items
    _ = Enum.each(g_value, fn item -> StringBuf.add(result, fn_param.(item)) end)
    %Container{}
  end
end
