defmodule Date_Impl_ do
  def now() do
    DateTime.utc_now()
  end
  def from_time(_t) do
    DateTime.from_unix!(Std.int(t), "millisecond")
  end
  def from_string(_s) do
    
            case DateTime.from_iso8601(s) do
                {:ok, dt, _} -> dt
                _ -> DateTime.utc_now()
            end
  end
  def _new(_year, _month, _day, _hour, _min, _sec) do
    elixir_month = month + 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(year, elixir_month, day, hour, min, sec)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    this1
  end
  def get_time(_this1) do
    DateTime.to_unix(this1, "millisecond")
  end
  def get_full_year(_this1) do
    this1.year
  end
  def get_month(_this1) do
    (this1.month - 1)
  end
  def get_date(_this1) do
    this1.day
  end
  def get_day(_this1) do
    date = DateTime.to_date(this1)
    dow = Date.day_of_week(date)
    if (dow == 7), do: 0, else: dow
  end
  def get_hours(_this1) do
    this1.hour
  end
  def get_minutes(_this1) do
    this1.minute
  end
  def get_seconds(_this1) do
    this1.second
  end
  def to_string(_this1) do
    DateTime.to_iso8601(this1)
  end
  def get_utc_full_year(_this1) do
    this1.year
  end
  def get_utc_month(_this1) do
    (this1.month - 1)
  end
  def get_utc_date(_this1) do
    this1.day
  end
  def get_utc_day(_this1) do
    date = DateTime.to_date(this1)
    dow = Date.day_of_week(date)
    if (dow == 7), do: 0, else: dow
  end
  def get_utc_hours(_this1) do
    this1.hour
  end
  def get_utc_minutes(_this1) do
    this1.minute
  end
  def get_utc_seconds(_this1) do
    this1.second
  end
  def get_timezone_offset(_this1) do
    0
  end
  def add(_this1, _amount, _unit) do
    DateTime.add(this1, amount, unit)
  end
  def diff(_this1, _other, _unit) do
    DateTime.diff(this1, other, unit)
  end
  def compare(_this1, _other) do
    DateTime.compare(this1, other)
  end
  def to_naive_date_time(_this1) do
    DateTime.to_naive(this1)
  end
  def to_elixir_date(_this1) do
    DateTime.to_date(this1)
  end
  def from_naive_date_time(_dt) do
    DateTime.from_naive!(dt, "Etc/UTC")
  end
  def truncate(_this1, _precision) do
    DateTime.truncate(this1, precision)
  end
  def is_before(_this1, _other) do
    DateTime.compare(this1, other) == ":lt"
  end
  def is_after(_this1, _other) do
    DateTime.compare(this1, other) == ":gt"
  end
  def is_equal(_this1, _other) do
    DateTime.compare(this1, other) == ":eq"
  end
  def format(_this1, _format) do
    Calendar.strftime(this1, format)
  end
  def beginning_of_day(_this1) do
    
            %DateTime{this1 | hour: 0, minute: 0, second: 0, microsecond: {0, 6}}
  end
  def end_of_day(_this1) do
    
            %DateTime{this1 | hour: 23, minute: 59, second: 59, microsecond: {999999, 6}}
  end
  defp gt(_a, _b) do
    DateTime.compare(a, b) == ":gt"
  end
  defp lt(_a, _b) do
    DateTime.compare(a, b) == ":lt"
  end
  defp gte(_a, _b) do
    result = DateTime.compare(a, b)
    result == ":gt" || result == ":eq"
  end
  defp lte(_a, _b) do
    result = DateTime.compare(a, b)
    result == ":lt" || result == ":eq"
  end
  defp eq(_a, _b) do
    DateTime.compare(a, b) == ":eq"
  end
  defp neq(_a, _b) do
    DateTime.compare(a, b) != ":eq"
  end
end