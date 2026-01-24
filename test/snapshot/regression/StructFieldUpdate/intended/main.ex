defmodule Main do
  def main() do
    tree = SimpleTree.new(nil)
    _ = apply(Map.get(tree, :__reflaxe_class__) || Map.get(tree, :__struct__), :set, [tree, "key1", "value1"])
    _ = apply(Map.get(tree, :__reflaxe_class__) || Map.get(tree, :__struct__), :set, [tree, "key2", "value2"])
    _value = apply(Map.get(tree, :__reflaxe_class__) || Map.get(tree, :__struct__), :get, [tree, "key1"])
    nil
  end
end
