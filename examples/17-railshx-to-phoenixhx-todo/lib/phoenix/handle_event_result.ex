defmodule Phoenix.HandleEventResult do
  def no_reply(arg0) do
    {:no_reply, arg0}
  end
  def reply(arg0, arg1) do
    {:reply, arg0, arg1}
  end
  def error(arg0, arg1) do
    {:error, arg0, arg1}
  end
end
