defmodule ConsoleLogger do
  def log(struct, message) do
    Log.trace("[LOG] " <> message, %{:file_name => "Storage.hx", :line_number => 103, :class_name => "ConsoleLogger", :method_name => "log"})
  end
  def debug(struct, message) do
    Log.trace("[DEBUG] " <> message, %{:file_name => "Storage.hx", :line_number => 108, :class_name => "ConsoleLogger", :method_name => "debug"})
  end
end