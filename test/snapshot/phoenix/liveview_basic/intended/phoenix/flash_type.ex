defmodule Phoenix.FlashType do
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
  def custom(arg0) do
    {4, arg0}
  end
end