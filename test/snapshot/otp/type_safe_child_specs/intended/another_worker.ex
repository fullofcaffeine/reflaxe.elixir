defmodule AnotherWorker do
  def new(config_param) do
    struct = %{:__reflaxe_class__ => AnotherWorker, :config => nil}
    struct = %{struct | config: config_param}
    struct
  end
  def start_link(_) do
    {"ok", "another_worker_pid"}
  end
end
