defmodule Main do
  def main() do
    tree = SimpleTree.new(nil)
    tree.set("key1", "value1")
    tree.set("key2", "value2")
    value = tree.get("key1")
    Log.trace(value, %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "main"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()