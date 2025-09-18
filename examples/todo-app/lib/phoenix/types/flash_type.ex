defmodule Phoenix.Types.FlashType do
  def info() do
    {0}
  end
  def success() do
    {1}
  end
  def warning() do
    {2}
  end
  def error() do
    {3}
  end
end