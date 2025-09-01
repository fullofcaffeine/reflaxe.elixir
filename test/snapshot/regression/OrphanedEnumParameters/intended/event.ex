defmodule Event do
  def click(arg0, arg1) do
    {:Click, arg0, arg1}
  end
  def hover(arg0, arg1) do
    {:Hover, arg0, arg1}
  end
  def key_press(arg0) do
    {:KeyPress, arg0}
  end
end