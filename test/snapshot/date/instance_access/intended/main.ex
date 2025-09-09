defmodule Main do
  def main() do
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 10, 30, 45)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d = this1
    obj = %{:y => d.year, :m => (d.month - 1), :dd => d.day, :dow => date = d.to_date()
dow = Date.day_of_week(date)
if (dow == 7), do: 0, else: dow, :hh => d.hour, :mm => d.minute, :ss => d.second}
    Log.trace(Std.string(obj), nil)
  end
end