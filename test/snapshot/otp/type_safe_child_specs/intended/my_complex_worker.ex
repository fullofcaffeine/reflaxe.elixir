defmodule MyComplexWorker do
  def new(config) do
    %{:config => config}
  end
  def start_link(_args) do
    {"ok", "complex_worker_pid"}
  end
end