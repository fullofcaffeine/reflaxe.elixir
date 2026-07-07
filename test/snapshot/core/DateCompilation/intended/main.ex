defmodule Main do
  def main() do
    _now = DateTime.utc_now()
    _from_timestamp = DateTime.from_unix!(trunc(1.23456789e+12), :millisecond)
    reflaxe_date_string = "2024-01-01T12:00:00Z"
    _from_string = (case reflaxe_date_string do
  <<year::binary-size(4), "-", month::binary-size(2), "-", day::binary-size(2), " ", hour::binary-size(2), ":", minute::binary-size(2), ":", second::binary-size(2)>> ->
    {:ok, naive} = NaiveDateTime.new(
      String.to_integer(year),
      String.to_integer(month),
      String.to_integer(day),
      String.to_integer(hour),
      String.to_integer(minute),
      String.to_integer(second)
    )
    DateTime.from_naive!(naive, "Etc/UTC")
  <<year::binary-size(4), "-", month::binary-size(2), "-", day::binary-size(2)>> ->
    {:ok, naive} = NaiveDateTime.new(
      String.to_integer(year),
      String.to_integer(month),
      String.to_integer(day),
      String.to_integer("0"),
      String.to_integer("0"),
      String.to_integer("0")
    )
    DateTime.from_naive!(naive, "Etc/UTC")
  <<hour::binary-size(2), ":", minute::binary-size(2), ":", second::binary-size(2)>> ->
    {:ok, naive} = NaiveDateTime.new(
      1970,
      1,
      1,
      String.to_integer(hour),
      String.to_integer(minute),
      String.to_integer(second)
    )
    DateTime.from_naive!(naive, "Etc/UTC")
  _ ->
    case DateTime.from_iso8601(reflaxe_date_string) do
      {:ok, dt, _} -> dt
      _ -> raise ArgumentError, "Invalid date format: #{inspect(reflaxe_date_string)}"
    end
end)
    elixir_month = 1
    specific_date = (
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 10, 30, 45)
            DateTime.from_naive!(naive, "Etc/UTC"))
    _timestamp = DateTime.to_unix(specific_date, :millisecond)
    _year = specific_date.year
    _month = (specific_date.month - 1)
    _day = specific_date.day
    date = apply(Map.get(specific_date, :__reflaxe_class__) || Map.get(specific_date, :__struct__), :to_date, [specific_date])
    dow = Date.day_of_week(date)
    _day_of_week = if (dow == 7), do: 0, else: dow
    _hours = specific_date.hour
    _minutes = specific_date.minute
    _seconds = specific_date.second
    _str = Calendar.strftime(specific_date, "%Y-%m-%d %H:%M:%S")
    _utc_year = specific_date.year
    _utc_month = (specific_date.month - 1)
    _utc_day = specific_date.day
    _utc_hours = specific_date.hour
    _offset = (fn date_time ->
  case date_time do
    %DateTime{} = dt -> -div(dt.utc_offset + dt.std_offset, 60)
    _ -> String.to_integer("0")
  end
end).(specific_date)
    nil
  end
end
