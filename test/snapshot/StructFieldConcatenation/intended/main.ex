defmodule Main do
  def main() do
    builder = TestBuilder.new("test")
    builder.add_item("item1", 42)
    builder.add_item("item2", 100)
    builder.remove_item("item1")
    Log.trace(builder.get_item_count(), %{:file_name => "Main.hx", :line_number => 20, :class_name => "Main", :method_name => "main"})
  end
end