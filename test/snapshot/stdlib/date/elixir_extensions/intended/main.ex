defmodule Main do
  def main() do
    _ = test_arithmetic()
    _ = test_comparisons()
    _ = test_conversions()
    _ = test_utility_methods()
    _ = test_operators()
  end
  defp test_arithmetic() do
    elixir_month = 1
    d = 
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
    _tomorrow = DateTime.add(d, 1, :day)
    _next_week = DateTime.add(d, 7, :day)
    _in_an_hour = DateTime.add(d, 1, :hour)
    _in30_min = DateTime.add(d, 30, :minute)
    elixir_month = 1
    _ = 
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 1, 0, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
    elixir_month = 1
    _ = 
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 0, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
    _days_diff = DateTime.diff(d_value, d_entry, :day)
    _hours_diff = DateTime.diff(d_value, d_entry, :hour)
    nil
  end
  defp test_comparisons() do
    elixir_month = 1
    d1 = 
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
    elixir_month = 1
    d2 = 
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 16, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
    elixir_month = 1
    d3 = 
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
    _ = DateTime.compare(d1, d2)
    _ = DateTime.compare(d2, d1)
    _ = DateTime.compare(d1, d3)
    nil
  end
  defp test_conversions() do
    elixir_month = 6
    d = 
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 21, 14, 30, 45)
            DateTime.from_naive!(naive, "Etc/UTC")
    naive = DateTime.to_naive(d)
    _date_only = DateTime.to_date(d)
    _from_naive = DateTime.from_naive!(naive, "Etc/UTC")
    nil
  end
  defp test_utility_methods() do
    elixir_month = 3
    d = 
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 14, 30, 45)
            DateTime.from_naive!(naive, "Etc/UTC")
    _truncated_to_min = DateTime.truncate(d, :second)
    _formatted = Calendar.strftime(d, "%Y-%m-%d %H:%M:%S")
    _short_format = Calendar.strftime(d, "%b %d, %Y")
    _start_of_day = 
            %DateTime{d | hour: 0, minute: 0, second: 0, microsecond: {0, 6}}
    _end_of_day = 
            %DateTime{d | hour: 23, minute: 59, second: 59, microsecond: {999999, 6}}
    nil
  end
  defp test_operators() do
    elixir_month = 1
    _d1 = 
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
    elixir_month = 1
    _d2 = 
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 16, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
    elixir_month = 1
    _d3 = 
            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
    nil
  end
end
