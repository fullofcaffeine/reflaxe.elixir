defmodule Main do
  def main() do
    builder = TestBuilder.new("test")
    _ = TestBuilder.add_item(builder, "item1", 42)
    _ = TestBuilder.add_item(builder, "item2", 100)
    _ = TestBuilder.remove_item(builder, "item1")
    nil
  end
end
