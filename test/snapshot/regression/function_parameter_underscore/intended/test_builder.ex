defmodule TestBuilder do
  def pubsub(app_name) do
    app_name <> ".PubSub"
  end
  def endpoint(app_name, port) do
    actual_port = if (port != nil), do: port, else: 4000
    app_name <> ".Endpoint on port " <> Kernel.to_string(actual_port)
  end
end