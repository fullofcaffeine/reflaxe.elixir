defmodule TodoApp.Application do
  defp get_app_name() do
    "TodoApp"
  end
  def start(type, args) do
    app_name = Application.get_app_name()
    children = [TodoApp.PubSub, TodoAppWeb.Telemetry, TodoAppWeb.Endpoint]
    opts = %{:strategy => :OneForOne, :max_restarts => 3, :max_seconds => 5}
    supervisor_result = Supervisor.start_link(children, opts)
    supervisor_result
  end
  def prep_stop(state) do
    state
  end
end