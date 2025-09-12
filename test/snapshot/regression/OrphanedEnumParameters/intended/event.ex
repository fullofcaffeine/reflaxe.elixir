defmodule Event do
  def click(arg0, arg1) do
    {0, arg0, arg1}
  end
  def hover(arg0, arg1) do
    {1, arg0, arg1}
  end
  def key_press(arg0) do
    {2, arg0}
  end
end