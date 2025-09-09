defmodule Main do
  def main() do
    x = 42
    _y = 3.14
    _s = "Hello, AST!"
    b = true
    sum = x + 10
    _product = x * 2
    _comparison = x > 20
    if b do
      Log.trace("Boolean is true", %{:file_name => "Main.hx", :line_number => 16, :class_name => "Main", :method_name => "main"})
    else
      Log.trace("Boolean is false", %{:file_name => "Main.hx", :line_number => 18, :class_name => "Main", :method_name => "main"})
    end
    Log.trace("Sum: " <> Kernel.to_string(sum), %{:file_name => "Main.hx", :line_number => 22, :class_name => "Main", :method_name => "main"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()