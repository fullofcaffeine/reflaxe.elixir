defmodule Phoenix.LogLevel do
  def debug() do
    {:Debug}
  end
  def info() do
    {:Info}
  end
  def warning() do
    {:Warning}
  end
  def error() do
    {:Error}
  end
end