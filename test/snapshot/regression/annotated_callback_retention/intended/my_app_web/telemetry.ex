defmodule MyAppWeb.Telemetry do
  use Supervisor
  def child_spec(opts) do
    %{id: "MyAppWeb.Telemetry", start: {MyAppWeb.Telemetry, :start_link, [opts]}, type: {:supervisor}}
  end
  def start_link(_args) do
    MyApp.ApplicationResultTools.ok(%{})
  end
  def init(_args) do
    %{}
  end
end
