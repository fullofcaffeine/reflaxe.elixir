defmodule FileStorage do
  def init(struct, _config) do
    if (not Kernel.is_nil(Map.get(config, :path))) do
      base_path = Map.get(config, :path)
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
