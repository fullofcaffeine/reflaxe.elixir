defmodule TestBuilder do
  def new(name_param) do
    struct = %{:__reflaxe_class__ => TestBuilder, :name => nil, :items => nil}
    struct = %{struct | name: name_param}
    struct = %{struct | items: []}
    struct
  end
  def add_item(struct, name_param, value) do
    %{struct | items: struct.items ++ [{:add_item, name_param, value}]}
  end
  def remove_item(struct, name_param) do
    struct = %{struct | items: struct.items ++ [{:remove_item, name_param}]}
    struct
  end
  def get_item_count(struct) do
    length(struct.items)
  end
end
