defmodule MyApp.Application do
  use Application
  def start(_type, _args) do
    options = [strategy: :one_for_one, max_restarts: 3, max_seconds: 5]
    _ = Supervisor.start_link([], options)
  end
  def prep_stop(state) do
    state
  end
end
