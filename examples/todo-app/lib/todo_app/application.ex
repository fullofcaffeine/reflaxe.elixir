defmodule TodoApp.Application do
  use Application
  def start(type, args) do
    _app_name = "TodoApp"
    children = [{Registry, [name: :"Postgrex.TypeManager", keys: :duplicate]}, TodoApp.Repo, {Phoenix.PubSub, [name: :"TodoApp.PubSub"]}, TodoAppWeb.Telemetry, TodoAppWeb.Endpoint]
    opts = [strategy: :one_for_one, max_restarts: 3, max_seconds: 5]
    supervisor_result = Supervisor.start_link(children, opts)
    supervisor_result
  end
  def prep_stop(state) do
    state
  end
end