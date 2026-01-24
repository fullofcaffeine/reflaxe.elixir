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
    _ = Date_Impl_.from_time(timestamp)
    iso_string = "2024-03-15T14:30:00Z"
    _ = iso_string
    nil
  end
  defp test_getters() do
    elixir_month = 3
    d = (
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 14, 30, 45)
            DateTime.from_naive!(naive, "Etc/UTC"))
    _ms = d
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
    timestamp = original
    _restored = Date_Impl_.from_time(timestamp)
    nil
  end
end
