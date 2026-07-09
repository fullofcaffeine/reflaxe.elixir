defmodule Main do
  def main() do
    elixir_month = 1
    d = (
                {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 10, 30, 45)
                DateTime.from_naive!(naive, "Etc/UTC"))
    date = apply(Map.get(d, :__reflaxe_class__) || Map.get(d, :__struct__), :to_date, [d])
    dow = Date.day_of_week(date)
    obj = %{y: d.year, m: (d.month - 1), dd: d.day, dow: (if (dow == 7), do: 0, else: dow), hh: d.hour, mm: d.minute, ss: d.second}
    _ = Log.trace(Reflaxe.Elixir.HaxeFloat.to_string(obj), nil)
  end
end
