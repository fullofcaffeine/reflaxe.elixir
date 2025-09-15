defmodule BalancedTree do
  defstruct root: nil

  def new() do
    %BalancedTree{root: nil}
  end

  def set(tree, key, value) do
    root = set_loop(tree, key, value, tree.root)
    %{tree | root: root}
  end

  def get(tree, key) do
    find_node(tree.root, key, &compare/2)
  end

  def remove(tree, key) do
    result = remove_loop(tree, key, tree.root)
    if result != nil, do: result.found, else: false
  end

  def exists(tree, key) do
    exists_node(tree.root, key, &compare/2)
  end

  def iterator(tree) do
    ret = iterator_loop(tree.root, [])
    ArrayIterator.new(ret)
  end

  def key_value_iterator(tree) do
    MapKeyValueIterator.new(tree)
  end

  def keys(tree) do
    ret = keys_loop(tree.root, [])
    ArrayIterator.new(ret)
  end

  def copy(tree) do
    # For immutable structures, copy can return the same tree
    # If deep copy is needed, traverse and rebuild
    %BalancedTree{root: copy_node(tree.root)}
  end

  # Private helper functions using idiomatic recursion

  defp find_node(nil, _key, _compare_fn), do: nil
  defp find_node(node, key, compare_fn) do
    case compare_fn.(key, node.key) do
      0 -> node.value
      x when x < 0 -> find_node(node.left, key, compare_fn)
      _ -> find_node(node.right, key, compare_fn)
    end
  end

  defp exists_node(nil, _key, _compare_fn), do: false
  defp exists_node(node, key, compare_fn) do
    case compare_fn.(key, node.key) do
      0 -> true
      x when x < 0 -> exists_node(node.left, key, compare_fn)
      _ -> exists_node(node.right, key, compare_fn)
    end
  end

  defp set_loop(_tree, k, v, nil) do
    TreeNode.new(nil, k, v, nil, 0)
  end

  defp set_loop(tree, k, v, node) do
    case compare(k, node.key) do
      0 ->
        TreeNode.new(node.left, k, v, node.right, node.height)
      x when x < 0 ->
        balance(set_loop(tree, k, v, node.left), node.key, node.value, node.right)
      _ ->
        balance(node.left, node.key, node.value, set_loop(tree, k, v, node.right))
    end
  end

  defp remove_loop(_tree, _k, nil) do
    %{node: nil, found: false}
  end

  defp remove_loop(tree, k, node) do
    case compare(k, node.key) do
      0 ->
        %{node: merge(tree, node.left, node.right), found: true}
      x when x < 0 ->
        result = remove_loop(tree, k, node.left)
        if result != nil and result.found do
          %{node: balance(result.node, node.key, node.value, node.right), found: true}
        else
          %{node: node, found: false}
        end
      _ ->
        result = remove_loop(tree, k, node.right)
        if result != nil and result.found do
          %{node: balance(node.left, node.key, node.value, result.node), found: true}
        else
          %{node: node, found: false}
        end
    end
  end

  defp iterator_loop(nil, acc), do: acc
  defp iterator_loop(node, acc) do
    acc = iterator_loop(node.left, acc)
    acc = acc ++ [node.value]
    iterator_loop(node.right, acc)
  end

  defp keys_loop(nil, acc), do: acc
  defp keys_loop(node, acc) do
    acc = keys_loop(node.left, acc)
    acc = acc ++ [node.key]
    keys_loop(node.right, acc)
  end

  defp copy_node(nil), do: nil
  defp copy_node(node) do
    TreeNode.new(
      copy_node(node.left),
      node.key,
      node.value,
      copy_node(node.right),
      node.height
    )
  end

  defp merge(_tree, nil, t2), do: t2
  defp merge(_tree, t1, nil), do: t1
  defp merge(tree, t1, t2) do
    case min_binding(t2) do
      nil -> t1
      t -> balance(t1, t.key, t.value, remove_min_binding(t2))
    end
  end

  defp min_binding(nil), do: nil
  defp min_binding(%{left: nil} = node), do: node
  defp min_binding(%{left: left}), do: min_binding(left)

  defp remove_min_binding(nil), do: nil
  defp remove_min_binding(%{left: nil, right: right}), do: right
  defp remove_min_binding(node) do
    balance(remove_min_binding(node.left), node.key, node.value, node.right)
  end

  defp balance(l, k, v, r) do
    hl = get_height(l)
    hr = get_height(r)

    cond do
      hl > hr + 2 ->
        if get_height(l.left) >= get_height(l.right) do
          TreeNode.new(l.left, l.key, l.value, TreeNode.new(l.right, k, v, r, 0), 0)
        else
          TreeNode.new(
            TreeNode.new(l.left, l.key, l.value, l.right.left, 0),
            l.right.key,
            l.right.value,
            TreeNode.new(l.right.right, k, v, r, 0),
            0
          )
        end

      hr > hl + 2 ->
        if get_height(r.right) > get_height(r.left) do
          TreeNode.new(TreeNode.new(l, k, v, r.left, 0), r.key, r.value, r.right, 0)
        else
          TreeNode.new(
            TreeNode.new(l, k, v, r.left.left, 0),
            r.left.key,
            r.left.value,
            TreeNode.new(r.left.right, r.key, r.value, r.right, 0),
            0
          )
        end

      true ->
        TreeNode.new(l, k, v, r, max(hl, hr) + 1)
    end
  end

  defp get_height(nil), do: 0
  defp get_height(node), do: node.height

  defp compare(k1, k2) do
    cond do
      k1 < k2 -> -1
      k1 > k2 -> 1
      true -> 0
    end
  end

  def to_string(nil), do: "[]"
  def to_string(%{root: nil}), do: "[]"
  def to_string(%{root: root}), do: "[#{node_to_string(root)}]"

  defp node_to_string(nil), do: ""
  defp node_to_string(node) do
    # In-order traversal for string representation
    left_str = if node.left, do: node_to_string(node.left) <> ", ", else: ""
    right_str = if node.right, do: ", " <> node_to_string(node.right), else: ""
    "#{left_str}#{node.key}=>#{node.value}#{right_str}"
  end

  def clear(_tree) do
    %BalancedTree{root: nil}
  end
end

defmodule TreeNode do
  defstruct [:left, :key, :value, :right, :height]

  def new(left, key, value, right, height) do
    actual_height = if height == 0 do
      max(get_height(left), get_height(right)) + 1
    else
      height
    end

    %TreeNode{
      left: left,
      key: key,
      value: value,
      right: right,
      height: actual_height
    }
  end

  defp get_height(nil), do: 0
  defp get_height(node), do: node.height

  defp max(a, b) when a > b, do: a
  defp max(_a, b), do: b
end