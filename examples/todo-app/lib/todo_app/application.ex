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
    type_safe_children = [{Phoenix.PubSub, name: "" <> app_name <> ".PubSub"}, TodoAppWeb.Telemetry, TodoAppWeb.Endpoint]
    g = []
    g = 0
    g = type_safe_children
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < g.length) do
          try do
            v = Enum.at(g, g)
          g = g + 1
          g ++ [TypeSafeChildSpecTools.toLegacy(v, app_name)]
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    opts = [strategy: :one_for_one, name: TodoApp.Supervisor]
    supervisor_result = Supervisor.start_link(g, opts)
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
