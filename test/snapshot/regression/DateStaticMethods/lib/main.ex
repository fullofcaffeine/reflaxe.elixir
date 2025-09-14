defmodule Main do
  def main() do
    current_date = DateTime.utc_now()
    Log.trace("Current date created", %{:file_name => "Main.hx", :line_number => 5, :class_name => "Main", :method_name => "main"})
    timestamp = 1.6094592e+12
    _date_from_time = Date_Impl_.from_time(timestamp)
    Log.trace("Date from timestamp created", %{:file_name => "Main.hx", :line_number => 10, :class_name => "Main", :method_name => "main"})
    date_string = "2021-01-01T00:00:00Z"
    _date_from_string = Date_Impl_.from_string(date_string)
    Log.trace("Date from string created", %{:file_name => "Main.hx", :line_number => 15, :class_name => "Main", :method_name => "main"})
    year = current_date.year
    month = (current_date.month - 1)
    day = current_date.day
    hour = current_date.hour
    minute = current_date.minute
    second = current_date.second
    Log.trace("Year: " <> Kernel.to_string(year), %{:file_name => "Main.hx", :line_number => 25, :class_name => "Main", :method_name => "main"})
    Log.trace("Month: " <> Kernel.to_string(month), %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
    Log.trace("Day: " <> Kernel.to_string(day), %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "main"})
    Log.trace("Hour: " <> Kernel.to_string(hour), %{:file_name => "Main.hx", :line_number => 28, :class_name => "Main", :method_name => "main"})
    Log.trace("Minute: " <> Kernel.to_string(minute), %{:file_name => "Main.hx", :line_number => 29, :class_name => "Main", :method_name => "main"})
    Log.trace("Second: " <> Kernel.to_string(second), %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "main"})
    time = Date_Impl_.get_time(current_date)
    Log.trace("Time in milliseconds: " <> Kernel.to_string(time), %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "main"})
    date_str = DateTime.to_iso8601(current_date)
    Log.trace("Date string: " <> date_str, %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "main"})
  end
end