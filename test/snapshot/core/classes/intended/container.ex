defmodule Container do
  def add(struct, item) do
    struct.items ++ [item]
  end
  def get(struct, index) do
    struct.items[index]
  end
  def size(struct) do
    length(struct.items)
  end
  def map(struct, fn_param) do
    result = %Container{}
    _g = 0
    g_value = struct.items
    result = Enum.reduce(g_value, result, fn item, result_acc ->
      _ = add(result_acc, fn_param.(item))
      result_acc
    end)
    result
  end
end
