defmodule Main do
  def main() do
    test_arithmetic()
    test_comparisons()
    test_conversions()
    test_utility_methods()
    test_operators()
  end
  defp test_arithmetic() do
    Log.trace("=== Arithmetic Operations ===", %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "testArithmetic"})
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d = this1
    tomorrow = DateTime.add(d, 1, "day")
    Log.trace("Add 1 day: " <> Kernel.to_string(d.day) <> " -> " <> Kernel.to_string(tomorrow.day), %{:file_name => "Main.hx", :line_number => 25, :class_name => "Main", :method_name => "testArithmetic"})
    next_week = DateTime.add(d, 7, "day")
    Log.trace("Add 7 days: " <> Kernel.to_string(d.day) <> " -> " <> Kernel.to_string(next_week.day), %{:file_name => "Main.hx", :line_number => 28, :class_name => "Main", :method_name => "testArithmetic"})
    in_an_hour = DateTime.add(d, 1, "hour")
    Log.trace("Add 1 hour: " <> Kernel.to_string(d.hour) <> ":00 -> " <> Kernel.to_string(in_an_hour.hour) <> ":00", %{:file_name => "Main.hx", :line_number => 31, :class_name => "Main", :method_name => "testArithmetic"})
    in30_min = DateTime.add(d, 30, "minute")
    Log.trace("Add 30 minutes: " <> Kernel.to_string(d.minute) <> " min -> " <> Kernel.to_string(in30_min.minute) <> " min", %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "testArithmetic"})
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 1, 0, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d1 = this1
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 0, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d2 = this1
    days_diff = DateTime.diff(d2, d1, "day")
    Log.trace("Days between Jan 1 and Jan 15: " <> Kernel.to_string(days_diff), %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "testArithmetic"})
    hours_diff = DateTime.diff(d2, d1, "hour")
    Log.trace("Hours between Jan 1 and Jan 15: " <> Kernel.to_string(hours_diff), %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "testArithmetic"})
  end
  defp test_comparisons() do
    Log.trace("=== Comparison Methods ===", %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "testComparisons"})
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d1 = this1
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 16, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d2 = this1
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d3 = this1
    result1 = DateTime.compare(d1, d2)
    Log.trace("d1.compare(d2): " <> Kernel.to_string(result1), %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "testComparisons"})
    result2 = DateTime.compare(d2, d1)
    Log.trace("d2.compare(d1): " <> Kernel.to_string(result2), %{:file_name => "Main.hx", :line_number => 58, :class_name => "Main", :method_name => "testComparisons"})
    result3 = DateTime.compare(d1, d3)
    Log.trace("d1.compare(d3): " <> Kernel.to_string(result3), %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "testComparisons"})
    Log.trace("d1.isBefore(d2): " <> Std.string(DateTime.compare(d1, d2) == ":lt"), %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "testComparisons"})
    Log.trace("d2.isAfter(d1): " <> Std.string(DateTime.compare(d2, d1) == ":gt"), %{:file_name => "Main.hx", :line_number => 65, :class_name => "Main", :method_name => "testComparisons"})
    Log.trace("d1.isEqual(d3): " <> Std.string(DateTime.compare(d1, d3) == ":eq"), %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "testComparisons"})
  end
  defp test_conversions() do
    Log.trace("=== Conversion Methods ===", %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "testConversions"})
    this1 = nil
    elixir_month = 6
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 21, 14, 30, 45)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d = this1
    naive = DateTime.to_naive(d)
    Log.trace("Converted to NaiveDateTime", %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "testConversions"})
    _date_only = DateTime.to_date(d)
    Log.trace("Converted to Elixir Date (date only)", %{:file_name => "Main.hx", :line_number => 80, :class_name => "Main", :method_name => "testConversions"})
    from_naive = DateTime.from_naive!(naive, "Etc/UTC")
    Log.trace("Created Date from NaiveDateTime: " <> DateTime.to_iso8601(from_naive), %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "testConversions"})
  end
  defp test_utility_methods() do
    Log.trace("=== Utility Methods ===", %{:file_name => "Main.hx", :line_number => 88, :class_name => "Main", :method_name => "testUtilityMethods"})
    this1 = nil
    elixir_month = 3
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 14, 30, 45)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d = this1
    _truncated_to_min = DateTime.truncate(d, "second")
    Log.trace("Truncated to seconds: " <> Kernel.to_string(d.second) <> " -> clean seconds", %{:file_name => "Main.hx", :line_number => 94, :class_name => "Main", :method_name => "testUtilityMethods"})
    formatted = Calendar.strftime(d, "%Y-%m-%d %H:%M:%S")
    Log.trace("Formatted date: " <> formatted, %{:file_name => "Main.hx", :line_number => 98, :class_name => "Main", :method_name => "testUtilityMethods"})
    short_format = Calendar.strftime(d, "%b %d, %Y")
    Log.trace("Short format: " <> short_format, %{:file_name => "Main.hx", :line_number => 101, :class_name => "Main", :method_name => "testUtilityMethods"})
    start_of_day = 
            %DateTime{d | hour: 0, minute: 0, second: 0, microsecond: {0, 6}}
    Log.trace("Beginning of day: " <> Kernel.to_string(start_of_day.hour) <> ":" <> Kernel.to_string(start_of_day.minute) <> ":" <> Kernel.to_string(start_of_day.second), %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "testUtilityMethods"})
    end_of_day = 
            %DateTime{d | hour: 23, minute: 59, second: 59, microsecond: {999999, 6}}
    Log.trace("End of day: " <> Kernel.to_string(end_of_day.hour) <> ":" <> Kernel.to_string(end_of_day.minute) <> ":" <> Kernel.to_string(end_of_day.second), %{:file_name => "Main.hx", :line_number => 108, :class_name => "Main", :method_name => "testUtilityMethods"})
  end
  defp test_operators() do
    Log.trace("=== Operator Overloading ===", %{:file_name => "Main.hx", :line_number => 112, :class_name => "Main", :method_name => "testOperators"})
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d1 = this1
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 16, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d2 = this1
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d3 = this1
    Log.trace("d1 < d2: " <> Std.string(DateTime.compare(d1, d2) == ":lt"), %{:file_name => "Main.hx", :line_number => 119, :class_name => "Main", :method_name => "testOperators"})
    Log.trace("d1 > d2: " <> Std.string(DateTime.compare(d1, d2) == ":gt"), %{:file_name => "Main.hx", :line_number => 120, :class_name => "Main", :method_name => "testOperators"})
    result = DateTime.compare(d1, d3)
    Log.trace("d1 <= d3: " <> Std.string(result == ":lt" || result == ":eq"), %{:file_name => "Main.hx", :line_number => 121, :class_name => "Main", :method_name => "testOperators"})
    result = DateTime.compare(d1, d3)
    Log.trace("d1 >= d3: " <> Std.string(result == ":gt" || result == ":eq"), %{:file_name => "Main.hx", :line_number => 122, :class_name => "Main", :method_name => "testOperators"})
    Log.trace("d1 == d3: " <> Std.string(DateTime.compare(d1, d3) == ":eq"), %{:file_name => "Main.hx", :line_number => 123, :class_name => "Main", :method_name => "testOperators"})
    Log.trace("d1 != d2: " <> Std.string(DateTime.compare(d1, d2) != ":eq"), %{:file_name => "Main.hx", :line_number => 124, :class_name => "Main", :method_name => "testOperators"})
  end
end