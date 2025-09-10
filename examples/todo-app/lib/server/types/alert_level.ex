defmodule Server.Types.AlertLevel do
  def info() do
    {0}
  end
  def warning() do
    {1}
  end
  def error() do
    {2}
  end
  def critical() do
    {3}
  end
end