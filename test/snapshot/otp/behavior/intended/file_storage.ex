defmodule FileStorage do
  @base_path nil
  def init(struct, config) do
    if (config.path != nil) do
      basePath = config.path
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