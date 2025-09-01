defmodule SupervisorOptionsBuilder do
  def defaults() do
    [strategy: :one_for_one, max_restarts: 3, max_seconds: 5]
  end
  def with_strategy(strategy) do
    opts = defaults()
    strategy = strategy
    opts
  end
  def with_limits(max_restarts, max_seconds) do
    opts = defaults()
    max_restarts = max_restarts
    max_seconds = max_seconds
    opts
  end
end