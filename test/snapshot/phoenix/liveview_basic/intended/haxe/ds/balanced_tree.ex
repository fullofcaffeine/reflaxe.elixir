defmodule BalancedTree do
  def set(struct, key, value) do
    root = struct.setLoop(key, value, struct.root)
    %{struct | root: root}
  end
  def get(struct, key) do
    node = struct.root
    Enum.each(node, fn {name, hex} ->
  if c == 0, do: node.value
  if c < 0 do
    node = node.left
  else
    node = node.right
  end
end)
    nil
  end
  def remove(struct, key) do
    result = struct.removeLoop(key, struct.root)
    if result != nil, do: result.found
    false
  end
  def exists(struct, key) do
    node = struct.root
    Enum.each(node, fn {name, hex} ->
  cond do
    c == 0 -> true
    c < 0 -> node = node.left
    :true -> node = node.right
    :true -> :nil
  end
end)
    false
  end
  def iterator(struct) do
    ret = []
    struct.iteratorLoop(struct.root, ret)
    ArrayIterator.new(ret)
  end
  def key_value_iterator(struct) do
    MapKeyValueIterator.new(struct)
  end
  def keys(struct) do
    ret = []
    struct.keysLoop(struct.root, ret)
    ArrayIterator.new(ret)
  end
  def copy(struct) do
    copied = BalancedTree.new()
    root = struct.root
    copied
  end
  defp set_loop(struct, k, v, node) do
    if Kernel.is_nil(node) do
      TreeNode.new(nil, k, v, nil, -1)
    end
    c = struct.compare(k, node.key)
    cond do
      c == 0 -> TreeNode.new(node.left, k, v, node.right, node.get_height())
      c < 0 ->
        nl = struct.setLoop(k, v, node.left)
        struct.balance(nl, node.key, node.value, node.right)
      :true ->
        nr = struct.setLoop(k, v, node.right)
        struct.balance(node.left, node.key, node.value, nr)
      :true -> :nil
    end
  end
  defp remove_loop(struct, k, node) do
    if Kernel.is_nil(node), do: %{:node => nil, :found => false}
    c = struct.compare(k, node.key)
    cond do
      c == 0 -> %{:node => struct.merge(node.left, node.right), :found => true}
      c < 0 ->
        result = struct.removeLoop(k, node.left)
        if result != nil and result.found, do: %{:node => struct.balance(result.node, node.key, node.value, node.right), :found => true}
        %{:node => node, :found => false}
      :true ->
        result = struct.removeLoop(k, node.right)
        if result != nil and result.found, do: %{:node => struct.balance(node.left, node.key, node.value, result.node), :found => true}
        %{:node => node, :found => false}
      :true -> :nil
    end
  end
  defp iterator_loop(struct, node, acc) do
    if node != nil do
      struct.iteratorLoop(node.left, acc)
      %{struct | acc: struct.acc ++ [node.value]}
      struct.iteratorLoop(node.right, acc)
    end
  end
  defp keys_loop(struct, node, acc) do
    if node != nil do
      struct.keysLoop(node.left, acc)
      %{struct | acc: struct.acc ++ [node.key]}
      struct.keysLoop(node.right, acc)
    end
  end
  defp merge(struct, t1, t2) do
    if Kernel.is_nil(t1), do: t2
    if Kernel.is_nil(t2), do: t1
    t = struct.minBinding(t2)
    if Kernel.is_nil(t), do: t1
    struct.balance(t1, t.key, t.value, struct.removeMinBinding(t2))
  end
  defp min_binding(struct, t) do
    if Kernel.is_nil(t), do: nil
    if Kernel.is_nil(t.left), do: t
    struct.minBinding(t.left)
  end
  defp remove_min_binding(struct, t) do
    if Kernel.is_nil(t), do: nil
    if Kernel.is_nil(t.left), do: t.right
    struct.balance(struct.removeMinBinding(t.left), t.key, t.value, t.right)
  end
  defp balance(struct, l, k, v, r) do
    hl = l.get_height()
    hr = r.get_height()
    cond do
      hl > hr + 2 ->
        if l.left.get_height() >= l.right.get_height() do
          TreeNode.new(l.left, l.key, l.value, TreeNode.new(l.right, k, v, r, -1), -1)
        else
          TreeNode.new(TreeNode.new(l.left, l.key, l.value, l.right.left, -1), l.right.key, l.right.value, TreeNode.new(l.right.right, k, v, r, -1), -1)
        end
      hr > hl + 2 ->
        if r.right.get_height() > r.left.get_height() do
          TreeNode.new(TreeNode.new(l, k, v, r.left, -1), r.key, r.value, r.right, -1)
        else
          TreeNode.new(TreeNode.new(l, k, v, r.left.left, -1), r.left.key, r.left.value, TreeNode.new(r.left.right, r.key, r.value, r.right, -1), -1)
        end
      :true -> TreeNode.new(l, k, v, r, (if hl > hr, do: hl, else: hr) + 1)
      :true -> :nil
    end
  end
  defp compare(struct, k1, k2) do
    Reflect.compare(k1, k2)
  end
  def to_string(struct) do
    if Kernel.is_nil(struct.root) do
      "[]"
    else
      "[#{struct.root.toString()}]"
    end
  end
  def clear(struct) do
    root = nil
  end
end