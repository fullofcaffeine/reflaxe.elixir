defmodule BackgroundWorker do
  def start_link(_args) do
    {"ok", "background_worker_pid"}
  end
end
