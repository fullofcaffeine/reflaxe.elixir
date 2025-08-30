defmodule SupervisorOptionsBuilder do
  def defaults() do
    fn -> %{:strategy => :OneForOne, :max_restarts => 3, :max_seconds => 5} end
  end
  def withStrategy() do
    fn strategy -> opts = SupervisorOptionsBuilder.defaults()
strategy = strategy
opts end
  end
  def withLimits() do
    fn max_restarts, max_seconds -> opts = SupervisorOptionsBuilder.defaults()
max_restarts = max_restarts
max_seconds = max_seconds
opts end
  end
end