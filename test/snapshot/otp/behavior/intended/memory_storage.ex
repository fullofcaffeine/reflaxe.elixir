defmodule MemoryStorage do
  @data nil
  def init(struct, _config) do
    %{:ok => struct}
  end
  def get(struct, key) do
    this1 = struct.data
    Map.get(this1, key)
  end
  def put(struct, key, value) do
    this1 = struct.data
    this1 = Map.put(this1, key, value)
    true
  end
  def delete(struct, key) do
    this1 = struct.data
    Map.delete(this1, key)
  end
  def list(struct) do
    g = []
    this1 = struct.data
    k = Map.keys(this1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} -> nil end)
    g
  end
end