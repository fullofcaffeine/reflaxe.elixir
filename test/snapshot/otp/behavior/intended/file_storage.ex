defmodule FileStorage do
  def init(struct, config) do
    if (not Kernel.is_nil(Map.get(config, :path))) do
      base_path = Map.get(config, :path)
    end
    %{:ok => struct}
  end
  def get(struct, key) do
    nil
  end
  def put(struct, key, value) do
    true
  end
  def delete(struct, key) do
    true
  end
  def list(struct) do
    []
  end
end
