defmodule Main do
  def main() do
    test = PropertySetterTest.new()
    test.set_value(42)
    test.set_name("Test")
    if (test.value == 42 && test.name == "Test") do
      Log.trace("Property setters work correctly", %{:file_name => "Main.hx", :line_number => 42, :class_name => "Main", :method_name => "main"})
    end
    test.set_value(100)
    test.set_name("Updated")
    if (test.value == 100 && test.name == "Updated") do
      Log.trace("Chained property setters work", %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "main"})
    end
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()