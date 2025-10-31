defmodule Phoenix.FlashType do
  def info() do
    {:info}
  end
  def success() do
    {:success}
  end
  def warning() do
    {:warning}
  end
  def error() do
    {:error}
  end
  def custom(arg0) do
    {:custom, arg0}
  end
end
