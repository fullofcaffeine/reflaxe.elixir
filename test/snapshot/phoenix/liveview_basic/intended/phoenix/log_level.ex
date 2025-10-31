defmodule Phoenix.LogLevel do
  def debug() do
    {:debug}
  end
  def info() do
    {:info}
  end
  def warning() do
    {:warning}
  end
  def error() do
    {:error}
  end
end
