defmodule Main do
  def main() do
    test_constructors()
    test_getters()
    test_u_t_c_methods()
    test_conversions()
  end
  defp test_constructors() do
    Log.trace("=== Constructor Tests ===", %{:file_name => "Main.hx", :line_number => 14, :class_name => "Main", :method_name => "testConstructors"})
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 10, 30, 45)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d1 = this1
    Log.trace("Constructor: year=" <> Kernel.to_string(d1.year) <> ", month=" <> Kernel.to_string(((d1.month - 1))) <> ", day=" <> Kernel.to_string(d1.day), %{:file_name => "Main.hx", :line_number => 18, :class_name => "Main", :method_name => "testConstructors"})
    Log.trace("Time: " <> Kernel.to_string(d1.hour) <> ":" <> Kernel.to_string(d1.minute) <> ":" <> Kernel.to_string(d1.second), %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "testConstructors"})
    now = DateTime.utc_now()
    Log.trace("Date.now() returned a date: " <> DateTime.to_iso8601(now), %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "testConstructors"})
    timestamp = 1.7040672e+12
    d2 = DateTime.from_unix!(Std.int(timestamp), "millisecond")
    Log.trace("fromTime(" <> Kernel.to_string(timestamp) <> "): " <> DateTime.to_iso8601(d2), %{:file_name => "Main.hx", :line_number => 28, :class_name => "Main", :method_name => "testConstructors"})
    iso_string = "2024-03-15T14:30:00Z"
    d3 = Date_Impl_.from_string(iso_string)
    Log.trace("fromString(\"" <> iso_string <> "\"): year=" <> Kernel.to_string(d3.year) <> ", month=" <> Kernel.to_string(((d3.month - 1))), %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testConstructors"})
  end
  defp test_getters() do
    Log.trace("=== Getter Tests ===", %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "testGetters"})
    this1 = nil
    elixir_month = 3
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 15, 14, 30, 45)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d = this1
    Log.trace("getFullYear(): " <> Kernel.to_string(d.year), %{:file_name => "Main.hx", :line_number => 42, :class_name => "Main", :method_name => "testGetters"})
    Log.trace("getMonth(): " <> Kernel.to_string(((d.month - 1))), %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "testGetters"})
    Log.trace("getDate(): " <> Kernel.to_string(d.day), %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "testGetters"})
    Log.trace("getHours(): " <> Kernel.to_string(d.hour), %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "testGetters"})
    Log.trace("getMinutes(): " <> Kernel.to_string(d.minute), %{:file_name => "Main.hx", :line_number => 46, :class_name => "Main", :method_name => "testGetters"})
    Log.trace("getSeconds(): " <> Kernel.to_string(d.second), %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "testGetters"})
    date = DateTime.to_date(d)
    dow = Date.day_of_week(date)
    Log.trace("getDay(): " <> Kernel.to_string((if dow == 7, do: 0, else: dow)), %{:file_name => "Main.hx", :line_number => 51, :class_name => "Main", :method_name => "testGetters"})
    ms = Date_Impl_.get_time(d)
    Log.trace("getTime(): " <> Kernel.to_string(ms) <> " milliseconds since epoch", %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "testGetters"})
    Log.trace("toString(): " <> DateTime.to_iso8601(d), %{:file_name => "Main.hx", :line_number => 58, :class_name => "Main", :method_name => "testGetters"})
  end
  defp test_utc_methods() do
    Log.trace("=== UTC Method Tests ===", %{:file_name => "Main.hx", :line_number => 62, :class_name => "Main", :method_name => "testUTCMethods"})
    this1 = nil
    elixir_month = 6
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 21, 8, 15, 30)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d = this1
    Log.trace("getUTCFullYear(): " <> Kernel.to_string(d.year), %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "testUTCMethods"})
    Log.trace("getUTCMonth(): " <> Kernel.to_string(((d.month - 1))), %{:file_name => "Main.hx", :line_number => 67, :class_name => "Main", :method_name => "testUTCMethods"})
    Log.trace("getUTCDate(): " <> Kernel.to_string(d.day), %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "testUTCMethods"})
    date = DateTime.to_date(d)
    dow = Date.day_of_week(date)
    Log.trace("getUTCDay(): " <> Kernel.to_string((if dow == 7, do: 0, else: dow)), %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "testUTCMethods"})
    Log.trace("getUTCHours(): " <> Kernel.to_string(d.hour), %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "testUTCMethods"})
    Log.trace("getUTCMinutes(): " <> Kernel.to_string(d.minute), %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "testUTCMethods"})
    Log.trace("getUTCSeconds(): " <> Kernel.to_string(d.second), %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "testUTCMethods"})
    Log.trace("getTimezoneOffset(): " <> Kernel.to_string(0), %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "testUTCMethods"})
  end
  defp test_conversions() do
    Log.trace("=== Conversion Tests ===", %{:file_name => "Main.hx", :line_number => 77, :class_name => "Main", :method_name => "testConversions"})
    this1 = nil
    elixir_month = 12
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 25, 0, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    d = this1
    Log.trace("December in Haxe (0-based): month=" <> Kernel.to_string(((d.month - 1))), %{:file_name => "Main.hx", :line_number => 81, :class_name => "Main", :method_name => "testConversions"})
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 7, 0, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    sunday = this1
    date = DateTime.to_date(sunday)
    dow = Date.day_of_week(date)
    Log.trace("Sunday getDay(): " <> Kernel.to_string((if dow == 7, do: 0, else: dow)), %{:file_name => "Main.hx", :line_number => 86, :class_name => "Main", :method_name => "testConversions"})
    this1 = nil
    elixir_month = 1
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 8, 0, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    monday = this1
    date = DateTime.to_date(monday)
    dow = Date.day_of_week(date)
    Log.trace("Monday getDay(): " <> Kernel.to_string((if dow == 7, do: 0, else: dow)), %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "testConversions"})
    this1 = nil
    elixir_month = 7
    this1 = (

            {:ok, naive} = NaiveDateTime.new(2024, elixir_month, 4, 12, 0, 0)
            DateTime.from_naive!(naive, "Etc/UTC")
)
    original = this1
    timestamp = Date_Impl_.get_time(original)
    restored = DateTime.from_unix!(Std.int(timestamp), "millisecond")
    Log.trace("Roundtrip test:", %{:file_name => "Main.hx", :line_number => 96, :class_name => "Main", :method_name => "testConversions"})
    Log.trace("  Original: " <> Kernel.to_string(original.year) <> "-" <> Kernel.to_string(((original.month - 1))) <> "-" <> Kernel.to_string(original.day), %{:file_name => "Main.hx", :line_number => 97, :class_name => "Main", :method_name => "testConversions"})
    Log.trace("  Restored: " <> Kernel.to_string(restored.year) <> "-" <> Kernel.to_string(((restored.month - 1))) <> "-" <> Kernel.to_string(restored.day), %{:file_name => "Main.hx", :line_number => 98, :class_name => "Main", :method_name => "testConversions"})
  end
end