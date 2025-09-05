defmodule MySupervisor do
  def new(config) do
    %{:config => config}
  end
  def start_link(_args) do
    %{:_0 => "ok", :_1 => "supervisor_pid"}
  end
end