defmodule BalancedTree do
  def set(struct, key, value) do
    root = struct.setLoop(key, value, struct.root)
    %{struct | root: root}
  end
  def get(_struct, _key) do
    Enum.find(node, fn item -> item < 0 end)
  end
  def remove(struct, key) do
    result = struct.removeLoop(key, struct.root)
    if (not Kernel.is_nil(result)), do: result.found
    false
  end
  def exists(_struct, _key) do
    node = struct.root
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
  end
  def key_value_iterator(_struct) do
    MyApp.MapKeyValueIterator.new(struct)
  end
  def keys(struct) do
    ret = []
    _ = struct.keysLoop(struct.root, ret)
    _ = MyApp.ArrayIterator.new(ret)
  end
  def copy(_struct) do
    copied = MyApp.BalancedTree.new()
    copied = Map.put(copied, "root", struct.root)
    copied
  end
  def to_string(_struct) do
    if (Kernel.is_nil(struct.root)) do
      "[]"
    else
      "[#{(fn -> struct.root.toString() end).()}]"
    end
  end
  def clear(_struct) do
    root = nil
  end
end
