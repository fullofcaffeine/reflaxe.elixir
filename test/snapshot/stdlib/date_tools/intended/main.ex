defmodule Main do
  def main() do
    elixir_month = 1
    monday = (
                {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 1, 12, 0, 0)
                DateTime.from_naive!(naive, "Etc/UTC"))
    elixir_month = 1
    sunday = (
                {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 7, 12, 0, 0)
                DateTime.from_naive!(naive, "Etc/UTC"))
    if (DateTools.format(monday, "%u") != "1") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "ISO Monday must be weekday 1"]
    end
    if (DateTools.format(sunday, "%u") != "7") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "ISO Sunday must be weekday 7"]
    end
    epoch = DateTime.from_unix!(trunc(0), :millisecond)
    elixir_month = 2
    _leap_feb = (
                {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 1, 0, 0, 0)
                DateTime.from_naive!(naive, "Etc/UTC"))
    _next_day = DateTime.from_unix!(trunc(Reflaxe.Elixir.HaxeFloat.add(DateTime.to_unix(epoch, :millisecond), 86400000)), :millisecond)
    built = DateTools.make(%{ms: 123, seconds: 2, minutes: 3, hours: 4, days: 5})
    _parts = DateTools.parse(built)
    nil
  end
end
