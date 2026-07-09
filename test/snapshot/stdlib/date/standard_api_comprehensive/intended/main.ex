defmodule Main do
  def main() do
    _ = test_constructors()
    _ = test_getters()
    _ = test_utc_methods()
    _ = test_conversions()
  end
  defp test_constructors() do
    elixir_month = 1
    _d1 = (
                {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 10, 30, 45)
                DateTime.from_naive!(naive, "Etc/UTC"))
    _now = DateTime.utc_now()
    timestamp = 1.7040672e+12
    _ = DateTime.from_unix!(trunc(timestamp), :millisecond)
    iso_string = "2024-03-15T14:30:00Z"
    reflaxe_date_string = iso_string
    _ = (case reflaxe_date_string do
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
    nil
  end
  defp test_getters() do
    elixir_month = 3
    d = (
                {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 14, 30, 45)
                DateTime.from_naive!(naive, "Etc/UTC"))
    _ms = DateTime.to_unix(d, :millisecond)
    nil
  end
  defp test_utc_methods() do
    elixir_month = 6
    _d = (
                {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 21, 8, 15, 30)
                DateTime.from_naive!(naive, "Etc/UTC"))
    nil
  end
  defp test_conversions() do
    elixir_month = 12
    _d = (
                {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 25, 0, 0, 0)
                DateTime.from_naive!(naive, "Etc/UTC"))
    elixir_month = 1
    _sunday = (
                {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 7, 0, 0, 0)
                DateTime.from_naive!(naive, "Etc/UTC"))
    elixir_month = 1
    _monday = (
                {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 8, 0, 0, 0)
                DateTime.from_naive!(naive, "Etc/UTC"))
    elixir_month = 7
    original = (
                {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 4, 12, 0, 0)
                DateTime.from_naive!(naive, "Etc/UTC"))
    timestamp = DateTime.to_unix(original, :millisecond)
    _restored = DateTime.from_unix!(trunc(timestamp), :millisecond)
    nil
  end
end
