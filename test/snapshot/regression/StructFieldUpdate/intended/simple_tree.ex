defmodule SimpleTree do
  def set(struct, key, value) do
    root = struct.insertNode(struct.root, key, value)
    %{struct | root: root}
  end
  def get(struct, key) do
    struct.findNode(struct.root, key)
  end
end
