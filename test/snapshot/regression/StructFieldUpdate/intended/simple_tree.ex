defmodule SimpleTree do
  def set(struct, key, value) do
    root = insert_node(struct, struct.root, key, value)
    %{struct | root: root}
  end
  def get(struct, key) do
    find_node(struct, struct.root, key)
  end
  defp insert_node(struct, node, key, value) do
    if (Kernel.is_nil(node)) do
      TreeNode.new(key, value, nil, nil)
    else
      cond do
        key < node.key -> TreeNode.new(node.key, node.value, insert_node(struct, node.left, key, value), node.right)
        key > node.key -> TreeNode.new(node.key, node.value, node.left, insert_node(struct, node.right, key, value))
        :true -> TreeNode.new(key, value, node.left, node.right)
      end
    end
  end
  defp find_node(struct, node, key) do
    if (Kernel.is_nil(node)) do
      nil
    else
      cond do
        key < node.key -> find_node(struct, node.left, key)
        key > node.key -> find_node(struct, node.right, key)
        :true -> node.value
      end
    end
  end
end
