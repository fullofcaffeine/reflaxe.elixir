defmodule ApplicationSupervisor do
  use Supervisor
  def init(_struct, _args) do
    children = [Worker.child_spec(%{}), DatabaseConnection.child_spec(%{port: 5432})]
    opts = [strategy: :one_for_one, max_restarts: 3, max_seconds: 5]
    {:ok, {opts, children}}
  end
  def child_spec(args) do
    %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [args]},
          type: :supervisor,
          restart: :permanent,
          shutdown: :infinity
        }
  end
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end
end
