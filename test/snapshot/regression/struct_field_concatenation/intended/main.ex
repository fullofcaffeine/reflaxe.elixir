defmodule Main do
  def main() do
    builder = TestBuilder.new("test")
    _ = apply(Map.get(builder, :__reflaxe_class__) || Map.get(builder, :__struct__), :add_item, [builder, "item1", 42])
    _ = apply(Map.get(builder, :__reflaxe_class__) || Map.get(builder, :__struct__), :add_item, [builder, "item2", 100])
    _ = apply(Map.get(builder, :__reflaxe_class__) || Map.get(builder, :__struct__), :remove_item, [builder, "item1"])
    nil
  end
end
