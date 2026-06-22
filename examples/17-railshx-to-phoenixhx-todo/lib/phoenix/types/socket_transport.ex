defmodule Phoenix.Types.SocketTransport do
  def web_socket() do
    {:web_socket}
  end
  def long_poll() do
    {:long_poll}
  end
end
