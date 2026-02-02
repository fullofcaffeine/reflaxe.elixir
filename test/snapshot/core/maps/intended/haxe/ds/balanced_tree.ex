defmodule BalancedTree do
  def new() do
    %{:__reflaxe_class__ => BalancedTree, :root => nil}
  end
  def set(struct, key, value) do
    _ = %{struct | root: set_loop(struct, key, value, struct.root)}
  end
  def exists(struct, key) do
    node = struct.root
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {node}, fn _, {acc_node} ->
      try do
        if (not Kernel.is_nil(acc_node)) do
          c = compare(struct, key, acc_node.key)
          cond do
            c == 0 -> true
            c < 0 -> acc_node = acc_node.left
            :true -> acc_node = acc_node.right
          end
          {:cont, {acc_node}}
        else
          {:halt, {acc_node}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_node}}
        :throw, :continue ->
          {:cont, {acc_node}}
      end
    end)
    false
  end
  def keys(struct) do
    ret = []
    _ = keys_loop(struct, struct.root, ret)
    _ = ArrayIterator.new(ret)
  end
  defp set_loop(struct, k, v, node) do
    if (Kernel.is_nil(node)) do
      TreeNode.new(nil, k, v, nil, nil)
    else
      c = compare(struct, k, node.key)
      cond do
        c == 0 -> TreeNode.new(node.left, k, v, node.right, (if (Kernel.is_nil(node)), do: 0, else: node._height))
        c < 0 ->
          nl = set_loop(struct, k, v, node.left)
          _ = balance(struct, nl, node.key, node.value, node.right)
        :true ->
          nr = set_loop(struct, k, v, node.right)
          _ = balance(struct, node.left, node.key, node.value, nr)
      end
    end
  end
  defp keys_loop(struct, node, acc) do
    if (not Kernel.is_nil(node)) do
      _ = keys_loop(struct, node.left, acc)
      acc = acc ++ [node.key]
      _ = keys_loop(struct, node.right, acc)
    end
  end
  defp balance(_, l, k, v, r) do
    hl = if (Kernel.is_nil(l)), do: 0, else: l._height
    hr = if (Kernel.is_nil(r)), do: 0, else: r._height
    cond do
      hl > hr + 2 ->
        if ((fn ->
  this = l.left
  if (Kernel.is_nil(this)), do: 0, else: this._height
end).() >= (fn ->
  this = l.right
  if (Kernel.is_nil(this)), do: 0, else: this._height
end).()) do
          TreeNode.new(l.left, l.key, l.value, TreeNode.new(l.right, k, v, r, nil), nil)
        else
          TreeNode.new(TreeNode.new(l.left, l.key, l.value, l.right.left, nil), l.right.key, l.right.value, TreeNode.new(l.right.right, k, v, r, nil), nil)
        end
      hr > hl + 2 ->
        if ((fn ->
  this = r.right
  if (Kernel.is_nil(this)), do: 0, else: this._height
end).() > (fn ->
  this = r.left
  if (Kernel.is_nil(this)), do: 0, else: this._height
end).()) do
          TreeNode.new(TreeNode.new(l, k, v, r.left, nil), r.key, r.value, r.right, nil)
        else
          TreeNode.new(TreeNode.new(l, k, v, r.left.left, nil), r.left.key, r.left.value, TreeNode.new(r.left.right, r.key, r.value, r.right, nil), nil)
        end
      :true -> TreeNode.new(l, k, v, r, (if (hl > hr), do: hl, else: hr) + 1)
    end
  end
  defp compare(_, k1, k2) do
    Reflect.compare(k1, k2)
  end
end
