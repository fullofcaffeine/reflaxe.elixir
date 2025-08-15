defmodule TodoApp.Application do
  @moduledoc false

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

  @doc "Start the application"
  @spec start(term(), term()) :: term()
  def start(type, args) do
    app_name = "TodoApp"
    children = [%{id: "" <> app_name <> ".Repo", start: %{module: "" <> app_name <> ".Repo", function: "start_link", args: []}}, %{id: "Phoenix.PubSub", start: %{module: "Phoenix.PubSub", function: "start_link", args: [%{name: "" <> app_name <> ".PubSub"}]}}, %{id: "" <> app_name <> "Web.Telemetry", start: %{module: "" <> app_name <> "Web.Telemetry", function: "start_link", args: []}}, %{id: "" <> app_name <> "Web.Endpoint", start: %{module: "" <> app_name <> "Web.Endpoint", function: "start_link", args: []}}]
    opts = %{strategy: "one_for_one", name: "" <> app_name <> ".Supervisor"}
    Supervisor.start_link(children, opts)
  end

  @doc "Called when application is preparing to shut down"
  @spec prep_stop(term()) :: term()
  def prep_stop(state) do
    state
  end

end
