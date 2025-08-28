defmodule TodoApp.Application do
  use Application

  @moduledoc """
    TodoApp.Application module generated from Haxe

     * Main TodoApp application module
     * Defines the OTP application supervision tree
  """

  # Static functions
  @doc "Generated from Haxe getAppName"
  def get_app_name() do
    "TodoApp"
  end

  @doc "Generated from Haxe start"
  def start(_type, _args) do
    _app_name = "TodoApp"

    type_safe_children = [{Phoenix.PubSub, name: TodoApp.PubSub}, TodoAppWeb.Telemetry, TodoAppWeb.Endpoint]

    children = type_safe_children

    opts = [strategy: :one_for_one, name: TodoApp.Supervisor, max_restarts: 3, max_seconds: 5]

    supervisor_result = Supervisor.start_link(children, opts)

    supervisor_result
  end

  @doc "Generated from Haxe prep_stop"
  def prep_stop(state) do
    state
  end

end
