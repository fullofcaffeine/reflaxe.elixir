defmodule FileStorage do
  def new() do
    struct = %{:__reflaxe_class__ => FileStorage, :base_path => nil}
    struct = %{struct | base_path: "/tmp/storage"}
    struct
  end
  def init(struct, config) do
    cond_value = (case config do
      dyn_obj ->
        (case Map.fetch(dyn_obj, "path") do
          {:ok, dyn_value} -> dyn_value
          _ ->
            Map.get(dyn_obj, :path)
        end)
    end)
    struct = if (not Kernel.is_nil(cond_value)) do
      %{struct | base_path: (case config do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "path") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :path)
    end)
end)}
    else
      struct
    end
    %{:ok => struct}
  end
  def get(_struct, _key) do
    nil
  end
  def put(_struct, _key, _value) do
    true
  end
  def delete(_struct, _key) do
    true
  end
  def list(_struct) do
    []
  end
end
