defmodule TodoAppWeb.Telemetry do
  use Supervisor
  def child_spec(opts) do
    %{:id => "TodoAppWeb.Telemetry", :start => {TodoAppWeb.Telemetry, :start_link, [opts]}, :type => :supervisor, :restart => :permanent, :shutdown => :infinity}
  end
  def start_link(args) do
    Supervisor.start_link([], [strategy: :one_for_one, max_restarts: 3, max_seconds: 5])
  end
  def init(args) do
    {:ok, {[], [strategy: :one_for_one, max_restarts: 3, max_seconds: 5]}}
  end
end
