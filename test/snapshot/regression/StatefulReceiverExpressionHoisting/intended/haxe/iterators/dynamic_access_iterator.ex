defmodule DynamicAccessIterator do
  def new(access_param) do
    struct = %{:__reflaxe_class__ => DynamicAccessIterator, :access => nil, :keys => nil, :index => nil}
    struct = %{struct | access: access_param}
    struct = %{struct | keys: Reflect.fields(access_param)}
    struct = %{struct | index: 0}
    struct
  end
  def has_next(struct) do
    not Kernel.is_nil(Enum.at(struct.keys, struct.index))
  end
  def next(struct) do
    key = Enum.at(struct.keys, struct.index)
    struct = %{struct | index: struct.index + 1}
    (case {struct.access, key} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
end
