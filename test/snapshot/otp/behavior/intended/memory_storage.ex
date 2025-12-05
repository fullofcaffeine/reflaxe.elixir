defmodule MemoryStorage do
  def init(struct, _config) do
    %{:ok => struct}
  end
  def get(_struct, key) do
    this1 = struct.data
    _ = this1.get(key)
  end
  def put(_struct, _key, _value) do
    this1 = struct.data
    _ = Map.put(this1, key, value)
    true
  end
  def delete(_struct, key) do
    this1 = struct.data
    _ = this1.remove(key)
  end
  def list(_struct) do
    k = this1 = struct.data
    _ = this1.keys()
    _ = Enum.each(k, fn item -> [].push(item) end)
    []
  end
end
