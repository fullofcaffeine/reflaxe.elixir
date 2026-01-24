defmodule MySupervisor do
  def new(config_param) do
    struct = %{:__reflaxe_class__ => MySupervisor, :config => nil}
    struct = %{struct | config: config_param}
    struct
  end
  def start_link(_) do
    {"ok", "supervisor_pid"}
  end
end
