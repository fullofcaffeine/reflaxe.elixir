defmodule TestBuilder do
  @name nil
  @items nil
  def add_item(struct, name, value) do
    %{struct | items: struct.items ++ [{:add_item, name, value}]}
  end
  def remove_item(struct, name) do
    struct = %{struct | items: struct.items ++ [{:remove_item, name}]}
    struct
  end
  def get_item_count(struct) do
    length(struct.items)
  end
end