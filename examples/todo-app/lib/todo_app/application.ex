defmodule TodoApp.Application do
  defp getAppName() do
    fn -> "TodoApp" end
  end
  def start(type, args) do
    fn type, args -> app_name = Application.get_app_name()
children = [{:unknown, "TodoApp.PubSub"}, {:unknown, "TodoAppWeb.Telemetry"}, {:unknown, "TodoAppWeb.Endpoint"}]
opts = %{:strategy => :OneForOne, :max_restarts => 3, :max_seconds => 5}
supervisor_result = Supervisor.start_link(children, opts)
supervisor_result end
  end
  def prep_stop(state) do
    fn state -> state end
  end
end