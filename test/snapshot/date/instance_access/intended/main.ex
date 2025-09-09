defmodule Main do
  def main() do
    d = Date.new(2024, 0, 15, 10, 30, 45)
    obj = %{:y => d.get_full_year(), :m => d.get_month(), :dd => d.get_date(), :dow => (

            dow = Date.day_of_week(DateTime.to_date(d))
            if dow == 7, do: 0, else: dow
), :hh => d.get_hours(), :mm => d.get_minutes(), :ss => d.get_seconds()}
    Log.trace(Std.string(obj), nil)
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