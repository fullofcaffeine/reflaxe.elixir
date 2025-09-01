defmodule BalancedTree do
  def new() do
    %{}
  end
  def set(struct, key, value) do
    root = struct.setLoop(key, value, struct.root)
  end
  def get(struct, key) do
    node = struct.root
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (node != nil) do
  c = struct.compare(key, node.key)
  if (c == 0), do: node.value
  if (c < 0) do
    node = node.left
  else
    node = node.right
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    nil
  end
  def remove(struct, key) do
    try do
      root = struct.removeLoop(key, struct.root)
      true
    rescue
      e ->
        false
    end
  end
  def exists(struct, key) do
    node = struct.root
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (node != nil) do
  c = struct.compare(key, node.key)
  if (c == 0) do
    true
  else
    if (c < 0) do
      node = node.left
    else
      node = node.right
    end
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    false
  end
  def iterator(struct) do
    ret = []
    BalancedTree.iterator_loop(struct.root, ret)
    ret.iterator()
  end
  def key_value_iterator(struct) do
    MapKeyValueIterator.new(struct)
  end
  def keys(struct) do
    ret = []
    struct.keysLoop(struct.root, ret)
    ret.iterator()
  end
  def copy(struct) do
    copied = BalancedTree.new()
    root = struct.root
    copied
  end
  defp set_loop(struct, k, v, node) do
    if (node == nil) do
      TreeNode.new(nil, k, v, nil)
    end
    c = struct.compare(k, node.key)
    if (c == 0) do
      TreeNode.new(node.left, k, v, node.right, (if (node == nil), do: 0, else: node._height))
    else
      if (c < 0) do
        nl = struct.setLoop(k, v, node.left)
        struct.balance(nl, node.key, node.value, node.right)
      else
        nr = struct.setLoop(k, v, node.right)
        struct.balance(node.left, node.key, node.value, nr)
      end
    end
  end
  defp remove_loop(struct, k, node) do
    if (node == nil) do
      throw("Not_found")
    end
    c = struct.compare(k, node.key)
    if (c == 0) do
      struct.merge(node.left, node.right)
    else
      if (c < 0) do
        struct.balance(struct.removeLoop(k, node.left), node.key, node.value, node.right)
      else
        struct.balance(node.left, node.key, node.value, struct.removeLoop(k, node.right))
      end
    end
  end
  defp keys_loop(struct, node, acc) do
    if (node != nil) do
      struct.keysLoop(node.left, acc)
      acc.push(node.key)
      struct.keysLoop(node.right, acc)
    end
  end
  defp merge(struct, t1, t2) do
    if (t1 == nil), do: t2
    if (t2 == nil), do: t1
    t = struct.minBinding(t2)
    struct.balance(t1, t.key, t.value, struct.removeMinBinding(t2))
  end
  defp min_binding(struct, t) do
    if (t == nil) do
      throw("Not_found")
    else
      if (t.left == nil), do: t, else: struct.minBinding(t.left)
    end
  end
  defp remove_min_binding(struct, t) do
    if (t.left == nil) do
      t.right
    else
      struct.balance(struct.removeMinBinding(t.left), t.key, t.value, t.right)
    end
  end
  defp balance(struct, l, k, v, r) do
    hl = if (l == nil), do: 0, else: l._height
    hr = if (r == nil), do: 0, else: r._height
    if (hl > hr + 2) do
      if (_this = l.left
if (_this == nil), do: 0, else: _this._height >= _this = l.right
if (_this == nil), do: 0, else: _this._height) do
        TreeNode.new(l.left, l.key, l.value, TreeNode.new(l.right, k, v, r))
      else
        TreeNode.new(TreeNode.new(l.left, l.key, l.value, l.right.left), l.right.key, l.right.value, TreeNode.new(l.right.right, k, v, r))
      end
    else
      if (hr > hl + 2) do
        if (_this = r.right
if (_this == nil), do: 0, else: _this._height > _this = r.left
if (_this == nil), do: 0, else: _this._height) do
          TreeNode.new(TreeNode.new(l, k, v, r.left), r.key, r.value, r.right)
        else
          TreeNode.new(TreeNode.new(l, k, v, r.left.left), r.left.key, r.left.value, TreeNode.new(r.left.right, r.key, r.value, r.right))
        end
      else
        TreeNode.new(l, k, v, r, (if (hl > hr), do: hl, else: hr) + 1)
      end
    end
  end
  defp compare(struct, k1, k2) do
    Reflect.compare(k1, k2)
  end
  def to_string(struct) do
    if (struct.root == nil), do: "[]", else: "[" + struct.root.toString() + "]"
  end
  def clear(struct) do
    root = nil
  end
  defp iterator_loop(node, acc) do
    if (node != nil) do
      BalancedTree.iterator_loop(node.left, acc)
      acc.push(node.value)
      BalancedTree.iterator_loop(node.right, acc)
    end
  end
end