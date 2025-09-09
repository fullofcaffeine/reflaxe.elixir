defmodule Main do
  def main() do
    meta = %{:online_at => DateTime.to_unix(Date.now(), :millisecond), :user_name => "alice", :avatar => nil}
    Log.trace(Std.string(meta), nil)
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