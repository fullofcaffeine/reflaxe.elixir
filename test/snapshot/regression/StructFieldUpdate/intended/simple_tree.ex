defmodule SimpleTree do
  @root nil
  def set(struct, key, value) do
    root = struct.insert_node(struct.root, key, value)
    %{struct | root: root}
  end
  def get(struct, key) do
    struct.find_node(struct.root, key)
  end
  defp insert_node(struct, node, key, value) do
    if (node == nil) do
      TreeNode.new(key, value, nil, nil)
    end
    if (key < node.key) do
      TreeNode.new(node.key, node.value, struct.insert_node(node.left, key, value), node.right)
    else
      if (key > node.key) do
        TreeNode.new(node.key, node.value, node.left, struct.insert_node(node.right, key, value))
      else
        TreeNode.new(key, value, node.left, node.right)
      end
    end
  end
  defp find_node(struct, node, key) do
    if (node == nil), do: nil
    if (key < node.key) do
      struct.find_node(node.left, key)
    else
      if (key > node.key), do: struct.find_node(node.right, key), else: node.value
    end
  end
end