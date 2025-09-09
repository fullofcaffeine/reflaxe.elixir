defmodule AnotherWorker do
  @config nil
  def start_link(_args) do
    {"ok", "another_worker_pid"}
  end
end