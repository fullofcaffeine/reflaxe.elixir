defmodule TodoApp.Application do
  use Application
  def start(type, args) do
    children = [TodoApp.Repo, {Phoenix.PubSub, [name: TodoApp.PubSub]}, TodoAppWeb.Presence, TodoAppWeb.Telemetry, TodoAppWeb.Endpoint]
    Supervisor.start_link(children, SupervisorOptionsBuilder.defaults())
  end
  def prep_stop(state) do
    state
  end
end
