defmodule BalancedTree do
  def set(struct, key, value) do
    root = struct.set_loop(key, value, struct.root)
    %{struct | root: root}
  end
  def get(struct, key) do
    node = struct.root
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {node, :ok}, fn _, {acc_node, acc_state} ->
  if (acc_node != nil) do
    c = struct.compare(key, acc_node.key)
    if (c == 0), do: acc_node.value
    nil
    {:cont, {acc_node, acc_state}}
  else
    {:halt, {acc_node, acc_state}}
  end
end)
    nil
  end
  def remove(struct, key) do
    result = struct.remove_loop(key, struct.root)
    if (result != nil), do: result.found
    false
  end
  def exists(struct, key) do
    node = struct.root
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {node, :ok}, fn _, {acc_node, acc_state} ->
  if (acc_node != nil) do
    c = struct.compare(key, acc_node.key)
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
  def copy(struct) do
    copied = BalancedTree.new()
    root = struct.root
    copied
  end
  defp set_loop(struct, k, v, node) do
    if (node == nil) do
      TreeNode.new(nil, k, v, nil, -1)
    end
    c = struct.compare(k, node.key)
    temp_result = nil
    if (c == 0) do
      temp_result = TreeNode.new(node.left, k, v, node.right, node.get_height())
    else
      if (c < 0) do
        nl = struct.set_loop(k, v, node.left)
        temp_result = struct.balance(nl, node.key, node.value, node.right)
      else
        nr = struct.set_loop(k, v, node.right)
        temp_result = struct.balance(node.left, node.key, node.value, nr)
      end
    end
    temp_result
  end
  defp remove_loop(struct, k, node) do
    if (node == nil), do: %{:node => nil, :found => false}
    c = struct.compare(k, node.key)
    if (c == 0) do
      %{:node => struct.merge(node.left, node.right), :found => true}
    else
      if (c < 0) do
        result = struct.remove_loop(k, node.left)
        if (result != nil and result.found), do: %{:node => struct.balance(result.node, node.key, node.value, node.right), :found => true}
        %{:node => node, :found => false}
      else
        result = struct.remove_loop(k, node.right)
        if (result != nil and result.found), do: %{:node => struct.balance(node.left, node.key, node.value, result.node), :found => true}
        %{:node => node, :found => false}
      end
    end
  end
  defp iterator_loop(struct, node, acc) do
    if (node != nil) do
      struct.iterator_loop(node.left, acc)
      acc = acc ++ [node.value]
      struct.iterator_loop(node.right, acc)
    end
  end
  defp keys_loop(struct, node, acc) do
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
  defp remove_min_binding(struct, t) do
    if (t == nil), do: nil
    if (t.left == nil), do: t.right
    struct.balance(struct.remove_min_binding(t.left), t.key, t.value, t.right)
  end
  defp balance(struct, l, k, v, r) do
    hl = l.get_height()
    hr = r.get_height()
    temp_result = nil
    if (hl > hr + 2) do
      if (l.left.get_height() >= l.right.get_height()) do
        temp_result = TreeNode.new(l.left, l.key, l.value, TreeNode.new(l.right, k, v, r, -1), -1)
      else
        temp_result = TreeNode.new(TreeNode.new(l.left, l.key, l.value, l.right.left, -1), l.right.key, l.right.value, TreeNode.new(l.right.right, k, v, r, -1), -1)
      end
    else
      if (hr > hl + 2) do
        if (r.right.get_height() > r.left.get_height()) do
          temp_result = TreeNode.new(TreeNode.new(l, k, v, r.left, -1), r.key, r.value, r.right, -1)
        else
          temp_result = TreeNode.new(TreeNode.new(l, k, v, r.left.left, -1), r.left.key, r.left.value, TreeNode.new(r.left.right, r.key, r.value, r.right, -1), -1)
        end
      else
        temp_number = nil
        if (hl > hr) do
          temp_number = hl
        else
          temp_number = hr
        end
        temp_result = TreeNode.new(l, k, v, r, (temp_number) + 1)
      end
    end
    temp_result
  end
  defp compare(struct, k1, k2) do
    cond do
      k1 < k2 ->
        -1
      k1 > k2 ->
        1
      true ->
        0
    end
  end
  def to_string(struct) do
    temp_result = nil
    if (struct.root == nil) do
      temp_result = "[]"
    else
      temp_result = "[" <> struct.root.to_string() <> "]"
    end
    temp_result
  end
  def clear(struct) do
    root = nil
  end
end