defmodule TaskSupervisor do
  @config nil
  def start_link(_args) do
    {"ok", "task_supervisor_pid"}
  end
end