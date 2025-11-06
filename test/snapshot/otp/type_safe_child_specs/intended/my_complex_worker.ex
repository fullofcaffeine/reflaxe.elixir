defmodule MyComplexWorker do
  def start_link(args) do
    {"ok", "complex_worker_pid"}
  end
end
