defmodule BackgroundWorker do
  @config nil
  def start_link(_args) do
    {"ok", "background_worker_pid"}
  end
end