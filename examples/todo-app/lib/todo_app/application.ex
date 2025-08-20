defmodule TodoApp.Application do
  use Application

  @moduledoc """
    TodoApp.Application module generated from Haxe

     * Main TodoApp application module
     * Defines the OTP application supervision tree
  """

  # Static functions
  @doc """
    Get the app name from the @:appName annotation
    Simplified version for testing
  """
  @spec get_app_name() :: String.t()
  def get_app_name() do
    "TodoApp"
  end

  @doc """
    Start the application

  """
  @spec start(ApplicationStartType.t(), ApplicationArgs.t()) :: ApplicationResult.t()
  def start(type, args) do
    app_name = "TodoApp"
    children = [%{id: Phoenix.PubSub, start: {Phoenix.PubSub, :start_link, [%{name: TodoApp.PubSub}]}}, %{id: TodoAppWeb.Telemetry, start: {TodoAppWeb.Telemetry, :start_link, []}}, %{id: TodoAppWeb.Endpoint, start: {TodoAppWeb.Endpoint, :start_link, []}}]
    opts = [strategy: :one_for_one, name: TodoApp.Supervisor]
    supervisor_result = Supervisor.start_link(children, opts)
    supervisor_result
  end

  @doc """
    Called when application is preparing to shut down
    State is whatever was returned from start/2
  """
  @spec prep_stop(term()) :: term()
  def prep_stop(state) do
    state
  end

end
