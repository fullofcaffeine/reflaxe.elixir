defmodule BalancedTree do
  def set(struct, key, value) do
    root = struct.setLoop(key, value, struct.root)
    %{struct | root: root}
  end
  def exists(struct, key) do
    node = struct.root
    Enum.each(node, fn _ ->
      cond do
        c == 0 -> true
        c < 0 -> node = node.left
        :true -> node = node.right
      end
    end)
    nil
    false
  end
  def keys(struct) do
    ret = []
    _ = struct.keysLoop(struct.root, ret)
    _ = ArrayIterator.new(ret)
  end
end
