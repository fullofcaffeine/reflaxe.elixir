defmodule Elixir.Types.HandleCallResult do
  def reply(arg0, arg1) do
    {:Reply, arg0, arg1}
  end
  def reply_timeout(arg0, arg1, arg2) do
    {:ReplyTimeout, arg0, arg1, arg2}
  end
  def reply_hibernate(arg0, arg1) do
    {:ReplyHibernate, arg0, arg1}
  end
  def reply_continue(arg0, arg1, arg2) do
    {:ReplyContinue, arg0, arg1, arg2}
  end
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
  def stop_reply(arg0, arg1, arg2) do
    {:StopReply, arg0, arg1, arg2}
  end
  def stop(arg0, arg1) do
    {:Stop, arg0, arg1}
  end
end