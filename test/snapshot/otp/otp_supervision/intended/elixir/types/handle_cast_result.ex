defmodule Elixir.Types.HandleCastResult do
  def no_reply(arg0) do
    {:NoReply, arg0}
  end
  def no_reply_timeout(arg0, arg1) do
    {:NoReplyTimeout, arg0, arg1}
  end
  def no_reply_hibernate(arg0) do
    {:NoReplyHibernate, arg0}
  end
  def no_reply_continue(arg0, arg1) do
    {:NoReplyContinue, arg0, arg1}
  end
  def stop(arg0, arg1) do
    {:Stop, arg0, arg1}
  end
end