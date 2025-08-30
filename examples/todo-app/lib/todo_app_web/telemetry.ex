defmodule TodoAppWeb.Telemetry do
  def start_link(args) do
    fn args -> %{:ok => nil} end
  end
  def metrics() do
    fn -> [] end
  end
end