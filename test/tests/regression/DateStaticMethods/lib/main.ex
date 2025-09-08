defmodule Main do
  def main() do
    current_date = Date.now()
    Log.trace("Current date created", %{:fileName => "Main.hx", :lineNumber => 5, :className => "Main", :methodName => "main"})
    timestamp = 1.6094592e+12
    _date_from_time = Date.from_time(timestamp)
    Log.trace("Date from timestamp created", %{:fileName => "Main.hx", :lineNumber => 10, :className => "Main", :methodName => "main"})
    date_string = "2021-01-01T00:00:00Z"
    _date_from_string = Date.from_string(date_string)
    Log.trace("Date from string created", %{:fileName => "Main.hx", :lineNumber => 15, :className => "Main", :methodName => "main"})
    year = current_date.year
    month = current_date.month - 1
    day = current_date.day
    hour = current_date.hour
    minute = current_date.minute
    second = current_date.second
    Log.trace("Year: " <> Kernel.to_string(year), %{:fileName => "Main.hx", :lineNumber => 25, :className => "Main", :methodName => "main"})
    Log.trace("Month: " <> Kernel.to_string(month), %{:fileName => "Main.hx", :lineNumber => 26, :className => "Main", :methodName => "main"})
    Log.trace("Day: " <> Kernel.to_string(day), %{:fileName => "Main.hx", :lineNumber => 27, :className => "Main", :methodName => "main"})
    Log.trace("Hour: " <> Kernel.to_string(hour), %{:fileName => "Main.hx", :lineNumber => 28, :className => "Main", :methodName => "main"})
    Log.trace("Minute: " <> Kernel.to_string(minute), %{:fileName => "Main.hx", :lineNumber => 29, :className => "Main", :methodName => "main"})
    Log.trace("Second: " <> Kernel.to_string(second), %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "main"})
    time = DateTime.to_unix(current_date, :millisecond)
    Log.trace("Time in milliseconds: " <> Kernel.to_string(time), %{:fileName => "Main.hx", :lineNumber => 34, :className => "Main", :methodName => "main"})
    date_str = DateTime.to_iso8601(current_date)
    Log.trace("Date string: " <> date_str, %{:fileName => "Main.hx", :lineNumber => 38, :className => "Main", :methodName => "main"})
  end
end