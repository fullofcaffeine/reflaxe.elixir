defmodule MyWorker do
  def start_link(_args) do
    {"ok", "worker_pid"}
  end
end
