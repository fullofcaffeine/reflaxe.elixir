defmodule phoenix.HandleEventResult do
  def no_reply(arg0) do
    {:NoReply, arg0}
  end
  def reply(arg0, arg1) do
    {:Reply, arg0, arg1}
  end
  def error(arg0, arg1) do
    {:Error, arg0, arg1}
  end
end