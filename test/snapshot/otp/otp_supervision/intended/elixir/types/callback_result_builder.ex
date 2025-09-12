defmodule CallbackResultBuilder do
  def init_ok(state) do
    {:ok, state}
  end
  def reply(reply, state) do
    {:reply, reply, state}
  end
  def noreply(state) do
    {:no_reply, state}
  end
  def stop_normal(state) do
    {:stop, :normal, state}
  end
  def stop_shutdown(state) do
    {:stop, :shutdown, state}
  end
end