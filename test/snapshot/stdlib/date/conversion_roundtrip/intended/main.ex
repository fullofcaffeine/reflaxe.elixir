defmodule Main do
  def main() do
    d = DateTime.utc_now()
    iso = Calendar.strftime(d, "%Y-%m-%d %H:%M:%S")
    reflaxe_date_string = iso
    parsed = (case reflaxe_date_string do
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
    Log.trace(Reflaxe.Elixir.HaxeFloat.to_string(%{iso: iso, y: parsed.year, m: (parsed.month - 1), dd: parsed.day}), nil)
  end
end
