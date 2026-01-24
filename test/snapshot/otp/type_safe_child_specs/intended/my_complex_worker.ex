defmodule MyComplexWorker do
  def new(config_param) do
    struct = %{:__reflaxe_class__ => MyComplexWorker, :config => nil}
    struct = %{struct | config: config_param}
    struct
  end
  def start_link(_) do
    {"ok", "complex_worker_pid"}
  end
end
