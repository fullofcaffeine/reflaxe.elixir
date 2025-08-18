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
  @spec start(term(), term()) :: term()
  def start(type, args) do
    app_name = "TodoApp"
    children = [TodoApp.Repo, {Phoenix.PubSub, name: TodoApp.PubSub}, TodoAppWeb.Telemetry, TodoAppWeb.Endpoint]
    opts = [strategy: ::one_for_one, name: TodoApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
    Called when application is preparing to shut down

  """
  @spec prep_stop(term()) :: term()
  def prep_stop(state) do
    state
  end

end
