defmodule AnotherWorker do
  def start_link(args) do
    {"ok", "another_worker_pid"}
  end
end
