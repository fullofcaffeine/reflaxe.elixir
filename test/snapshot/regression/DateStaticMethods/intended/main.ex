defmodule Main do
  def main() do
    current_date = DateTime.utc_now()
    timestamp = 1.6094592e+12
    _date_from_time = Date_Impl_.from_time(timestamp)
    date_string = "2021-01-01T00:00:00Z"
    _date_from_string = date_string
    _year = current_date.year
    _month = (current_date.month - 1)
    _day = current_date.day
    _hour = current_date.hour
    _minute = current_date.minute
    _second = current_date.second
    _time = current_date
    _date_str = (case current_date do
  %NaiveDateTime{} = nd -> NaiveDateTime.to_iso8601(nd)
  %DateTime{} = dt -> DateTime.to_iso8601(dt)
  other -> Kernel.to_string(other)
end)
    nil
  end
end
