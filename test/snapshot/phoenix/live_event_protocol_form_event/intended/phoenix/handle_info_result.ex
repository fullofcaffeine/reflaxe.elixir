defmodule Phoenix.HandleInfoResult do
  def no_reply(arg0) do
    {:no_reply, arg0}
  end
  def error(arg0, arg1) do
    {:error, arg0, arg1}
  end
end
