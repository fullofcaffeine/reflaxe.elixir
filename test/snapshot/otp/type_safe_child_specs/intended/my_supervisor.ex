defmodule MySupervisor do
  @config nil
  def start_link(_args) do
    {"ok", "supervisor_pid"}
  end
end