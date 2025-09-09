defmodule Main do
  def main() do
    Log.trace("Hello external bootstrap!", nil)
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()