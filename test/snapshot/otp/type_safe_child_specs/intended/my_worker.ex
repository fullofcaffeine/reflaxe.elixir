defmodule MyWorker do
  def new(config_param) do
    struct = %{:config => nil}
    struct = %{struct | config: config_param}
    struct
  end
  def start_link(_) do
    {"ok", "worker_pid"}
  end
end
