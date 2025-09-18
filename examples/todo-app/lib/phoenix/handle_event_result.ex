defmodule Phoenix.HandleEventResult do
  def no_reply(arg0) do
    {0, arg0}
  end
  def reply(arg0, arg1) do
    {1, arg0, arg1}
  end
  def error(arg0, arg1) do
    {2, arg0, arg1}
  end
end