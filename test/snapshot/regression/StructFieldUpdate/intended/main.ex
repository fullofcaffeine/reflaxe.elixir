defmodule Main do
  def main() do
    tree = SimpleTree.new(nil)
    _ = SimpleTree.set(tree, "key1", "value1")
    _ = SimpleTree.set(tree, "key2", "value2")
    _value = SimpleTree.get(tree, "key1")
    nil
  end
end
