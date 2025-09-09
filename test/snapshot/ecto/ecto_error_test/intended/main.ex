defmodule Main do
  def main() do
    Log.trace("Ecto error validation test", %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "main"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()