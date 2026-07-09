defmodule Main do
  def main() do
    current_date = DateTime.utc_now()
    timestamp = 1.6094592e+12
    _date_from_time = DateTime.from_unix!(trunc(timestamp), :millisecond)
    date_string = "2021-01-01T00:00:00Z"
    reflaxe_date_string = date_string
    _date_from_string = (case reflaxe_date_string do
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
    _year = current_date.year
    _month = (current_date.month - 1)
    _day = current_date.day
    _hour = current_date.hour
    _minute = current_date.minute
    _second = current_date.second
    _time = DateTime.to_unix(current_date, :millisecond)
    _date_str = Calendar.strftime(current_date, "%Y-%m-%d %H:%M:%S")
    nil
  end
end
