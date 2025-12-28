defmodule FileStorage do
  def new() do
    struct = %{:base_path => nil}
    struct = %{struct | base_path: "/tmp/storage"}
    struct
  end
  def init(struct, config) do
    if (not Kernel.is_nil(Map.get(config, :path))) do
      struct = %{struct | base_path: Map.get(config, :path)}
    end
    %{:ok => struct}
  end
  def get(_, _) do
    nil
  end
  def put(_, _, _) do
    true
  end
  def delete(_, _) do
    true
  end
  def list(_) do
    []
  end
end
