defmodule Main do
  def main() do
    t = DateTime.to_unix(Date.now(), :millisecond)
    d2 = Date.from_time(t)
    t2 = DateTime.to_unix(d2, :millisecond)
    Log.trace(Std.string(%{:t => t, :t2 => t2}), nil)
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()