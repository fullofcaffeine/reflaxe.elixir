defmodule Date_Impl_ do
  def now() do
    DateTime.utc_now()
  end
  def from_time(t) do
    DateTime.from_unix!(Std.int(t), :millisecond)
  end
  def from_string(s) do
    
            case DateTime.from_iso8601(s) do
                {:ok, dt, _} -> dt
                _ -> DateTime.utc_now()
            end
  end
  def _new(year, month, day, hour, min, sec) do
    elixir_month = month + 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(year, elixirMonth, day, hour, min, sec)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    this1
  end
  def get_time(this1) do
    DateTime.to_unix(this1, :millisecond)
  end
  def get_full_year(this1) do
    this1.year
  end
  def get_month(this1) do
    (this1.month - 1)
  end
  def get_date(this1) do
    this1.day
  end
  def get_day(this1) do
    date = DateTime.to_date(this1)
    dow = Date.day_of_week(date)
    temp_result = nil
    if (dow == 7) do
      temp_result = 0
    else
      temp_result = dow
    end
    tempResult
  end
  def get_hours(this1) do
    this1.hour
  end
  def get_minutes(this1) do
    this1.minute
  end
  def get_seconds(this1) do
    this1.second
  end
  def to_string(this1) do
    DateTime.to_iso8601(this1)
  end
  def get_utc_full_year(this1) do
    this1.year
  end
  def get_utc_month(this1) do
    (this1.month - 1)
  end
  def get_utc_date(this1) do
    this1.day
  end
  def get_utc_day(this1) do
    temp_result = nil
    date = DateTime.to_date(this1)
    dow = Date.day_of_week(date)
    if (dow == 7) do
      temp_result = 0
    else
      temp_result = dow
    end
    tempResult
  end
  def get_utc_hours(this1) do
    this1.hour
  end
  def get_utc_minutes(this1) do
    this1.minute
  end
  def get_utc_seconds(this1) do
    this1.second
  end
  def get_timezone_offset(this1) do
    0
  end
  def add(this1, amount, unit) do
    DateTime.add(this1, amount, unit)
  end
  def diff(this1, other, unit) do
    DateTime.diff(this1, other, unit)
  end
  def compare(this1, other) do
    DateTime.compare(this1, other)
  end
  def to_naive_date_time(this1) do
    DateTime.to_naive(this1)
  end
  def to_elixir_date(this1) do
    DateTime.to_date(this1)
  end
  def from_naive_date_time(dt) do
    DateTime.from_naive!(dt, "Etc/UTC")
  end
  def truncate(this1, precision) do
    DateTime.truncate(this1, precision)
  end
  def is_before(this1, other) do
    DateTime.compare(this1, other) == ":lt"
  end
  def is_after(this1, other) do
    DateTime.compare(this1, other) == ":gt"
  end
  def is_equal(this1, other) do
    DateTime.compare(this1, other) == ":eq"
  end
  def format(this1, format) do
    Calendar.strftime(this1, format)
  end
  def beginning_of_day(this1) do
    
            %DateTime{this1 | hour: 0, minute: 0, second: 0, microsecond: {0, 6}}
  end
  def end_of_day(this1) do
    
            %DateTime{this1 | hour: 23, minute: 59, second: 59, microsecond: {999999, 6}}
  end
  defp gt(a, b) do
    DateTime.compare(a, b) == ":gt"
  end
  defp lt(a, b) do
    DateTime.compare(a, b) == ":lt"
  end
  defp gte(a, b) do
    result = DateTime.compare(a, b)
    result == ":gt" || result == ":eq"
  end
  defp lte(a, b) do
    result = DateTime.compare(a, b)
    result == ":lt" || result == ":eq"
  end
  defp eq(a, b) do
    DateTime.compare(a, b) == ":eq"
  end
  defp neq(a, b) do
    DateTime.compare(a, b) != ":eq"
  end
end