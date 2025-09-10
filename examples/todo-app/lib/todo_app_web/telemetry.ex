defmodule TodoAppWeb.Telemetry do
  def child_spec(opts) do
    %{:id => "TodoAppWeb.Telemetry", :start => {TodoAppWeb.Telemetry, :start_link, [opts]}, :type => :supervisor, :restart => :permanent, :shutdown => :infinity}
  end
  def start_link(_args) do
    Supervisor.start_link(children, [strategy: :one_for_one, max_restarts: 3, max_seconds: 5])
  end
  def metrics() do
    []
  end
end