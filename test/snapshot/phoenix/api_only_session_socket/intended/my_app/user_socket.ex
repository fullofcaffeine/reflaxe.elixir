defmodule MyApp.UserSocket do
  use Phoenix.Socket
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end
  def id(_socket) do
    nil
  end
end
