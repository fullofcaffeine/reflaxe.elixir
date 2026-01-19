defmodule Main do
  def main() do
    _now = DateTime.utc_now()
    _from_timestamp = Date_Impl_.from_time(1.23456789e+12)
    _from_string = "2024-01-01T12:00:00Z"
    elixir_month = 1
    specific_date = 
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 10, 30, 45)
            DateTime.from_naive!(naive, "Etc/UTC")
    _timestamp = specific_date
    _year = specific_date.year
    _month = (specific_date.month - 1)
    _day = specific_date.day
    date = DateTime.to_date(specific_date)
    dow = Date.day_of_week(date)
    _day_of_week = if (dow == 7), do: 0, else: dow
    _hours = specific_date.hour
    _minutes = specific_date.minute
    _seconds = specific_date.second
    _str = case specific_date do
  %NaiveDateTime{} = nd -> NaiveDateTime.to_iso8601(nd)
  %DateTime{} = dt -> DateTime.to_iso8601(dt)
  other -> Kernel.to_string(other)
end
    _utc_year = specific_date.year
    _utc_month = (specific_date.month - 1)
    _utc_day = specific_date.day
    _utc_hours = specific_date.hour
    nil
  end
end
