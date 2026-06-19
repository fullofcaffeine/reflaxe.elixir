defmodule Main do
  def main() do
    epoch = Date_Impl_.from_time(0)
    elixir_month = 2
    _leap_feb = (
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 1, 0, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC"))
    _next_day = Date_Impl_.from_time(Reflaxe.Elixir.HaxeFloat.add(epoch, 86400000))
    built = DateTools.make(%{:ms => 123, :seconds => 2, :minutes => 3, :hours => 4, :days => 5})
    _parts = DateTools.parse(built)
    nil
  end
end
