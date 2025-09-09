Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
defmodule Main do
  def main() do
    Log.trace("Hello inline deterministic!", nil)
  end
end
Main.main()
