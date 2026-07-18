defmodule Container do
  def new() do
    struct = %{:__reflaxe_class__ => Container, :items => nil}
    struct = %{struct | items: []}
    struct
  end
  def add(struct, item) do
    struct.items ++ [item]
  end
  def get(struct, index) do
    Enum.at(struct.items, index)
  end
  def size(struct) do
    length(struct.items)
  end
  def map(struct, fn_param) do
    result = Container.new()
    _g = 0
    g_value = struct.items
    result = Enum.reduce(g_value, result, fn item, result_acc ->
      apply(Map.get(result_acc, :__reflaxe_class__) || Map.get(result_acc, :__struct__), :add, [result_acc, fn_param.(item)])
      result_acc
    end)
    result
  end
end
