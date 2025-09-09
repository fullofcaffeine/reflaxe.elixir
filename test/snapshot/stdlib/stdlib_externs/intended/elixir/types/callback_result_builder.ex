defmodule CallbackResultBuilder do
  def init_ok(state) do
    {:Ok, state}
  end
  def reply(reply, state) do
    {:Reply, reply, state}
  end
  def noreply(state) do
    {:NoReply, state}
  end
  def stop_normal(state) do
    {:Stop, :normal, state}
  end
  def stop_shutdown(state) do
    {:Stop, :shutdown, state}
  end
end