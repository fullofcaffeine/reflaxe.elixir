defmodule SupervisorOptionsBuilder do
  def defaults() do
    %{:strategy => :OneForOne, :max_restarts => 3, :max_seconds => 5}
  end
  def withStrategy(strategy) do
    opts = SupervisorOptionsBuilder.defaults()
    strategy = strategy
    opts
  end
  def withLimits(max_restarts, max_seconds) do
    opts = SupervisorOptionsBuilder.defaults()
    max_restarts = max_restarts
    max_seconds = max_seconds
    opts
  end
end