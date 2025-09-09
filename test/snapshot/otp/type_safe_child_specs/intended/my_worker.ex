defmodule MyWorker do
  @config nil
  def start_link(_args) do
    {"ok", "worker_pid"}
  end
end