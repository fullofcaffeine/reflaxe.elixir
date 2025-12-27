defmodule MemoryStorage do
  def init(struct, config) do
    %{:ok => struct}
  end
  def get(struct, key) do
    this1 = struct.data
    _ = StringMap.get(this1, key)
  end
  def put(struct, key, value) do
    this1 = struct.data
    _ = StringMap.set(this1, key, value)
    true
  end
  def delete(struct, key) do
    this1 = struct.data
    _ = StringMap.remove(this1, key)
  end
  def list(struct) do
    this1 = struct.data
    k = _ = StringMap.keys(this1)
    _ = Enum.each(colors, fn item -> [item] end)
    []
  end
end
