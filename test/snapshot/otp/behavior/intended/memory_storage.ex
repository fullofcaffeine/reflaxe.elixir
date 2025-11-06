defmodule MemoryStorage do
  def init(struct, config) do
    %{:ok => struct}
  end
  def get(struct, key) do
    this1 = struct.data
    _ = this1.get(key)
    _
  end
  def put(struct, key, value) do
    _ = struct.data
    _ = Map.put(this1, key, value)
    true
  end
  def delete(struct, key) do
    this1 = struct.data
    _ = this1.remove(key)
    _
  end
  def list(struct) do
    _ = this1 = struct.data
    _ = this1.keys()
    _ = Enum.each(k, fn item -> [].push(item) end)
    []
  end
end
