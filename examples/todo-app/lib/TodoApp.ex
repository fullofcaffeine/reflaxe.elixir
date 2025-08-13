defmodule TodoApp.Application do
  @moduledoc """
  TodoApp.Application module generated from Haxe
  
  
 * Main TodoApp application module
 * Defines the OTP application supervision tree
 
  """

  # Static functions
  @doc "
     * Start the application
     "
  @spec start(term(), term()) :: term()
  def start(arg0, arg1) do
    (
  children = [%{id: "TodoApp.Repo", start: %{module: "TodoApp.Repo", function: "start_link", args: []}}, %{id: "Phoenix.PubSub", start: %{module: "Phoenix.PubSub", function: "start_link", args: [%{name: "TodoApp.PubSub"}]}}, %{id: "TodoAppWeb.Telemetry", start: %{module: "TodoAppWeb.Telemetry", function: "start_link", args: []}}, %{id: "TodoAppWeb.Endpoint", start: %{module: "TodoAppWeb.Endpoint", function: "start_link", args: []}}]
  opts = %{strategy: "one_for_one", name: "TodoApp.Supervisor"}
  Supervisor.Supervisor.start_link(children, opts)
)
  end

  @doc "
     * Called when application is preparing to shut down
     "
  @spec prep_stop(term()) :: term()
  def prep_stop(arg0) do
    state
  end

end
