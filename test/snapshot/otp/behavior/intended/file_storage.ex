defmodule FileStorage do
  @base_path nil
  def init(struct, config) do
    if (config.path != nil) do
      basePath = config.path
    end
    %{:ok => struct}
  end
  def get(struct, _key) do
    nil
  end
  def put(struct, _key, _value) do
    true
  end
  def delete(struct, _key) do
    true
  end
  def list(struct) do
    []
  end
end