defmodule ConsoleLogger do
  def new() do
    %{}
  end
  def log(_struct, message) do
    Log.trace("[LOG] " <> message, %{:fileName => "Storage.hx", :lineNumber => 103, :className => "ConsoleLogger", :methodName => "log"})
  end
  def debug(_struct, message) do
    Log.trace("[DEBUG] " <> message, %{:fileName => "Storage.hx", :lineNumber => 108, :className => "ConsoleLogger", :methodName => "debug"})
  end
end