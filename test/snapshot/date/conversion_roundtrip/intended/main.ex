defmodule Main do
  def main() do
    d = Date.now()
    iso = d.to_string()
    parsed = Date.from_string(iso)
    Log.trace(Std.string(%{:iso => iso, :y => parsed.get_full_year(), :m => parsed.get_month(), :dd => parsed.get_date()}), nil)
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