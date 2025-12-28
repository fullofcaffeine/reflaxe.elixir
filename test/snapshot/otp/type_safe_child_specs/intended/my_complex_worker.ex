defmodule MyComplexWorker do
  def new(config_param) do
    struct = %{:config => nil}
    struct = %{struct | config: config_param}
    struct
  end
  def start_link(_) do
    {"ok", "complex_worker_pid"}
  end
end
