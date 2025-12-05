defmodule SupervisorOptionsBuilder do
  def defaults() do
    [strategy: :one_for_one, max_restarts: 3, max_seconds: 5]
  end
  def with_strategy(_strategy) do
    [strategy: strategy, max_restarts: 3, max_seconds: 5]
  end
  def with_limits(_max_restarts, _max_seconds) do
    [strategy: :one_for_one, max_restarts: max_restarts, max_seconds: max_seconds]
  end
end
