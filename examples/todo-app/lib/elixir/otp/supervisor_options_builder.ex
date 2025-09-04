defmodule SupervisorOptionsBuilder do
  def defaults() do
    [strategy: :one_for_one, max_restarts: 3, max_seconds: 5]
  end
  def with_strategy(strategy) do
    [strategy: strategy, max_restarts: 3, max_seconds: 5]
  end
  def with_limits(max_restarts, max_seconds) do
    [strategy: :one_for_one, max_restarts: max_restarts, max_seconds: max_seconds]
  end
end