defmodule Elixir.Types.HandleCastResult do
  def no_reply(arg0) do
    {0, arg0}
  end
  def no_reply_timeout(arg0, arg1) do
    {1, arg0, arg1}
  end
  def no_reply_hibernate(arg0) do
    {2, arg0}
  end
  def no_reply_continue(arg0, arg1) do
    {3, arg0, arg1}
  end
  def stop(arg0, arg1) do
    {4, arg0, arg1}
  end
end
