defmodule MyAppWeb.UserSocket do
  use Phoenix.Socket
  channel("typed:*", MyAppWeb.PingChannel)
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end
  def id(_socket) do
    nil
  end
end
