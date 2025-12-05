defmodule AnotherWorker do
  def start_link(_args) do
    {"ok", "another_worker_pid"}
  end
end
