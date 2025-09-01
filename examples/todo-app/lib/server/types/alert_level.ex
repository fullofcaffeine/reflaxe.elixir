defmodule Server.Types.AlertLevel do
  def info() do
    {:Info}
  end
  def warning() do
    {:Warning}
  end
  def error() do
    {:Error}
  end
  def critical() do
    {:Critical}
  end
end