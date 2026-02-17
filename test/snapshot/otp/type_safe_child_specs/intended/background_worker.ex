defmodule BackgroundWorker do
  def new(config_param) do
    struct = %{:__reflaxe_class__ => BackgroundWorker, :config => nil}
    struct = %{struct | config: config_param}
    struct
  end
  def start_link(_args) do
    {"ok", "background_worker_pid"}
  end
end
