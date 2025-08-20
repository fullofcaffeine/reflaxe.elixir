defmodule SupervisorOptionsBuilder do
  @moduledoc """
    SupervisorOptionsBuilder module generated from Haxe

     * Helper class for supervisor options
  """

  # Static functions
  @doc """
    Default supervisor options

  """
  @spec defaults() :: SupervisorOptions.t()
  def defaults() do
    [strategy: :one_for_one, name: App.Supervisor]
  end

  @doc """
    Create supervisor options with custom strategy

  """
  @spec with_strategy(SupervisorStrategy.t()) :: SupervisorOptions.t()
  def with_strategy(strategy) do
    opts = SupervisorOptionsBuilder.defaults()
    opts = %{opts | strategy: strategy}
    opts
  end

  @doc """
    Create supervisor options with custom restart limits

  """
  @spec with_limits(integer(), integer()) :: SupervisorOptions.t()
  def with_limits(max_restarts, max_seconds) do
    opts = SupervisorOptionsBuilder.defaults()
    opts = %{opts | max_restarts: max_restarts}
    opts = %{opts | max_seconds: max_seconds}
    opts
  end

end
