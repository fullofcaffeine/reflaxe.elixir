defmodule MyComplexWorker do
  def start_link(_args) do
    {"ok", "complex_worker_pid"}
  end
end
