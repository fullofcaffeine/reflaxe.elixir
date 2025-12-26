defmodule MemoryStorage do
  def init(struct, config) do
    %{:ok => struct}
  end
  def get(struct, key) do
    this1 = struct.data
    _ = this1.get(key)
  end
  def put(struct, key, value) do
    this1 = struct.data
    _ = Map.put(this1, key, value)
    true
  end
  def delete(struct, key) do
    this1 = struct.data
    _ = this1.remove(key)
  end
  def list(struct) do
    this1 = struct.data
    k = _ = this1.keys()
    _ = Enum.each(colors, fn item -> _ = [item] end)
    []
  end
end
