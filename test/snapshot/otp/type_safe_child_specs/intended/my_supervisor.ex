defmodule MySupervisor do
  def new(config) do
    %{:config => config}
  end
  def start_link(_args) do
    {"ok", "supervisor_pid"}
  end
end