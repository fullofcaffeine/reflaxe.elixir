defmodule Main do
  def main() do
    builder = TestBuilder.new("test")
    apply(Map.get(builder, :__reflaxe_class__) || Map.get(builder, :__struct__), :add_item, [builder, "item1", 42])
    apply(Map.get(builder, :__reflaxe_class__) || Map.get(builder, :__struct__), :add_item, [builder, "item2", 100])
    apply(Map.get(builder, :__reflaxe_class__) || Map.get(builder, :__struct__), :remove_item, [builder, "item1"])
    nil
  end
end
