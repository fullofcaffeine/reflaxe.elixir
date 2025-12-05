defmodule Elixir.Types.HandleCallResult do
  def reply(arg0, arg1) do
    {0, arg0, arg1}
  end
  def reply_timeout(arg0, arg1, arg2) do
    {1, arg0, arg1, arg2}
  end
  def reply_hibernate(arg0, arg1) do
    {2, arg0, arg1}
  end
  def reply_continue(arg0, arg1, arg2) do
    {3, arg0, arg1, arg2}
  end
  def no_reply(arg0) do
    {4, arg0}
  end
  def no_reply_timeout(arg0, arg1) do
    {5, arg0, arg1}
  end
  def no_reply_hibernate(arg0) do
    {6, arg0}
  end
  def no_reply_continue(arg0, arg1) do
    {7, arg0, arg1}
  end
  def stop_reply(arg0, arg1, arg2) do
    {8, arg0, arg1, arg2}
  end
  def stop(arg0, arg1) do
    {9, arg0, arg1}
  end
end
