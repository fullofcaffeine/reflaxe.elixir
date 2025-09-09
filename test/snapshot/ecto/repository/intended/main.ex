defmodule Main do
  def main() do
    Log.trace("Repository pattern compilation test complete!", %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "main"})
  end
end

Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("std.ex", __DIR__)
Code.require_file("sys.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()