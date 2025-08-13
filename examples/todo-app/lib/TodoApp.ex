defmodule TodoApp.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # NOTE: This is a placeholder - proper compilation needs TypedExpr
    children = [
      TodoApp.Repo,
      TodoAppWeb.Telemetry,
      {Phoenix.PubSub, name: TodoApp.PubSub},
      TodoAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: TodoApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
