defmodule SupervisorOptionsBuilder do
  @moduledoc """
    SupervisorOptionsBuilder module generated from Haxe

     * Helper class for supervisor options
  """

  # Static functions
  @doc "Generated from Haxe defaults"
  def defaults() do
    [strategy: :one_for_one, name: TodoApp.Supervisor]
  end

  @doc "Generated from Haxe withStrategy"
  def with_strategy(strategy) do
    opts = SupervisorOptionsBuilder.defaults()
    %{opts | strategy: strategy}
    opts
  end

  @doc "Generated from Haxe withLimits"
  def with_limits(max_restarts, max_seconds) do
    opts = SupervisorOptionsBuilder.defaults()
    %{opts | max_restarts: max_restarts}
    %{opts | max_seconds: max_seconds}
    opts
  end

end
