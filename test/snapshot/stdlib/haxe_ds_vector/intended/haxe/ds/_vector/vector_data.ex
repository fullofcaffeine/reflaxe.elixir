defmodule VectorData do
  def new(length_param, items) do
    struct = %{:__reflaxe_class__ => VectorData, :length => nil, :ref => nil, :dict_key => nil}
    struct = %{struct | length: length_param}
    struct = %{struct | ref: :erlang.unique_integer([:positive])}
    struct = %{struct | dict_key: {:reflaxe_vector, struct.ref}}
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :put_items, [struct, items])
    struct
  end
  def items(struct) do
    stored = Process.get(struct.dict_key)
    stored = if (Kernel.is_nil(stored)) do
      stored = []
      apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :put_items, [struct, stored])
      stored
    else
      stored
    end
    stored
  end
  def put_items(struct, items) do
    Process.put(struct.dict_key, items)
  end
  def get(struct, index) do
    Enum.at(apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :items, [struct]), index)
  end
  def set(struct, index, value) do
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :put_items, [struct, List.replace_at(apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :items, [struct]), index, value)])
    value
  end
end
