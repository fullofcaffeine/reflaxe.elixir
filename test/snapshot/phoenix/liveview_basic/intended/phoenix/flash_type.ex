defmodule phoenix.FlashType do
  def info() do
    {:Info}
  end
  def success() do
    {:Success}
  end
  def warning() do
    {:Warning}
  end
  def error() do
    {:Error}
  end
  def custom(arg0) do
    {:Custom, arg0}
  end
end