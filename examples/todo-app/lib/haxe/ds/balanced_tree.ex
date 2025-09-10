defmodule BalancedTree do
  @root nil
  def set(_struct, _key, _value) do
    root = struct.set_loop(key, value, struct.root)
    %{struct | root: root}
  end
  def get(_struct, _key) do
    node = struct.root
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {node, :ok}, fn _, {acc_node, acc_state} ->
  if (acc_node != nil) do
    c = struct.compare(_key, acc_node.key)
    if (c == 0), do: acc_node.value
    nil
    {:cont, {acc_node, acc_state}}
  else
    {:halt, {acc_node, acc_state}}
  end
end)
    nil
  end
  def remove(_struct, _key) do
    result = struct.remove_loop(key, struct.root)
    if (result != nil), do: result.found
    false
  end
  def exists(_struct, _key) do
    node = struct.root
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {node, :ok}, fn _, {acc_node, acc_state} ->
  if (acc_node != nil) do
    c = struct.compare(_key, acc_node.key)
    if (c == 0), do: true, else: nil
    {:cont, {acc_node, acc_state}}
  else
    {:halt, {acc_node, acc_state}}
  end
end)
    false
  end
  def iterator(struct) do
    ret = []
    struct.iterator_loop(struct.root, ret)
    ArrayIterator.new(ret)
  end
  def key_value_iterator(struct) do
    MapKeyValueIterator.new(struct)
  end
  def keys(struct) do
    ret = []
    struct.keys_loop(struct.root, ret)
    ArrayIterator.new(ret)
  end
  def copy(_struct) do
    copied = BalancedTree.new()
    root = struct.root
    copied
  end
  defp set_loop(struct, k, v, node) do
    if (node == nil) do
      TreeNode.new(nil, k, v, nil, -1)
    end
    c = struct.compare(k, node.key)
    if (c == 0) do
      TreeNode.new(node.left, k, v, node.right, node.get_height())
    else
      if (c < 0) do
        struct.balance((struct.set_loop(k, v, node.left)), node.key, node.value, node.right)
      else
        struct.balance(node.left, node.key, node.value, (struct.set_loop(k, v, node.right)))
      end
    end
  end
  defp remove_loop(struct, _k, node) do
    if (node == nil), do: %{:node => nil, :found => false}
    c = struct.compare(k, node.key)
    if (c == 0) do
      %{:node => struct.merge(node.left, node.right), :found => true}
    else
      if (c < 0) do
        result = struct.remove_loop(k, node.left)
        if (result != nil && result.found), do: %{:node => struct.balance(result.node, node.key, node.value, node.right), :found => true}
        %{:node => node, :found => false}
      else
        result = struct.remove_loop(k, node.right)
        if (result != nil && result.found), do: %{:node => struct.balance(node.left, node.key, node.value, result.node), :found => true}
        %{:node => node, :found => false}
      end
    end
  end
  defp iterator_loop(struct, _node, acc) do
    if (node != nil) do
      struct.iterator_loop(node.left, acc)
      acc = acc ++ [node.value]
      struct.iterator_loop(node.right, acc)
    end
  end
  defp keys_loop(struct, _node, acc) do
    if (node != nil) do
      struct.keys_loop(node.left, acc)
      acc = acc ++ [node.key]
      struct.keys_loop(node.right, acc)
    end
  end
  defp merge(struct, t1, t2) do
    if (t1 == nil), do: t2
    if (t2 == nil), do: t1
    t = struct.min_binding(t2)
    if (t == nil), do: t1
    struct.balance(t1, t.key, t.value, struct.remove_min_binding(t2))
  end
  defp min_binding(struct, t) do
    if (t == nil), do: nil
    if (t.left == nil), do: t
    struct.min_binding(t.left)
  end
  defp remove_min_binding(struct, _t) do
    if (t == nil), do: nil
    if (t.left == nil), do: t.right
    struct.balance(struct.remove_min_binding(t.left), t.key, t.value, t.right)
  end
  defp balance(_struct, l, k, v, r) do
    hl = l.get_height()
    hr = r.get_height()
    if (hl > hr + 2) do
      if (l.left.get_height() >= l.right.get_height()) do
        TreeNode.new(l.left, l.key, l.value, TreeNode.new(l.right, k, v, r, -1), -1)
      else
        TreeNode.new(TreeNode.new(l.left, l.key, l.value, l.right.left, -1), l.right.key, l.right.value, TreeNode.new(l.right.right, k, v, r, -1), -1)
      end
    else
      if (hr > hl + 2) do
        if (r.right.get_height() > r.left.get_height()) do
          TreeNode.new(TreeNode.new(l, k, v, r.left, -1), r.key, r.value, r.right, -1)
        else
          TreeNode.new(TreeNode.new(l, k, v, r.left.left, -1), r.left.key, r.left.value, TreeNode.new(r.left.right, r.key, r.value, r.right, -1), -1)
        end
      else
        TreeNode.new(l, k, v, r, (if (hl > hr), do: hl, else: hr) + 1)
      end
    end
  end
  defp compare(_struct, _k1, _k2) do
    cond do
      k1 < k2 ->
        -1
      k1 > k2 ->
        1
      true ->
        0
    end
  end
  def to_string(_struct) do
    if (struct.root == nil), do: "[]", else: "[" <> struct.root.to_string() <> "]"
  end
  def clear(_struct) do
    nil
  end
end