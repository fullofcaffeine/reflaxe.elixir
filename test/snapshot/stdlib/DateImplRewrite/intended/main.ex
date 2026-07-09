defmodule Main do
  def main() do

  end
  def test_utc_now() do
    DateTime.to_iso8601(DateTime.utc_now())
  end
  def passthrough(s) do
    reflaxe_date_string = s
    this1 = (case reflaxe_date_string do
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
    Calendar.strftime(this1, "%Y-%m-%d %H:%M:%S")
  end
end
