defmodule TodoApp.Application do
  def start(type, args) do
    app_name = "TodoApp"
    children = [TodoApp.Repo, {Phoenix.PubSub, [name: TodoApp.PubSub]}, TodoAppWeb.Telemetry, TodoAppWeb.Endpoint]
    opts = [strategy: :one_for_one, max_restarts: 3, max_seconds: 5]
    supervisor_result = Supervisor.start_link(children, opts)
    supervisor_result
  end
  def prep_stop(state) do
    state
  end
end