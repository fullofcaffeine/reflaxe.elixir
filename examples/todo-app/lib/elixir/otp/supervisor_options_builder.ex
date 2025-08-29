defmodule SupervisorOptionsBuilder do
  @moduledoc """
    SupervisorOptionsBuilder module generated from Haxe

     * Helper class for supervisor options
  """

  # Static functions
  @doc "Generated from Haxe defaults"
  def defaults() do
    %{:strategy => :OneForOne, :max_restarts => 3, :max_seconds => 5}
  end

  @doc "Generated from Haxe withStrategy"
  def with_strategy(strategy) do
    opts = :SupervisorOptionsBuilder.defaults()
    strategy = strategy
    opts
  end

  @doc "Generated from Haxe withLimits"
  def with_limits(max_restarts, max_seconds) do
    opts = :SupervisorOptionsBuilder.defaults()
    max_restarts = max_restarts
    max_seconds = max_seconds
    opts
  end

end
