defmodule Color do
  def red() do
    {:Red}
  end
  def green() do
    {:Green}
  end
  def blue() do
    {:Blue}
  end
  def rgb(arg0, arg1, arg2) do
    {:RGB, arg0, arg1, arg2}
  end
end