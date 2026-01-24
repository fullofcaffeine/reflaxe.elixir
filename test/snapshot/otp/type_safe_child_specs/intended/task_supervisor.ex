defmodule TaskSupervisor do
  def new(config_param) do
    struct = %{:__reflaxe_class__ => TaskSupervisor, :config => nil}
    struct = %{struct | config: config_param}
    struct
  end
  def start_link(_) do
    {"ok", "task_supervisor_pid"}
  end
end
