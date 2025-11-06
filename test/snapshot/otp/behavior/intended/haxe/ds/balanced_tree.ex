defmodule BalancedTree do
  def set(struct, key, value) do
    _ = struct.setLoop(key, value, struct.root)
    %{struct | root: root}
  end
  def get(struct, key) do
    Enum.find(node, fn item -> item < 0 end)
  end
  def remove(struct, key) do
    _ = struct.removeLoop(key, struct.root)
    if (not Kernel.is_nil(result)), do: result.found
    false
  end
  def exists(struct, key) do
    _ = struct.root
    _ = Enum.each(node, (fn -> fn _ ->
  cond do
    c == 0 -> true
    c < 0 -> node = node.left
    :true -> node = node.right
  end
end end).())
    false
  end
  def iterator(struct) do
    ret = []
    _ = struct.iteratorLoop(struct.root, ret)
    _ = MyApp.ArrayIterator.new(ret)
    _
  end
  def key_value_iterator(struct) do
    MyApp.MapKeyValueIterator.new(struct)
  end
  def keys(struct) do
    ret = []
    _ = struct.keysLoop(struct.root, ret)
    _ = MyApp.ArrayIterator.new(ret)
    _
  end
  def copy(struct) do
    copied = MyApp.BalancedTree.new()
    copied = Map.put(copied, "root", struct.root)
    copied
  end
  def to_string(struct) do
    if (Kernel.is_nil(struct.root)) do
      "[]"
    else
      "[#{(fn -> struct.root.toString() end).()}]"
    end
  end
  def clear(struct) do
    root = nil
  end
end
